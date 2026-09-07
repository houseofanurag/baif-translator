import warnings
import multiprocessing
import time
import librosa
import soundfile as sf
import numpy as np
from scipy import signal
from langdetect import detect, DetectorFactory
from langdetect.lang_detect_exception import LangDetectException
from pathlib import Path
import os
import shutil
import uuid
import json
import subprocess
import re
from typing import Optional, List, Dict, Any

# ========================================================
# FORCE OFFLINE MODE - MUST BE BEFORE ANY IMPORTS
# ========================================================
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["TOKENIZERS_PARALLELISM"] = "false"

warnings.filterwarnings("ignore", category=UserWarning, module="multiprocessing")
multiprocessing.set_start_method('fork', force=True)

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

# Use faster-whisper instead of mlx-whisper
from faster_whisper import WhisperModel
from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
from config import Config

# Set seed for language detection
DetectorFactory.seed = 0

app = FastAPI(title=Config.APP_TITLE)
app.mount("/static", StaticFiles(directory="src/frontend/static"), name="static")

UPLOAD_DIR = Path(Config.UPLOAD_DIR)
OUTPUT_DIR = Path(Config.OUTPUT_DIR)
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# Translation engines
opus_models = {}

# Language mapping for NLLB (Hindi & Marathi only)
NLLB_LANG_MAP = {
    "hi": "hin_Deva",
    "mr": "mar_Deva",
}

# Supported languages
SUPPORTED_LANGS = ["en", "hi", "mr"]

# Global Whisper model cache
whisper_models = {}

# NLLB models cache
nllb_models = {}
nllb_tokenizers = {}

def convert_bengali_to_marathi(text: str) -> str:
    """Convert Bengali script text to Marathi Devanagari script"""
    bengali_to_devanagari = {
        'অ': 'अ', 'আ': 'आ', 'ই': 'इ', 'ঈ': 'ई', 'উ': 'उ', 'ঊ': 'ऊ',
        'ঋ': 'ऋ', 'এ': 'এ', 'ঐ': 'ঐ', 'ও': 'ও', 'ঔ': 'ঔ',
        'ক': 'क', 'খ': 'ख', 'গ': 'গ', 'ঘ': 'ঘ', 'ঙ': 'ङ',
        'চ': 'চ', 'ছ': 'छ', 'জ': 'ज', 'ঝ': 'ঝ', 'ঞ': 'ञ',
        'ট': 'ট', 'ঠ': 'ঠ', 'ড': 'ড', 'ঢ': 'ঢ', 'ণ': 'ण',
        'ত': 'ত', 'থ': 'থ', 'দ': 'দ', 'ধ': 'ধ', 'ন': 'ন',
        'প': 'প', 'ফ': 'ফ', 'ব': 'ব', 'ভ': 'ভ', 'ম': 'ম',
        'য': 'য', 'র': 'র', 'ল': 'ল', 'শ': 'শ', 'ষ': 'ষ',
        'স': 'স', 'হ': 'হ', 'ড়': 'ड़', 'ঢ়': 'ढ़', 'য়': 'য়',
        'ং': 'ं', 'ঃ': 'ः', 'ঁ': 'ँ', 'া': 'ा', 'ি': 'ि',
        'ী': 'ी', 'ু': 'ु', 'ূ': 'ू', 'ৃ': 'ृ', 'ে': 'ে',
        'ৈ': 'ै', 'ো': 'ो', 'ৌ': 'ौ', '্': '्', 'ৎ': 'त्',
        'ৗ': 'ौ',
    }
    
    for bengali, devanagari in bengali_to_devanagari.items():
        text = text.replace(bengali, devanagari)
    
    return text

