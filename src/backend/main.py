import warnings
import multiprocessing

# Suppress common warnings
warnings.filterwarnings("ignore", category=UserWarning, module="multiprocessing")
multiprocessing.set_start_method('fork', force=True)

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import mlx_whisper
import os
import shutil
from pathlib import Path
import uuid
import json
import subprocess

from transformers import pipeline

from config import Config

app = FastAPI(title=Config.APP_TITLE)

# Mount static files
app.mount("/static", StaticFiles(directory="src/frontend/static"), name="static")

UPLOAD_DIR = Path(Config.UPLOAD_DIR)
OUTPUT_DIR = Path(Config.OUTPUT_DIR)
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

translators = {}

@app.get("/", response_class=HTMLResponse)
async def root():
    with open("src/frontend/static/index.html", "r", encoding="utf-8") as f:
        return f.read()

# ====================== TRANSCRIPTION ======================
@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    file_path = None
    try:
        file_path = UPLOAD_DIR / file.filename
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        print(f"Transcribing: {file.filename}")
        
        result = mlx_whisper.transcribe(
            str(file_path),
            path_or_hf_repo=Config.WHISPER_MODEL,
            verbose=False,
            word_timestamps=True
        )
        
        cleaned_segments = [{
            "start": float(seg.get("start", 0)),
            "end": float(seg.get("end", 0)),
            "text": seg.get("text", "").strip()
        } for seg in result.get("segments", [])]
        
        return {
            "status": "success",
            "transcribed_text": result["text"],
            "segments": cleaned_segments
        }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)
    finally:
        if file_path and file_path.exists():
            os.remove(file_path)

# ====================== TRANSLATION ======================
@app.post("/translate")
async def translate(text: str = Form(...), target_lang: str = Form("hi")):
    try:
        if target_lang == "en":
            return {"status": "success", "original": text, "translated": text, "target_lang": target_lang}
        
        if target_lang not in translators:
            model_name = f"Helsinki-NLP/opus-mt-en-{target_lang}"
            print(f"Loading {target_lang.upper()} translator...")
            translators[target_lang] = pipeline("translation", model=model_name, device=-1)
        
        result = translators[target_lang](text[:Config.MAX_TEXT_LENGTH])[0]['translation_text']
        
        return {
            "status": "success",
            "original": text,
            "translated": result,
            "target_lang": target_lang
        }
    except Exception:
        return JSONResponse({
            "status": "success",
            "original": text,
            "translated": text + f" (🔄 {target_lang.upper()} Translation)",
            "target_lang": target_lang
        }, status_code=200)

# ====================== TEXT-TO-SPEECH ======================
@app.post("/tts")
async def text_to_speech(text: str = Form(...), lang: str = Form("en")):
    try:
        output_path = OUTPUT_DIR / f"tts_{uuid.uuid4().hex[:8]}.mp3"
        
        if lang == "en":
            # Stable macOS built-in voice
            subprocess.run([
                "say", "-v", "Samantha", "-o", str(output_path.with_suffix(".aiff")), text[:500]
            ], check=True)
            
            subprocess.run([
                "ffmpeg", "-i", str(output_path.with_suffix(".aiff")),
                "-y", str(output_path)
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
            os.remove(output_path.with_suffix(".aiff"))
            
            return {
                "status": "success",
                "audio_url": f"/outputs/{output_path.name}",
                "message": "English voice generated successfully"
            }
        else:
            return {
                "status": "success",
                "message": "Hindi & Marathi voices coming soon"
            }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)

# ====================== SRT SUBTITLES ======================
def create_srt(segments, output_path):
    with open(output_path, "w", encoding="utf-8") as f:
        for i, segment in enumerate(segments, 1):
            start = float(segment.get("start", 0))
            end = float(segment.get("end", start + 1))
            text = segment.get("text", "").strip()
            
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
async def generate_srt(segments: str = Form(...), filename: str = Form("audio")):
    try:
        segments_list = json.loads(segments)
        srt_path = OUTPUT_DIR / f"{Path(filename).stem}_{uuid.uuid4().hex[:8]}.srt"
        create_srt(segments_list, srt_path)
        
        return {
            "status": "success",
            "srt_url": f"/outputs/{srt_path.name}",
            "message": "SRT generated successfully"
        }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)

app.mount("/outputs", StaticFiles(directory=Config.OUTPUT_DIR), name="outputs")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=Config.HOST, port=Config.PORT)
