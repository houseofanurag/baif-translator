# BAIF Offline Translator

A fully **offline** translation application for BAIF that supports **Text, Audio, and Video** inputs with transcription, translation, and voice output.

---

## 🎯 Objective

To provide a complete offline solution for transcribing, translating, and generating outputs between **English, Hindi, and Marathi** languages — especially useful in rural/field areas.

---

## ✨ Features

- Audio & Video file upload
- Speech-to-Text Transcription
- Translation (English ↔ Hindi ↔ Marathi)
- Text-to-Speech (Voice Output)
- SRT Subtitle Generation
- Fully offline & open-source

---

## 🛠️ Tech Stack & Models

| Component            | Technology / Model                          | Purpose |
|----------------------|---------------------------------------------|-------|
| **Backend**          | FastAPI (Python)                            | Main server & API |
| **Transcription**    | MLX Whisper (`whisper-base-mlx`)            | Speech-to-Text (optimized for Apple Silicon) |
| **Translation**      | Helsinki-NLP OPUS-MT models                 | Text translation |
| **Text-to-Speech**   | macOS `say` (English) + Piper (planned)     | Voice output |
| **SRT Generation**   | Custom logic with timestamps                | Subtitle files |
| **Frontend**         | HTML + Tailwind CSS + JavaScript            | Modern responsive UI |
| **Media Processing** | FFmpeg                                      | Audio/Video handling |

---

## 🚀 Quick Start

### 1. Setup (First Time Only)

```bash
./setup.sh