#!/bin/bash

echo "🚀 BAIF Offline Translator - Setup Script"
echo "========================================="

# ==================== SYSTEM CHECKS ====================

echo "🔍 Checking system dependencies..."

# Check Python 3.11
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found!"
    echo "Please install it using: brew install python@3.11"
    exit 1
else
    echo "✅ Python 3.11 found"
fi

# Check and install FFmpeg-full (required for burned subtitles)
if ! ffmpeg -filters 2>/dev/null | grep -q subtitles; then
    echo "⚠️  FFmpeg with subtitles support (libass) not found."
    echo "Installing ffmpeg-full (this may take 2-5 minutes)..."
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

# Install dev tools (optional but useful)
echo "📥 Installing development tools..."
pip install -r requirements-dev.txt --quiet

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p uploads outputs

# Make scripts executable
chmod +x run.sh setup.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo ""
echo "How to run the application:"
echo "   ./run.sh"
echo ""
echo "Open in browser → http://127.0.0.1:8000"
echo ""
echo "Note: Burned-in Subtitles feature requires FFmpeg-full (already installed)"
