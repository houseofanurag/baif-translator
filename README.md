# BAIF Offline Translator

A fully **offline** translation application for BAIF supporting **Text, Audio, and Video** inputs.

---

## 🎯 Objective

To provide a complete offline solution for transcribing, translating, and generating outputs between **English, Hindi, and Marathi** languages.

---

## ✨ Features

- Audio & Video Transcription
- Translation (English ↔ Hindi ↔ Marathi)
- SRT Subtitle Generation
- Fully offline & open-source

---

## 🛠️ Tech Stack & Models

| Component          | Technology / Model                        | Purpose |
|--------------------|-------------------------------------------|-------|
| **Backend**        | FastAPI (Python)                          | Main server & API |
| **Transcription**  | MLX Whisper (`whisper-base-mlx`)          | Speech-to-Text (optimized for Apple Silicon) |
| **Translation**    | Helsinki-NLP OPUS-MT (En→Hi, En→Mr)       | Text translation |
| **SRT Generation** | Custom Python logic + timestamps          | Create subtitle files |
| **Frontend**       | HTML + CSS + JavaScript                   | User Interface |
| **Media Handling** | FFmpeg                                    | Audio/Video processing |

---

## 🚀 Quick Start

### 1. Setup (First Time)

```bash
./setup.sh