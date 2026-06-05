# BAIF Offline Translator

A fully **offline** translation application for BAIF that supports **Text, Audio, and Video** inputs.

---

## 🎯 Objective

Develop a complete offline solution for translating content between **English, Hindi, and Marathi** — especially useful in rural/field areas with poor internet.

---

## ✨ Features

- Audio & Video file upload
- Speech-to-Text Transcription (MLX Whisper)
- Translation (English ↔ Hindi ↔ Marathi)
- Text-to-Speech (Voice Output - under development)
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

### 1. Setup

```bash
cd baif-translator
./setup.sh