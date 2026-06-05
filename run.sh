#!/bin/bash

echo "🚀 Starting BAIF Offline Translator..."
echo "===================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run setup first: ./setup.sh"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo "✅ Virtual environment activated"
echo "🌐 Starting server at http://127.0.0.1:8000"
echo "Press Ctrl+C to stop"
echo ""

# Start FastAPI server with auto-reload (good for development)
uvicorn src.backend.main:app --reload --host 127.0.0.1 --port 8000
