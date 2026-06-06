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

# Find local IP address to make it easy for field teams to connect tablets
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

echo "--------------------------------------------------------"
echo "🌐 Local Laptop Access: http://localhost:8000"
echo "📱 Field Tablet Hotspot Access: http://$LOCAL_IP:8000"
echo "--------------------------------------------------------"
echo "Press Ctrl+C to stop the server safely"
echo ""

# Start FastAPI server assigned to broad 0.0.0.0 network interfaces
uvicorn src.backend.main:app --host 0.0.0.0 --port 8000