#!/bin/bash

echo "🚀 BAIF Offline Translator"
echo "====================================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run: python3.11 -m venv venv"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo "✅ Virtual Environment Activated"

# Check and install requirements if needed
if [ ! -f "requirements.txt" ]; then
    echo "⚠️  requirements.txt not found. Skipping auto-install."
else
    echo "📦 Checking dependencies..."
    pip install -r requirements.txt --quiet
    echo "✅ Dependencies are ready"
fi

echo ""
echo "🌐 Starting BAIF Translator Backend..."
echo "📍 Access URL: http://127.0.0.1:8000"
echo "====================================="

# Start the FastAPI server
uvicorn backend.main:app --reload --port 8000
