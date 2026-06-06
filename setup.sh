#!/bin/bash

echo "🚀 BAIF Offline Translator - Production Field Setup"
echo "=================================================="

# ==================== SYSTEM CHECKS ====================

echo "🔍 Checking system dependencies..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed! It is required to install system dependencies."
    echo "Please install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check Python 3.11
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found!"
    echo "Installing Python 3.11 via Homebrew..."
    brew install python@3.11
else
    echo "✅ Python 3.11 found"
fi

# Check and install FFmpeg-full (required for burned subtitles)
if ! ffmpeg -filters 2>/dev/null | grep -q subtitles; then
    echo "⚠️  FFmpeg with subtitles support (libass) not found."
    echo "Installing ffmpeg-full (this may take a few minutes)..."
    brew install ffmpeg-full
    echo "✅ FFmpeg-full installed successfully"
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

# Activate venv
source venv/bin/activate

# Upgrade pip
echo "🔄 Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📥 Installing Python packages..."
pip install -r requirements.txt

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p uploads outputs

# ==================== OFFLINE MODEL WARMUP ====================
echo "📥 Pre-downloading AI Models for 100% Offline Field Readiness..."
echo "⚠️  Ensure you have a stable internet connection right now!"

python3 -c "
import mlx_whisper
from transformers import pipeline
print('Downloading Whisper Base MLX model...')
mlx_whisper.transcribe(None, path_or_hf_repo='mlx-community/whisper-base-mlx', download_only=True)
print('Downloading Helsinki English-to-Hindi translation models...')
pipeline('translation', model='Helsinki-NLP/opus-mt-en-hi')
print('Downloading Helsinki English-to-Marathi translation models...')
pipeline('translation', model='Helsinki-NLP/opus-mt-en-mr')
print('✅ All translation models are warm and cached locally!')
" || echo "⚠️ Model caching skipped or failed. Ensure internet is active before taking this tool to the field."

# Make scripts executable
chmod +x run.sh setup.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo ""
echo "How to run the application:"
echo "   ./run.sh"
echo ""
echo "Open in browser → http://localhost:8000"
echo "To share with nearby tablets over local Wi-Fi, use your laptop's IP address."
echo ""