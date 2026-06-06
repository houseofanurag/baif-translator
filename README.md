# BAIF Offline Translator

A fully **offline** translation application built for BAIF field teams. It supports **audio and video** inputs, transcribes speech, translates between Indian languages, and generates multiple outputs — all without internet.

---

## 🎯 Objective

Provide a reliable, secure, and easy-to-use offline tool for BAIF teams working in rural areas to:
- Transcribe local language recordings
- Translate between English, Hindi, and Marathi
- Generate voice output and subtitles

---

## ✨ Features

- ✅ Audio & Video Upload (MP4, MOV, MP3, WAV, M4A, etc.)
- ✅ Speech-to-Text Transcription (MLX Whisper)
- ✅ Translation: English ↔ Hindi ↔ Marathi
- ✅ Text-to-Speech (Voice Generation) – Full English support
- ✅ SRT Subtitle Generation
- ✅ Burn Subtitles into Video
- ✅ Download Translated Text
- ✅ Recent Translations History
- ✅ Modern Responsive UI
- ✅ 100% Offline & Open Source

---

## 🏗️ Project Architecture
baif-translator/
├── src/
│   ├── backend/
│   │   └── main.py                 # FastAPI Server + All Endpoints
│   └── frontend/
│       └── static/
│           ├── index.html          # Modern Dashboard UI
│           └── js/
│               └── app.js          # Frontend Logic
├── uploads/                        # Temporary uploaded media
├── outputs/                        # SRT, Audio, Burned Videos
├── run.sh                          # Start the app
├── setup.sh                        # Initial setup script
├── requirements.txt
├── config.py
├── push-all.sh                     # Push to both GitHub repos
└── README.md



---

## 🛠️ Tech Stack

| Component            | Technology                              | Purpose |
|----------------------|-----------------------------------------|--------|
| Backend              | FastAPI (Python)                        | API Server |
| Transcription        | MLX Whisper (`whisper-base`)            | Speech-to-Text (Apple Silicon Optimized) |
| Translation          | Helsinki-NLP OPUS-MT models             | Text Translation |
| Text-to-Speech       | macOS `say` command                     | Voice Output (English) |
| Media Processing     | FFmpeg                                  | Audio/Video handling & Subtitle burning |
| Frontend             | HTML + Tailwind CSS + Vanilla JS        | User Interface |
| Local Storage        | Browser localStorage                    | History |

---

## 🚀 Quick Start

### 1. Setup (First Time)
```bash
./setup.sh

./run.sh