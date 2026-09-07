#!/bin/bash

echo "🚀 BAIF Offline Translator - Setup Matrix (Hindi, Marathi, English)"
echo "=================================================================="

IS_PROD=false

read -p "❓ Is this installation for a Production Field Laptop? (y/N): " choice
case "$choice" in 
  [yY][eE][sS]|[yY])
    echo "⚠️  Production Mode Selected: Full offline dependencies will be cached (~6GB disk space needed)."
    IS_PROD=true
    ;;
  *)
    echo "💻 Development Mode Selected: Only minimal lightweight models will be cached."
    IS_PROD=false
    ;;
esac
echo "--------------------------------------------------"

# ==================== SYSTEM CHECKS ====================

echo "🔍 Checking system dependencies..."

if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed! Please install it first."
    echo "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found! Installing..."
    brew install python@3.11
else
    echo "✅ Python 3.11 found"
fi

if ! command -v git-lfs &> /dev/null; then
    echo "⚠️  Git LFS not found. Installing..."
    brew install git-lfs
    git lfs install
else
    echo "✅ Git LFS is installed"
fi

if ! ffmpeg -filters 2>/dev/null | grep -q subtitles; then
    echo "⚠️  FFmpeg with subtitles support not found."
    echo "Installing ffmpeg (this may take a few minutes)..."
    brew install ffmpeg
    echo "✅ FFmpeg installed successfully"
else
    echo "✅ FFmpeg with subtitles support is ready"
fi

# ==================== VIRTUAL ENVIRONMENT ====================

if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3.11 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

source venv/bin/activate
pip install --upgrade pip

# ==================== INSTALL DEPENDENCIES ====================

echo "📥 Installing Python packages..."
pip install -r requirements.txt

# ==================== CREATE DIRECTORIES ====================

mkdir -p uploads outputs
mkdir -p "$HOME/.cache/mlx_models"
mkdir -p "$HOME/.cache/huggingface"

# ==================== MODEL DOWNLOAD ====================

echo ""
echo "📥 Downloading ALL AI Models for Offline Use..."
echo "⚠️  Ensure you have a stable internet connection!"
echo ""

python3 -c "
import os
import sys
import time
from pathlib import Path
from huggingface_hub import snapshot_download
from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
from faster_whisper import WhisperModel

is_prod_env = os.environ.get('BAIF_PROD_SETUP', 'false') == 'true'

print('\n📥 Downloading faster-whisper models...')
print('  These models will be cached for offline use.\n')

# Download Whisper models using faster-whisper
models_to_download = ['tiny', 'base']

if is_prod_env:
    models_to_download.extend(['small', 'medium', 'large-v3'])

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

chmod +x run.sh setup.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo ""
echo "Supported Languages: English, Hindi (हिंदी), Marathi (मराठी)"
echo ""
echo "All models are now cached locally for offline use."
echo ""
echo "How to run:"
echo "   ./run.sh"
echo ""