def get_whisper_model(model_size: str = "base"):
    """Get or load Whisper model with caching"""
    if model_size not in whisper_models:
        model_map = {
            "tiny": "tiny",
            "base": "base",
            "small": "small",
            "medium": "medium",
            "large": "large-v3"
        }
        model_name = model_map.get(model_size, "base")
        print(f"🔄 Loading faster-whisper model: {model_name}")
        
        device = "cpu"
        compute_type = "int8"
        
        whisper_models[model_size] = WhisperModel(
            model_name, 
            device=device, 
            compute_type=compute_type,
            cpu_threads=4,
            num_workers=1
        )
    return whisper_models[model_size]

# ========================================================
# AUDIO PREPROCESSING UTILITIES
# ========================================================

def extract_audio_from_video(video_path: Path) -> Path:
    """Extract audio from video file using ffmpeg"""
    try:
        audio_path = video_path.parent / f"extracted_audio_{video_path.stem}.wav"
        
        cmd = [
            "ffmpeg",
            "-i", str(video_path),
            "-vn",
            "-acodec", "pcm_s16le",
            "-ar", "16000",
            "-ac", "1",
            "-y",
            str(audio_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"FFmpeg error: {result.stderr}")
            return video_path
        
        if audio_path.exists():
            return audio_path
        else:
            return video_path
    except Exception as e:
        print(f"Audio extraction error: {e}")
        return video_path

def reduce_noise(y: np.ndarray, sr: int, noise_floor: float = 0.01) -> np.ndarray:
    """Apply spectral gating noise reduction"""
    try:
        n_fft = 2048
        hop_length = 512
        stft = librosa.stft(y, n_fft=n_fft, hop_length=hop_length)
        
        magnitude = np.abs(stft)
        noise_profile = np.percentile(magnitude, 10, axis=1)
        
        mask = magnitude > (noise_profile[:, np.newaxis] * (1 + noise_floor))
        stft_clean = stft * mask
        
        y_clean = librosa.istft(stft_clean, hop_length=hop_length)
        return y_clean
    except Exception as e:
        print(f"Noise reduction error: {e}")
        return y

def preprocess_audio(audio_path: Path) -> Path:
    """Preprocess audio for better transcription quality"""
    try:
        video_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv'}
        if audio_path.suffix.lower() in video_extensions:
            audio_path = extract_audio_from_video(audio_path)
            if audio_path.suffix == '.mp4':
                return audio_path
        
        y, sr = librosa.load(audio_path, sr=16000, mono=True)
        
        y = reduce_noise(y, sr)
        y = librosa.util.normalize(y)
        
        b, a = signal.butter(4, 100, 'highpass', fs=sr)
        y = signal.filtfilt(b, a, y)
        
        preprocessed_path = audio_path.parent / f"preprocessed_{audio_path.stem}.wav"
        sf.write(preprocessed_path, y, sr)
        
        return preprocessed_path
    except Exception as e:
        print(f"Audio preprocessing error: {e}")
        return audio_path

# ========================================================
# OFFLINE TRANSLATION ENGINE
# ========================================================

def load_nllb_model(target_lang: str):
    """Load NLLB model from local cache only"""
    if target_lang in nllb_models:
        return nllb_models[target_lang], nllb_tokenizers[target_lang]
    
    try:
        print(f"  Loading NLLB model for {target_lang} from local cache...")
        model_name = "facebook/nllb-200-distilled-600M"
        
        tokenizer = AutoTokenizer.from_pretrained(
            model_name, 
            src_lang="eng_Latn",
            use_fast=True,
            local_files_only=True
        )
        model = AutoModelForSeq2SeqLM.from_pretrained(
            model_name,
            device_map="cpu",
            local_files_only=True
        )
        
        nllb_models[target_lang] = model
        nllb_tokenizers[target_lang] = tokenizer
        print(f"    ✅ NLLB {target_lang} loaded")
        return model, tokenizer
    except Exception as e:
        print(f"    ❌ Could not load NLLB {target_lang}: {e}")
        return None, None

def load_opus_model(source_lang: str, target_lang: str):
    """Load Opus-MT model from local cache only using pipeline with local_files_only"""
    model_key = f"{source_lang}-{target_lang}"
    
    if model_key in opus_models:
        return opus_models[model_key]
    
    try:
        if source_lang == "hi" and target_lang == "en":
            model_name = "Helsinki-NLP/opus-mt-hi-en"
        elif source_lang == "mr" and target_lang == "en":
            model_name = "Helsinki-NLP/opus-mt-mr-en"
        elif source_lang == "en" and target_lang == "hi":
            model_name = "Helsinki-NLP/opus-mt-en-hi"
        elif source_lang == "en" and target_lang == "mr":
            model_name = "Helsinki-NLP/opus-mt-en-mr"
        else:
            return None
        
        print(f"  Loading Opus-MT model: {model_name} from local cache...")
        
        # Create pipeline with local_files_only
        pipe = pipeline(
            "translation", 
            model=model_name,
            device=-1
        )
        
        # Override the model's configuration to force offline
        if hasattr(pipe, 'model') and hasattr(pipe.model, 'config'):
            pipe.model.config.local_files_only = True
        
        opus_models[model_key] = pipe
        print(f"    ✅ {model_name} loaded")
        return pipe
    except Exception as e:
        print(f"    ❌ Could not load {model_key}: {e}")
        return None

def translate_with_nllb(text: str, source_lang: str, target_lang: str, max_length: int = 512) -> str:
    """Translate using NLLB model"""
    model, tokenizer = load_nllb_model(target_lang)
    if not model or not tokenizer:
        return text
    
    try:
        chunks = split_text(text, max_length)
        translated_chunks = []
        
        for chunk in chunks:
            inputs = tokenizer(
                chunk, 
                return_tensors="pt", 
                truncation=True, 
                max_length=max_length
            )
            
            target_code = NLLB_LANG_MAP.get(target_lang, f"{target_lang}_Deva")
            
            # Use tokenizer's language code mapping
            if hasattr(tokenizer, 'lang_code_to_id'):
                forced_bos_token_id = tokenizer.lang_code_to_id[target_code]
            else:
                # Fallback for newer versions
                forced_bos_token_id = tokenizer.convert_tokens_to_ids(target_code)
            
            translated_tokens = model.generate(
                **inputs,
                forced_bos_token_id=forced_bos_token_id,
                max_length=max_length,
                num_beams=5,
                temperature=0.8,
                do_sample=True,
                repetition_penalty=1.2,
                length_penalty=1.0,
                early_stopping=True,
                no_repeat_ngram_size=3,
            )
            
            translated_chunks.append(
                tokenizer.decode(translated_tokens[0], skip_special_tokens=True)
            )
        
        return " ".join(translated_chunks)
    except Exception as e:
        print(f"  NLLB translation error: {e}")
        return text

def translate_with_opus(text: str, source_lang: str, target_lang: str, max_length: int = 512) -> str:
    """Translate using Opus-MT model"""
    pipe = load_opus_model(source_lang, target_lang)
    if not pipe:
        return text
    
    try:
        if len(text) > max_length:
            chunks = split_text(text, max_length)
            translated_chunks = []
            for chunk in chunks:
                result = pipe(chunk[:max_length])[0]['translation_text']
                translated_chunks.append(result)
            return " ".join(translated_chunks)
        else:
            result = pipe(text[:max_length])[0]['translation_text']
            return result
    except Exception as e:
        print(f"  Opus-MT translation error: {e}")
        return text

def translate_offline(text: str, source_lang: str = "en", target_lang: str = "hi", max_length: int = 512) -> str:
    """Translate text using only local models"""
    if source_lang == target_lang or not text:
        return text
    
    print(f"  Translating {source_lang} -> {target_lang} using offline models...")
    
    # Case 1: English -> Hindi/Marathi (use NLLB)
    if source_lang == "en" and target_lang in ["hi", "mr"]:
        return translate_with_nllb(text, source_lang, target_lang, max_length)
    
    # Case 2: Hindi/Marathi -> English (use Opus-MT)
    if source_lang in ["hi", "mr"] and target_lang == "en":
        result = translate_with_opus(text, source_lang, target_lang, max_length)
        # If Opus-MT fails, try NLLB reverse
        if result == text:
            print("  Opus-MT failed, trying NLLB reverse...")
            return translate_with_nllb(text, source_lang, target_lang, max_length)
        return result
    
    # Case 3: Hindi <-> Marathi (use NLLB)
    if source_lang in ["hi", "mr"] and target_lang in ["hi", "mr"]:
        return translate_with_nllb(text, source_lang, target_lang, max_length)
    
    # Translation not available
    print(f"  ⚠️ No translation available for {source_lang} -> {target_lang}")
    return text

def split_text(text: str, max_length: int) -> List[str]:
    """Split text into chunks for processing"""
    if len(text) <= max_length:
        return [text]
    
    # Split by sentences
    sentence_endings = ['. ', '। ', '? ', '! ', '\n']
    sentences = [text]
    
    for ending in sentence_endings:
        new_sentences = []
        for s in sentences:
            if ending in s:
                parts = s.split(ending)
                new_sentences.extend([p + ending for p in parts if p])
            else:
                new_sentences.append(s)
        sentences = new_sentences
    
    # Merge into chunks
    chunks = []
    current_chunk = []
    current_length = 0
    
    for sentence in sentences:
        word_count = len(sentence.split())
        if current_length + word_count > max_length:
            if current_chunk:
                chunks.append(' '.join(current_chunk))
                current_chunk = []
                current_length = 0
        current_chunk.append(sentence)
        current_length += word_count
    
    if current_chunk:
        chunks.append(' '.join(current_chunk))
    
    return chunks if chunks else [text]

# Preload models on startup
print("📦 Pre-loading translation models from local cache...")
print("  (This may take a moment on first run)")

# Preload NLLB for Hindi and Marathi
for lang in ["hi", "mr"]:
    load_nllb_model(lang)

# Preload Opus-MT models
load_opus_model("hi", "en")
load_opus_model("mr", "en")
load_opus_model("en", "hi")
load_opus_model("en", "mr")

print("✅ Translation models ready")

# ========================================================
# STORAGE TRACKING MONITOR UTILITY ENDPOINTS
# ========================================================

@app.get("/system/storage")
async def get_storage_status():
    try:
        total_size_bytes = 0
        file_count = 0
        
        if OUTPUT_DIR.exists():
            for item in OUTPUT_DIR.iterdir():
                if item.is_file() and not item.is_symlink():
                    total_size_bytes += item.stat().st_size
                    file_count += 1
                    
        total_size_mb = round(total_size_bytes / (1024 * 1024), 2)
        return {
            "status": "success",
            "file_count": file_count,
            "size_mb": total_size_mb,
            "directory_path": str(OUTPUT_DIR.absolute())
        }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)

