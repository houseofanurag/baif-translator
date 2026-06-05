#!/bin/bash
echo "🚀 Starting BAIF Offline Translator..."
source venv/bin/activate
cd ~/baif-translator
uvicorn src.backend.main:app --reload --port 8000
