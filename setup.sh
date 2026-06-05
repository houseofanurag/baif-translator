#!/bin/bash

echo "🚀 BAIF Offline Translator - Setup Script"
echo "========================================="

# Check Python
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found. Please install it first."
    exit 1
fi

# Check FFmpeg (full version with libass)
if ! ffmpeg -filters 2>/dev/null | grep -q subtitles; then
    echo "⚠️  FFmpeg with subtitles support not found."
    echo "Installing ffmpeg-full (this may take a few minutes)..."
    brew install ffmpeg-full
else
    echo "✅ FFmpeg with subtitles support is installed."
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3.11 -m venv venv
fi

source venv/bin/activate

echo "🔄 Upgrading pip..."
pip install --upgrade pip

echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

echo "📁 Creating directories..."
mkdir -p uploads outputs

chmod +x run.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo "Run the app using: ./run.sh"
