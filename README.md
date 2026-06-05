cat > README.md << 'EOF'
# BAIF Offline Translator

A fully **offline** translation application for BAIF that supports **Text, Audio, and Video** inputs with transcription, translation, and voice output.

---

## 🎯 Objective

Develop a complete offline solution for translating content between **English, Hindi, and Marathi** — especially useful in rural/field areas with poor internet connectivity.

---

## ✨ Features

- Audio & Video file upload
- Speech-to-Text Transcription (Whisper Base)
- Translation (English ↔ Hindi ↔ Marathi)
- Text-to-Speech (under development)
- Fully offline & open-source

---

## 🛠️ Tech Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: FastAPI (Python)
- **Transcription**: MLX Whisper (`whisper-base`)
- **Translation**: Helsinki-NLP OPUS models
- **Media Processing**: FFmpeg

---

## 🚀 Quick Start

### 1. Setup (First Time Only)

```bash
./setup.sh