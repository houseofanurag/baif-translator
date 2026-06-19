
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

- ✅ **Universal Platform Support:** Deployable on any host operating system—macOS, Windows, or Linux Servers.
- ✅ **Dual-Media Upload:** Full native compatibility with audio/video formats (MP4, MOV, MP3, WAV, M4A).
- ✅ **Real-Time Field Mic Capture:** Captures voice inputs on-site using standard browser media APIs, routing raw audio directly to local memory pipelines.
- ✅ **Cross-Platform Local Speech-to-Text:** Powered by a dynamic hardware-sensing Whisper implementation (`whisper-base`), optimizing automatically for hardware acceleration chips across distinct deployment platforms.
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
│   │   └── main.py          # FastAPI Core Server (Auto-detects Neural Accelerators across Platforms)
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

## 🛠️ Tech Stack & Hardware Detection Matrix

The core backend uses a unified python architecture layer that dynamically probes the hardware execution space:

| Component | Technology | Purpose | Platform Hardware Support |
| --- | --- | --- | --- |
| **Backend Framework** | FastAPI (Python 3.11) | High-performance async local request & disk tracking | Universal (Windows, macOS, Linux) |
| **Speech-to-Text** | Whisper Core Engine | Local audio transcription and processing layers | Universal (Auto-detects matrix runtime) |
| **Hardware Acceleration** | MLX / CUDA / CPU | Direct core compute engine acceleration | **macOS Silicon:** MLX Neural Core Arrays<br>

<br>**Windows/Linux:** CUDA (Nvidia GPU) or CPU |
| **Translation Engine** | Helsinki-NLP OPUS-MT Models | Tokenized linguistic language mapping pipelines | Universal (Windows, macOS, Linux) |
| **Media Processing** | FFmpeg (compiled with `libass`) | Subtitle burn-in matrix overlay & track mapping | Universal (Windows, macOS, Linux) |
| **Frontend Layout** | HTML5 + Tailwind CSS + Vanilla JS | Responsive Field Dashboard Interface with Storage Telemetry | Universal (Accessed via local browser engine) |
| **Local Persistence** | Web Storage API (`localStorage`) | Secure, local-only translation activity logs | Client Browser Native |

---

## 💾 Core Endpoint Matrices (Storage Engine)

The frontend synchronization framework orchestrates local file layouts via these endpoints:

* `GET /system/storage` - Scans physical asset states and queries cumulative sizes and file counts inside the `outputs/` engine directory.
* `DELETE /system/storage` - Instantly purges all previously compiled video hardrenders, localized speech audios, and saved SRT files to free up disk space in the field.

---

## 🚀 Pre-Field Deployment & Setup

> ⚠️ **CRITICAL WARNING:** Run the setup sequence while connected to a stable, high-speed office internet connection. The setup process automatically fetches and caches several gigabytes of advanced neural network weights directly to the storage disk so that they are ready to run 100% offline later in remote field operations.

### 1. One-Time Setup Preparation

Depending on the operating system of the target deployment machine, execute the preparation scripts:

#### 🍏 On Apple Silicon MacBooks (macOS):

```bash
chmod +x setup.sh run.sh
./setup.sh

```

#### 🪟 On Windows Systems (PowerShell):

```powershell
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt

```

#### 🐧 On Linux Systems / Enterprise Edge Servers:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

```

*The setup sequence configures virtual environment frameworks, sets up internal directories (`uploads/` and `outputs/`), verifies local FFmpeg configuration links, and caches the primary translation weights.*

### 2. Launching the Local Engine

Whenever you are out in the field, launch the local server platform instance:

```bash
# On Mac/Linux Environments
./run.sh

# On Windows (With active virtual environment)
uvicorn src.backend.main:app --host 0.0.0.0 --port 8000 --reload

```

---

## 📱 Field Usage & Multi-Device Hotspot Pairing

When the boot routines initiate, the system automatically hooks onto available local network bindings and interfaces:

```text
--------------------------------------------------------
🌐 Local Computer Access: http://localhost:8000
📱 Field Tablet Hotspot Access: [http://192.168.1.45:8000](http://192.168.1.45:8000)
--------------------------------------------------------

```

1. **On the Host Workstation:** Open `http://localhost:8000` inside your web browser to operate the master control console.
2. **On Nearby Field Tablets/Phones:** Enable the laptop's Wi-Fi hotspot configuration utility. Connect the field devices to that hotspot, open a mobile browser tab, and navigate to the identified **Field Tablet Hotspot Access IP** (e.g., `http://192.168.1.45:8000`) to access and use the translation tool simultaneously without cellular network signals!
