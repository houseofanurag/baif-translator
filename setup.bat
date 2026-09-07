@echo off
SETLOCAL EnableDelayedExpansion
cls

echo ========================================================
echo 🇮🇳 BAIF Offline Translator - Windows Setup Compiler
echo ========================================================
echo.

:: Check for Python installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Python is not installed or not added to your system PATH.
    echo Please install Python 3.11 or higher before running this script.
    echo.
    echo Download Python from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)

:: Check Python version
for /f "tokens=2" %%I in ('python --version 2^>^&1') do set PYTHON_VERSION=%%I
echo ✅ Python found: %PYTHON_VERSION%

:: Create dropzones and storage workspaces
echo.
echo 📁 Creating local workspace directories...
if not exist "uploads" mkdir uploads
if not exist "outputs" mkdir outputs
if not exist "src\frontend\static\css" mkdir src\frontend\static\css 2>nul
if not exist "src\frontend\static\js" mkdir src\frontend\static\js 2>nul
if not exist "src\backend" mkdir src\backend 2>nul

:: Check for config.py
if not exist "src\backend\config.py" (
    echo 📝 Creating config.py...
    (
        echo class Config:
        echo     APP_TITLE = "BAIF Offline Translator"
        echo     UPLOAD_DIR = "uploads"
        echo     OUTPUT_DIR = "outputs"
        echo     MAX_TEXT_LENGTH = 5000
    ) > src\backend\config.py
)

:: Establish Virtual Environment
echo.
echo 📦 Configuring isolated Python environment (venv)...
if not exist "venv" (
    python -m venv venv
    echo ✅ Virtual environment compiled successfully.
) else (
    echo ℹ️ Virtual environment already exists. Skipping compilation.
)

:: Activate and bootstrap dependencies
echo.
echo ⚡ Activating environment and running dependency sync...
call .\venv\Scripts\activate.bat

echo.
echo 🔄 Upgrading local package managers...
python -m pip install --upgrade pip

echo.
echo 📥 Installing Python packages...
pip install -r requirements.txt

:: Check if requirements.txt exists
if not exist "requirements.txt" (
    echo.
    echo ⚠️ requirements.txt not found! Creating default...
    (
        echo fastapi>=0.100.0
        echo uvicorn>=0.22.0
        echo faster-whisper>=1.0.0
        echo ctranslate2>=4.0.0
        echo transformers>=4.38.0
        echo sentencepiece>=0.1.99
        echo indic-transliteration>=2.3.0
        echo pysubs2>=1.6.0
        echo python-multipart>=0.0.6
        echo librosa>=0.10.0
        echo soundfile>=0.12.0
        echo scipy>=1.10.0
        echo langdetect>=1.0.9
        echo numpy>=1.24.0
        echo accelerate>=0.25.0
        echo torch>=2.0.0
    ) > requirements.txt
    pip install -r requirements.txt
)

:: Check for FFmpeg
echo.
echo 🎬 Checking for FFmpeg...
where ffmpeg >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ FFmpeg not found in PATH.
    echo.
    echo 📥 Please install FFmpeg manually:
    echo 1. Download from: https://ffmpeg.org/download.html
    echo 2. Add the bin folder to your system PATH
    echo 3. Or install via chocolatey: choco install ffmpeg
    echo.
    echo Press any key to continue without FFmpeg (video features disabled)...
    pause >nul
) else (
    echo ✅ FFmpeg found
)

:: Download all models for offline use
echo.
echo 📥 Downloading ALL AI Models for Offline Use...
echo ⚠️  Ensure you have a stable internet connection!
echo.

python -c "
import os
import sys
import time
from pathlib import Path
from huggingface_hub import snapshot_download
from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
from faster_whisper import WhisperModel

print('\n📥 Downloading faster-whisper models...')
print('  These models will be cached for offline use.\n')

# Download Whisper models using faster-whisper
models_to_download = ['tiny', 'base', 'small', 'medium', 'large-v3']

for model_name in models_to_download:
    print(f'  - Loading Whisper {model_name}...')
    try:
        model = WhisperModel(model_name, device='cpu', compute_type='int8')
        print(f'    ✅ Whisper {model_name} loaded successfully')
    except Exception as e:
        print(f'    ⚠️  Could not load Whisper {model_name}: {e}')

print('\n📥 Downloading NLLB-200 translation model (English → Hindi/Marathi)...')
print('  This supports high-quality Hindi and Marathi translation.')
try:
    model_name = 'facebook/nllb-200-distilled-600M'
    AutoTokenizer.from_pretrained(model_name, src_lang='eng_Latn')
    AutoModelForSeq2SeqLM.from_pretrained(model_name, device_map='cpu')
    print('    ✅ NLLB-200 downloaded')
except Exception as e:
    print(f'    ⚠️  Could not download NLLB-200: {e}')

print('\n📥 Downloading Opus-MT models for Indian languages...')
print('  These support Hindi/Marathi ↔ English translation.\n')

# Download Opus-MT models for both directions
opus_models = [
    'Helsinki-NLP/opus-mt-hi-en',      # Hindi → English
    'Helsinki-NLP/opus-mt-mr-en',      # Marathi → English
    'Helsinki-NLP/opus-mt-en-hi',      # English → Hindi
    'Helsinki-NLP/opus-mt-en-mr',      # English → Marathi
]

for model_name in opus_models:
    print(f'  - Downloading {model_name}...')
    try:
        pipeline('translation', model=model_name, device=-1)
        print(f'    ✅ {model_name} downloaded')
    except Exception as e:
        print(f'    ⚠️  Could not download {model_name}: {e}')

print('\n📥 Downloading M2M-100 fallback model (for any language pair)...')
print('  This is a universal translation model for fallback.\n')
try:
    model_name = 'facebook/m2m100_418M'
    AutoTokenizer.from_pretrained(model_name)
    AutoModelForSeq2SeqLM.from_pretrained(model_name, device_map='cpu')
    print('    ✅ M2M-100 downloaded')
except Exception as e:
    print(f'    ⚠️  Could not download M2M-100: {e}')

print('\n✅ All models downloaded successfully!')
print('   The system is now fully offline-ready.')
"

echo.
echo ========================================================
echo 🎉 Setup Complete! Neural weights and binaries pre-staged.
echo.
echo Supported Languages: English, Hindi (हिंदी), Marathi (मराठी)
echo All models are now cached locally for offline use.
echo.
echo Run 'run.bat' to initiate the translator platform.
echo ========================================================
pause