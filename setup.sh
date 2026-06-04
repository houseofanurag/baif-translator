#!/bin/bash

echo "🚀 BAIF Offline Translator - Setup Script"
echo "========================================="

# Check if Python 3.11 is installed
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 not found. Please install it first."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3.11 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "🔄 Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📥 Installing dependencies..."
pip install -r requirements.txt

echo "📥 Installing development tools..."
pip install -r requirements-dev.txt --quiet

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p uploads outputs backend/static

# Make run.sh executable
chmod +x run.sh

echo ""
echo "🎉 Setup Completed Successfully!"
echo ""
echo "How to run the project:"
echo "   ./run.sh"
echo ""
echo "Project is ready at: http://127.0.0.1:8000"
