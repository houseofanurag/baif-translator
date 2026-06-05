#!/bin/bash

echo "🚀 BAIF Offline Translator - Setup Script"
echo "========================================="

# Check Python
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found!"
    echo "Please install it using: brew install python@3.11"
    exit 1
fi

# Create venv
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3.11 -m venv venv
fi

source venv/bin/activate

echo "🔄 Upgrading pip..."
pip install --upgrade pip

echo "📥 Installing dependencies..."
pip install -r requirements.txt

echo "📥 Installing dev tools..."
pip install -r requirements-dev.txt --quiet

# Create folders
mkdir -p uploads outputs backend/static

chmod +x run.sh push_code.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo "Run the app using: ./run.sh"
echo "Project URL: http://127.0.0.1:8000"
