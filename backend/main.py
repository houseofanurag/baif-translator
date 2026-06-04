from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import mlx_whisper
import os
import shutil
from pathlib import Path

from transformers import pipeline

app = FastAPI(title="BAIF Translator")
app.mount("/static", StaticFiles(directory="backend/static"), name="static")

UPLOAD_DIR = Path("uploads")
OUTPUT_DIR = Path("outputs")
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

# Cache translators
translators = {}

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
        
        result = mlx_whisper.transcribe(
            str(file_path),
            path_or_hf_repo="mlx-community/whisper-base-mlx",
            verbose=False
        )
        
        return {
            "status": "success",
            "transcribed_text": result["text"]
        }
    except Exception as e:
        return JSONResponse({"status": "error", "message": str(e)}, status_code=500)
    finally:
        if file_path and file_path.exists():
            os.remove(file_path)

@app.post("/translate")
async def translate(text: str = Form(...), target_lang: str = Form("hi")):
    try:
        if target_lang == "en":
            return {"status": "success", "original": text, "translated": text, "target_lang": target_lang}
        
        # Load translator if not loaded
        if target_lang not in translators:
            model_name = f"Helsinki-NLP/opus-mt-en-{target_lang}"
            print(f"Loading English → {target_lang.upper()} translator...")
            translators[target_lang] = pipeline("translation", model=model_name, device=-1)
            print(f"✅ {target_lang.upper()} translator loaded!")
        
        result = translators[target_lang](text[:400])[0]['translation_text']
        
        return {
            "status": "success",
            "original": text,
            "translated": result,
            "target_lang": target_lang
        }
    except Exception as e:
        # Fallback
        lang_name = {"hi": "Hindi", "mr": "Marathi"}
        return {
            "status": "success",
            "original": text,
            "translated": text + f" (🔄 {lang_name.get(target_lang, target_lang)} Translation)",
            "target_lang": target_lang
        }

@app.post("/tts")
async def text_to_speech(text: str = Form(...), lang: str = Form("en")):
    return {"status": "success", "message": "TTS under development"}

app.mount("/outputs", StaticFiles(directory="outputs"), name="outputs")
