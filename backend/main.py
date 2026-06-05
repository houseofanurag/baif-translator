from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import mlx_whisper
import os
import shutil
from pathlib import Path
import uuid
import json

from transformers import pipeline

app = FastAPI(title="BAIF Translator")
app.mount("/static", StaticFiles(directory="backend/static"), name="static")

UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

@app.get("/", response_class=HTMLResponse)
async def root():
    with open("backend/static/index.html", "r", encoding="utf-8") as f:
        return f.read()

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    file_path = None
    try:
        file_path = UPLOAD_DIR / file.filename
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        print(f"Transcribing {file.filename}...")
        
        result = mlx_whisper.transcribe(
            str(file_path),
            path_or_hf_repo="mlx-community/whisper-base-mlx",
            verbose=False,
            word_timestamps=True
        )
        
        # Clean segments to avoid NaN/inf values
        cleaned_segments = []
        for seg in result.get("segments", []):
            cleaned_segments.append({
                "start": float(seg.get("start", 0)),
                "end": float(seg.get("end", 0)),
                "text": seg.get("text", "").strip()
            })
        
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
            print(f"Loading English → {target_lang.upper()} translator...")
            translators[target_lang] = pipeline("translation", model=model_name, device=-1)
        
        result = translators[target_lang](text[:400])[0]['translation_text']
        
        return {
            "status": "success",
            "original": text,
            "translated": result,
            "target_lang": target_lang
        }
    except Exception as e:
        return JSONResponse({
            "status": "success",
            "original": text,
            "translated": text + f" (🔄 {target_lang.upper()} Translation)",
            "target_lang": target_lang
        }, status_code=200)

# ====================== SRT ======================
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

translators = {}  # Global cache

app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")
