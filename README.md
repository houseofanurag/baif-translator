
# BAIF Offline Translator

A fully **offline**, hardware-accelerated translation and subtitling suite built explicitly for BAIF field teams. It processes **audio and video** inputs, transcribes speech locally, translates between Indian languages, and generates multiple multimedia outputs—all without an internet connection.

---

## 🎯 Objective

Provide a resilient, secure, and zero-connectivity tool for BAIF teams working in remote rural areas to:
- Transcribe local language focus group recordings and field interviews.
- Translate text between English, Hindi, and Marathi fully locally.
- Generate translated voice clips, `.srt` subtitle documents, and hard-subtitled videos directly on-site.

---

## ✨ Features

- ✅ **Dual-Media Upload:** Full native compatibility with audio/video formats (MP4, MOV, MP3, WAV, M4A).
- ✅ **Real-Time Field Mic Capture:** Captures voice inputs on-site using standard browser media APIs, routing raw audio directly to local memory pipelines.
- ✅ **Local Speech-to-Text:** Powered by `MLX Whisper` (`whisper-base`), optimized to utilize Apple Silicon neural cores.
- ✅ **Deep Translation Engine:** Sequential timeline matrix translation utilizing local `Helsinki-NLP OPUS-MT` transformer blocks.
- ✅ **Interactive Subtitle Timeline Editor:** Review, verify, and correct timestamped segment rows dynamically before firing media rendering blocks.
- ✅ **Hardware-Accelerated Burn-in:** Overlays and burns hard subtitles into video containers cleanly via multi-pass local `FFmpeg` engines.
- ✅ **Disk Space & Storage Telemetry:** Integrated visual storage analyzer tracking the count and cumulative disk payload size (MB) of cached workspace exports.
- ✅ **Local Hotspot Mode:** Allows the host laptop to broadcast the app to nearby field tablets or smartphones over a local Wi-Fi router or hotspot.
- ✅ **On-Demand Cache Purging:** 100% offline security. Zero external tracking cookies with a single-click interactive system wipe tool to flush heavy output binaries on demand.

---

## 🏗️ Project Architecture

```text
baif-translator/
├── src/
│   ├── backend/
│   │   └── main.py          # FastAPI Core Server + Translation Engine & Storage Endpoints
│   └── frontend/
│       ├── index.html       # Responsive Field Dashboard + Telemetry Node Layout
│       └── static/
│           ├── css/
│           │   └── style.css # Decoupled Transitions, Responsive Architecture & Custom Scrollbars
│           └── js/
│               └── app.js   # Dynamic App State Controller, Media Drivers & Cache Sync
├── uploads/                 # Secure automated temporary media drop zone
├── outputs/                 # Exported Audio blocks, generated SRTs, and Rendered Videos
├── run.sh                   # Dynamic Multi-Interface Network Bootstrapper
├── setup.sh                 # Pre-deployment Dependency Compiler & Model Cache Warmup
├── requirements.txt         # Pinned Local Python Dependencies
├── config.py                # Global Network Routing and Token Limit Settings
├── push-all.sh              # Sync scripts for multi-repository configuration
└── README.md

```

---

## 🛠️ Tech Stack

| Component | Technology | Purpose |
| --- | --- | --- |
| **Backend Framework** | FastAPI (Python 3.11) | High-performance async local request & disk tracking management |
| **Speech-to-Text** | MLX Whisper (`whisper-base-mlx`) | Local audio transcription (Apple Silicon Matrix Optimized) |
| **Translation Engine** | Helsinki-NLP OPUS-MT Models | Tokenized linguistic language mapping pipelines |
| **Text-to-Speech** | macOS Native Speech Tool + FFmpeg | Synthesis voice rendering engines (English Core) |
| **Media Processing** | FFmpeg (compiled with `libass`) | Subtitle burn-in matrix overlay & track mapping |
| **Frontend Layout** | HTML5 + Tailwind CSS + Vanilla JS | Responsive Field Dashboard Interface with Storage Telemetry |
| **Local Persistence** | Web Storage API (`localStorage`) | Secure, local-only translation activity logs |

---

## 💾 Core Endpoint Matrices (Storage Engine)

The frontend synchronization framework orchestrates local file layouts via these endpoints:

* `GET /system/storage` - Scans physical asset states and queries cumulative sizes and file counts inside the `outputs/` engine directory.
* `DELETE /system/storage` - Instantly purges all previously compiled video hardrenders, localized speech audios, and saved SRT files to free up disk space in the field.

---

## 🚀 Pre-Field Deployment & Setup

> ⚠️ **CRITICAL WARNING:** Run the setup sequence while connected to a stable, high-speed office internet connection. The script automatically fetches and caches several gigabytes of advanced neural network weights directly to the laptop's storage so that they are ready to run 100% offline later.

### 1. One-Time Setup Preparation

Clone this repository on your Apple Silicon MacBook and run the automated setup command:

```bash
chmod +x setup.sh run.sh
./setup.sh

```

*This script automatically verifies Homebrew, updates Python modules, builds a virtual workspace environment, prepares storage paths, and caches the Whisper and Helsinki-NLP translation models.*

### 2. Launching the Local Engine

Whenever you are out in the field, launch the system by opening your terminal and typing:

```bash
./run.sh

```

---

## 📱 Field Usage & Multi-Device Hotspot Pairing

When you run `./run.sh`, the terminal automatically detects your laptop's system network address and displays access routes:

```text
--------------------------------------------------------
🌐 Local Laptop Access: http://localhost:8000
📱 Field Tablet Hotspot Access: [http://192.168.1.45:8000](http://192.168.1.45:8000)
--------------------------------------------------------

```

1. **On the Host Laptop:** Open `http://localhost:8000` in Safari or Chrome to manage translations.
2. **On Nearby Field Tablets/Phones:** Turn on your laptop's Wi-Fi hotspot. Connect field devices to that hotspot, open a mobile browser, and type the **Field Tablet Hotspot Access IP** (e.g., `http://192.168.1.45:8000`) to access and use the tool simultaneously without cell tower signal!

```

```