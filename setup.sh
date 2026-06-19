#!/bin/bash

echo "🚀 BAIF Offline Translator - Conditional Setup Matrix"
echo "=================================================="

# ==================== INTERACTIVE PROFILE SELECTION ====================
IS_PROD=false

read -p "❓ Is this installation for a Production Field Laptop? (y/N): " choice
case "$choice" in 
  [yY][eE][sS]|[yY])
    echo "⚠️  Production Mode Selected: Full offline dependencies will be cached (~6GB disk space needed)."
    IS_PROD=true
    ;;
  *)
    echo "💻 Development / Personal Mode Selected: Only minimal lightweight models will be cached to save space."
    IS_PROD=false
    ;;
esac
echo "--------------------------------------------------"

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

# Check Git LFS
if ! command -v git-lfs &> /dev/null; then
    echo "⚠️  Git LFS not found. Installing via Homebrew..."
    brew install git-lfs
    git lfs install
else
    echo "✅ Git LFS is installed"
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
mkdir -p "$HOME/.cache/mlx_models"

# ==================== CONDITIONAL OFFLINE MODEL WARMUP ====================
echo "📥 Pre-downloading AI Models based on selected environmental configuration..."
echo "⚠️  Ensure you have a stable internet connection right now!"

python3 -c "
import os
import sys
from pathlib import Path
from huggingface_hub import snapshot_download
from transformers import pipeline

# Read the environment variable passed from bash
is_prod_env = os.environ.get('BAIF_PROD_SETUP', 'false') == 'true'
base_model_dir = Path(os.path.expanduser('~/.cache/mlx_models'))

print('Downloading Whisper Tiny MLX model locally...')
snapshot_download(repo_id='mlx-community/whisper-tiny', local_dir=base_model_dir / 'whisper-tiny')

print('Downloading Whisper Base MLX model locally...')
snapshot_download(repo_id='mlx-community/whisper-base-mlx', local_dir=base_model_dir / 'whisper-base')

if is_prod_env:
    print('📦 [PROD-ONLY] Downloading Whisper Small MLX model locally...')
    snapshot_download(repo_id='mlx-community/whisper-small-mlx', local_dir=base_model_dir / 'whisper-small')

    print('📦 [PROD-ONLY] Downloading Whisper Medium MLX model locally...')
    snapshot_download(repo_id='mlx-community/whisper-medium-mlx', local_dir=base_model_dir / 'whisper-medium')

    print('📦 [PROD-ONLY] Downloading Whisper Large V3 MLX model locally...')
    snapshot_download(repo_id='mlx-community/whisper-large-v3-mlx', local_dir=base_model_dir / 'whisper-large-v3')
else:
    print('⏭️  [DEV-MODE] Skipping Small, Medium, and Large V3 whisper weights to save local storage.')

print('Downloading Helsinki English-to-Hindi translation models...')
pipeline('translation', model='Helsinki-NLP/opus-mt-en-hi')

print('Downloading Helsinki English-to-Marathi translation models...')
pipeline('translation', model='Helsinki-NLP/opus-mt-en-mr')

print('✅ Model caching run completed successfully!')
" BAIF_PROD_SETUP=$IS_PROD || echo "⚠️ Model caching skipped or failed. Ensure internet is active before running."

# Make scripts executable
chmod +x run.sh setup.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo ""
echo "How to run the application:"
echo "   ./run.sh"
echo ""