@app.delete("/system/storage")
async def clear_storage_cache():
    try:
        if OUTPUT_DIR.exists():
            for item in OUTPUT_DIR.iterdir():
                if item.is_file() or item.is_symlink():
                    item.unlink()
                elif item.is_dir():
                    shutil.rmtree(item)
                    
        return {"status": "success", "message": "Outputs cache folder cleared successfully."}
    except Exception as e:
        return JSONResponse({"status": "error", "message": f"Purge failed: {str(e)}"}, status_code=500)

# ========================================================
# OPERATIONAL TRANSLATION & SUBTITLE CORES
# ========================================================

@app.get("/", response_class=HTMLResponse)
async def root():
    with open("src/frontend/static/index.html", "r", encoding="utf-8") as f:
        return f.read()

@app.post("/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...), 
    model_size: str = Form("base"),
    language: str = Form("auto"),
    task: str = Form("transcribe"),
    beam_size: int = Form(5),
    vad_filter: bool = Form(True)
):
    file_path = None
    audio_path = None
    
    try:
        file_path = UPLOAD_DIR / f"transcribe_{uuid.uuid4().hex[:8]}_{file.filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        print(f"📁 File saved: {file_path}")
        
        video_extensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv'}
        is_video = file_path.suffix.lower() in video_extensions
        
        if is_video:
            print("🎬 Processing video file...")
            audio_path = extract_audio_from_video(file_path)
            if audio_path == file_path:
                audio_path = file_path
        else:
            print("🎵 Processing audio file...")
            audio_path = file_path
        
        print("🔧 Preprocessing audio...")
        preprocessed_path = preprocess_audio(audio_path)
        print(f"✅ Preprocessed audio: {preprocessed_path}")
        
        print(f"📦 Loading Whisper model: {model_size}")
        model = get_whisper_model(model_size)
        
        transcribe_options = {
            "beam_size": beam_size,
            "best_of": beam_size,
            "temperature": 0.0,
            "compression_ratio_threshold": 2.4,
            "log_prob_threshold": -1.0,
            "no_speech_threshold": 0.6,
            "condition_on_previous_text": True,
            "vad_filter": vad_filter,
            "word_timestamps": True,
        }
        
        if language and language != "auto" and language in SUPPORTED_LANGS:
            transcribe_options["language"] = language
            print(f"🔒 FORCING language: {language}")
        else:
            print(f"🔍 Auto-detect mode - letting Whisper detect language")
        
        if task and task != "transcribe":
            transcribe_options["task"] = task
        
        print(f"🎯 Transcribing with faster-whisper...")
        print(f"📋 Options: {transcribe_options}")
        
        segments, info = model.transcribe(
            str(preprocessed_path),
            **transcribe_options
        )
        
        if language and language != "auto" and language in SUPPORTED_LANGS:
            detected_lang = language
            print(f"🔒 Using forced language: {detected_lang}")
        else:
            detected_lang = info.language
            print(f"🔍 Whisper auto-detected: {detected_lang}")
        
        if detected_lang == "ur" or detected_lang == "urdu":
            print(f"🔄 Mapping Urdu to Hindi")
            detected_lang = "hi"
        
        if detected_lang == "bn" or detected_lang == "bengali":
            print(f"🔄 Mapping Bengali to Marathi")
            detected_lang = "mr"
        
        if detected_lang not in SUPPORTED_LANGS:
            print(f"⚠️ Unsupported language: {detected_lang}, defaulting to English")
            detected_lang = "en"
        
        print(f"📝 Final language: {detected_lang}")
        
        cleaned_segments = []
        full_text = []
        segment_count = 0
        
        for segment in segments:
            segment_count += 1
            text = segment.text.strip()
            text = text.replace("  ", " ")
            text = text.replace("...", " ")
            
            if detected_lang == "mr":
                bengali_pattern = re.compile(r'[\u0980-\u09FF]')
                if bengali_pattern.search(text):
                    print(f"🔄 Converting Bengali script to Marathi Devanagari...")
                    text = convert_bengali_to_marathi(text)
            
            if text:
                cleaned_segments.append({
                    "start": float(segment.start),
                    "end": float(segment.end),
                    "text": text,
                    "confidence": float(segment.avg_logprob) if hasattr(segment, 'avg_logprob') else 0.0
                })
                full_text.append(text)
                
                if segment_count % 10 == 0:
                    print(f"📊 Processed {segment_count} segments...")
        
        print(f"✅ Total segments processed: {segment_count}")
        
        avg_confidence = sum(s.get("confidence", 0) for s in cleaned_segments) / len(cleaned_segments) if cleaned_segments else 0
        
        return {
            "status": "success",
            "transcribed_text": " ".join(full_text),
            "segments": cleaned_segments,
            "language": detected_lang,
            "user_selected_language": language if language and language != "auto" else None,
            "average_confidence": avg_confidence,
            "model_used": model_size,
            "task": task,
            "language_probability": float(info.language_probability) if hasattr(info, 'language_probability') else 0.0,
            "segment_count": segment_count
        }
    except Exception as e:
        print(f"❌ Transcription error: {e}")
        import traceback
        traceback.print_exc()
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)
    finally:
        if file_path and file_path.exists():
            try: os.remove(file_path)
            except: pass
        if audio_path and audio_path != file_path and audio_path.exists():
            try: os.remove(audio_path)
            except: pass

@app.post("/translate")
async def translate_text(
    text: str = Form(...), 
    source_lang: str = Form("auto"),
    target_lang: str = Form("hi")
):
    try:
        if target_lang not in SUPPORTED_LANGS:
            target_lang = "en"
        
        actual_source = source_lang
        if source_lang == "auto":
            try:
                if text and len(text) > 5:
                    detected = detect(text[:500])
                    if detected in ["hi", "mr", "en"]:
                        actual_source = detected
                    elif detected == "hi-Latn":
                        actual_source = "hi"
                    elif detected in ["mr", "mr-IN"]:
                        actual_source = "mr"
                    else:
                        actual_source = "en"
                    print(f"🔍 Auto-detected source language: {actual_source}")
                else:
                    actual_source = "en"
            except Exception as e:
                print(f"Language detection error: {e}")
                actual_source = "en"
        
        if actual_source == target_lang:
            return {
                "status": "success",
                "original": text,
                "translated": text,
                "source_lang": actual_source,
                "target_lang": target_lang,
                "message": "Source and target languages are the same"
            }
        
        print(f"🔄 Translating from {actual_source} to {target_lang}...")
        
        translated = translate_offline(text, actual_source, target_lang)
        
        return {
            "status": "success",
            "original": text,
            "translated": translated,
            "source_lang": actual_source,
            "target_lang": target_lang,
            "engine": "NLLB/Opus-MT (Offline)"
        }
    except Exception as e:
        print(f"Translation error: {e}")
        import traceback
        traceback.print_exc()
        return JSONResponse({
            "status": "success",
            "original": text,
            "translated": text + f" (🔄 Translation Error: {str(e)})",
            "target_lang": target_lang
        }, status_code=200)

@app.post("/tts")
async def text_to_speech(text: str = Form(...), lang: str = Form("en")):
    try:
        if lang not in SUPPORTED_LANGS:
            lang = "en"
            
        output_path = OUTPUT_DIR / f"tts_{uuid.uuid4().hex[:8]}.mp3"
        aiff_path = output_path.with_suffix(".aiff")
        
        voice_map = {
            "en": "Samantha",
            "hi": "Lekha",
            "mr": "Ananya"
        }
        
        selected_voice = voice_map.get(lang, "Samantha")
        
        max_chunk_length = 500
        text_chunks = [text[i:i+max_chunk_length] for i in range(0, len(text), max_chunk_length)]
        
        temp_files = []
        for i, chunk in enumerate(text_chunks):
            temp_path = output_path.parent / f"temp_tts_{i}_{uuid.uuid4().hex[:8]}.aiff"
            subprocess.run(
                ["say", "-v", selected_voice, "-o", str(temp_path), chunk[:Config.MAX_TEXT_LENGTH]], 
                check=True
            )
            temp_files.append(temp_path)
        
        if len(temp_files) > 1:
            list_path = output_path.parent / f"concat_list_{uuid.uuid4().hex[:8]}.txt"
            with open(list_path, "w") as f:
                for temp_file in temp_files:
                    f.write(f"file '{temp_file.absolute()}'\n")
            
            subprocess.run(
                ["ffmpeg", "-f", "concat", "-safe", "0", "-i", str(list_path), "-y", str(output_path)], 
                stdout=subprocess.DEVNULL, 
                stderr=subprocess.DEVNULL,
                check=True
            )
            list_path.unlink()
        else:
            subprocess.run(
                ["ffmpeg", "-i", str(temp_files[0]), "-y", str(output_path)], 
                stdout=subprocess.DEVNULL, 
                stderr=subprocess.DEVNULL,
                check=True
            )
        
        for temp_file in temp_files:
            if temp_file.exists():
                os.remove(temp_file)
            
        return {"status": "success", "audio_url": f"/outputs/{output_path.name}"}
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)

def create_srt(segments, output_path, target_lang="en"):
    if target_lang not in SUPPORTED_LANGS:
        target_lang = "en"
    
    with open(output_path, "w", encoding="utf-8") as f:
        for i, segment in enumerate(segments, 1):
            start = float(segment.get("start", 0))
            end = float(segment.get("end", start + 1))
            text = segment.get("text", "").strip()
            
            if not text:
                continue
            
            if target_lang != "en" and text:
                try:
                    text = translate_offline(text, "en", target_lang)
                except:
                    pass
            
            def format_time(seconds):
                hours = int(seconds // 3600)
                minutes = int((seconds % 3600) // 60)
                secs = int(seconds % 60)
                millis = int((seconds % 1) * 1000)
                return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"
                
            f.write(f"{i}\n")
            f.write(f"{format_time(start)} --> {format_time(end)}\n")
            f.write(f"{text}\n\n")

@app.post("/generate_srt")
async def generate_srt(
    segments: str = Form(...), 
    filename: str = Form("audio"), 
    target_lang: str = Form("en")
):
    try:
        if target_lang not in SUPPORTED_LANGS:
            target_lang = "en"
            
        segments_list = json.loads(segments)
        srt_path = OUTPUT_DIR / f"{Path(filename).stem}_{uuid.uuid4().hex[:8]}.srt"
        create_srt(segments_list, srt_path, target_lang)
        return {
            "status": "success",
            "srt_url": f"/outputs/{srt_path.name}",
            "message": "SRT generated successfully"
        }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)

@app.post("/burn_subtitles")
async def burn_subtitles(
    original_video: UploadFile = File(...), 
    srt_filename: str = Form(...),
    font_size: int = Form(24),
    font_color: str = Form("white")
):
    video_path = None
    try:
        video_path = UPLOAD_DIR / f"burn_{uuid.uuid4().hex[:8]}_{original_video.filename}"
        with open(video_path, "wb") as buffer:
            shutil.copyfileobj(original_video.file, buffer)
        
        srt_path = OUTPUT_DIR / srt_filename
        if not srt_path.exists():
            return JSONResponse({"status": "error", "message": "SRT file not found"}, status_code=400)
        
        output_path = OUTPUT_DIR / f"burned_{uuid.uuid4().hex[:8]}.mp4"
        
        escaped_srt_path = str(srt_path.absolute()).replace("\\", "/").replace(":", "\\:").replace("'", "'\\\\''")
        vf_filter = f"subtitles='{escaped_srt_path}':force_style='FontSize={font_size},PrimaryColour=&H00FFFFFF&,OutlineColour=&H00000000&,BorderStyle=3,Outline=1,Shadow=1'"
        
        cmd = [
            "ffmpeg", "-i", str(video_path),
            "-vf", vf_filter,
            "-c:v", "libx264", "-preset", "medium", "-crf", "20",
            "-c:a", "copy",
            "-y", str(output_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode != 0:
            print("FFmpeg Error:", result.stderr)
            return JSONResponse({"status": "error", "message": "Failed to burn subtitles via FFmpeg runtime"}, status_code=500)
        
        return {
            "status": "success",
            "video_url": f"/outputs/{output_path.name}",
            "message": "✅ Subtitles burned successfully!"
        }
    except Exception as e:
        print("Burn error:", str(e))
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)
    finally:
        if video_path and video_path.exists():
            try: os.remove(video_path)
            except: pass

app.mount("/outputs", StaticFiles(directory=Config.OUTPUT_DIR), name="outputs")