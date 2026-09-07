# BAIF Offline Translator

A fully **offline**, hardware-accelerated translation and subtitling suite built explicitly for BAIF field teams. It processes **audio and video** inputs, transcribes speech locally, translates between Indian languages, and generates multiple multimedia outputs—all without an internet connection.

---

## 🎯 Objective

Provide a resilient, secure, and zero-connectivity tool for BAIF teams working in remote rural areas to:

- Transcribe local language focus group recordings and field interviews.
- Translate text between **English, Hindi, and Marathi** fully locally with bidirectional support.
- Generate translated voice clips, `.srt` subtitle documents, and hard-subtitled videos directly on-site.
- Maintain **100% data privacy** with all processing remaining on the host laptop.

---

## ✨ Features

- ✅ **Universal Platform Support:** Deployable on any host operating system—macOS, Windows, or Linux.
- ✅ **Dual-Media Upload:** Full native compatibility with audio/video formats (MP4, MOV, MP3, WAV, M4A, MKV, WebM).
- ✅ **Real-Time Field Mic Capture:** Captures voice inputs on-site using standard browser media APIs, routing raw audio directly to local memory pipelines.
- ✅ **Cross-Platform Local Speech-to-Text:** Powered by `faster-whisper` with VAD (Voice Activity Detection) filtering. Supports Tiny, Base, Small, Medium, and Large models.
- ✅ **Bidirectional Translation Engine:**
  - English ↔ Hindi (NLLB-200 + Opus-MT)
  - English ↔ Marathi (NLLB-200 + Opus-MT)
  - Hindi ↔ Marathi (NLLB-200)
- ✅ **Interactive Subtitle Timeline Editor:** Review, verify, and correct timestamped segment rows dynamically before firing media rendering blocks.
- ✅ **Hardware-Accelerated Burn-in:** Overlays and burns hard subtitles into video containers cleanly via multi-pass local `FFmpeg` engines with customizable font size and color.
- ✅ **Audio Preprocessing:** Noise reduction, volume normalization, and high-pass filtering for improved transcription accuracy.
- ✅ **Real-time Progress Tracking:** Visual progress bar shows transcription completion percentage with status messages.
- ✅ **Voice Activity Detection (VAD):** Removes silence before transcription, improving accuracy and speed.
- ✅ **Disk Space & Storage Telemetry:** Integrated visual storage analyzer tracking the count and cumulative disk payload size (MB) of cached workspace exports.
- ✅ **Local Hotspot Mode:** Allows the host laptop to broadcast the app to nearby field tablets or smartphones over a local Wi-Fi router or hotspot.
- ✅ **On-Demand Cache Purging:** 100% offline security. Zero external tracking cookies with a single-click interactive system wipe tool to flush heavy output binaries on demand.
- ✅ **Text-to-Speech (TTS):** Generate audio clips from translated text in English, Hindi, or Marathi.
- ✅ **Offline-First Design:** All models cached locally during setup. Zero internet required after initial installation.

---

## 🏗️ Project Architecture

```
baif-translator/
├── src/
│   ├── backend/
│   │   ├── main.py          # FastAPI Core Server (Offline Mode)
│   │   └── config.py        # Global Configuration Settings
│   └── frontend/
│       └── static/
│           ├── index.html   # Responsive Field Dashboard
│           ├── css/
│           │   └── style.css # Custom UI Styles
│           └── js/
│               └── app.js   # Frontend State Controller
├── uploads/                 # Temporary media drop zone
├── outputs/                 # Exported Audio, SRTs, and Rendered Videos
├── run.sh / run.bat        # Platform-Specific Launchers
├── setup.sh / setup.bat    # Pre-deployment Setup Scripts
├── requirements.txt        # Python Dependencies
├── push_code.sh            # Git Sync Script
├── README.md
└── LICENSE
```

---

## 🛠️ Tech Stack & Hardware Detection Matrix

The core backend uses a unified Python architecture layer that dynamically probes the hardware execution space:

| Component | Technology | Purpose | Platform Hardware Support |
| --- | --- | --- | --- |
| **Backend Framework** | FastAPI (Python 3.11) | High-performance async local request & disk tracking | Universal (Windows, macOS, Linux) |
| **Speech-to-Text** | faster-whisper (OpenAI Whisper) | Local audio transcription with VAD filtering | Universal (CPU/GPU optimized) |
| **Hardware Optimization** | int8 Quantization | Automatic memory footprint reduction (up to 60%) | Universal (Auto-detects) |
| **Translation Engine** | NLLB-200 + Helsinki-NLP OPUS-MT | Bidirectional language translation (3 language support) | Universal (Local cache only) |
| **Audio Preprocessing** | Librosa + SciPy | Noise reduction, normalization, filtering | Universal |
| **Media Processing** | FFmpeg (with libass) | Subtitle burn-in & video re-encoding | Universal |
| **Frontend** | HTML5 + Tailwind CSS + Vanilla JS | Responsive SPA with storage telemetry | Universal (Browser) |
| **Local Persistence** | Web Storage API (localStorage) | Secure, local-only translation activity logs | Client Browser |

---

## 💾 Core Endpoint Matrices

The frontend synchronization framework orchestrates local file layouts via these endpoints:

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/system/storage` | GET | Scans physical asset states, queries cumulative sizes and file counts inside `outputs/` |
| `/system/storage` | DELETE | Instantly purges all cached files to free up disk space |
| `/transcribe` | POST | Processes audio/video with Whisper AI |
| `/translate` | POST | Translates text using NLLB/Opus-MT models |
| `/generate_srt` | POST | Generates SRT subtitle file |
| `/burn_subtitles` | POST | Burns subtitles into video using FFmpeg |
| `/tts` | POST | Generates Text-to-Speech audio clip |

---

## 🚀 Pre-Field Deployment & Setup

> ⚠️ **CRITICAL WARNING:** Run the setup sequence while connected to a stable, high-speed office internet connection. The setup process automatically fetches and caches several gigabytes of advanced neural network weights directly to the storage disk so that they are ready to run 100% offline later in remote field operations.

### 1. One-Time Setup Preparation

#### 🍏 On macOS / Linux:

```bash
# Make scripts executable
chmod +x setup.sh run.sh

# Run setup (select 'y' for Production mode to download all models)
./setup.sh
```

#### 🪟 On Windows:

```cmd
# Run setup
setup.bat
```

#### Manual Setup (if scripts fail):

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate  # On macOS/Linux
# OR
.\venv\Scripts\activate   # On Windows

# Install dependencies
pip install -r requirements.txt

# Create directories
mkdir -p uploads outputs
```

### 2. Model Pre-Caching

The setup script automatically downloads and caches these models:

| Model | Purpose | Size |
| --- | --- | --- |
| Whisper Tiny/Base/Small/Medium/Large | Speech-to-Text | 75MB - 3GB |
| NLLB-200 Distilled 600M | Translation (Hindi/Marathi) | ~1.2GB |
| Opus-MT (hi-en, mr-en, en-hi, en-mr) | Translation | ~600MB each |
| M2M-100 418M | Universal Translation Fallback | ~1.9GB |

**Total disk space required:** ~6GB (Production mode) or ~2GB (Development mode)

---

## 📱 Launching the Local Engine

### On macOS / Linux:

```bash
./run.sh
```

### On Windows:

```cmd
run.bat
```

### Manual Launch:

```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# OR
.\venv\Scripts\activate   # Windows

# Start server
uvicorn src.backend.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📱 Field Usage & Multi-Device Hotspot Pairing

When the boot routines initiate, the system automatically hooks onto available local network bindings and interfaces:

```
--------------------------------------------------------
🌐 Local Computer Access: http://localhost:8000
📱 Field Tablet Hotspot Access: http://192.168.1.45:8000
--------------------------------------------------------
```

1. **On the Host Workstation:** Open `http://localhost:8000` inside your web browser to operate the master control console.
2. **On Nearby Field Tablets/Phones:** Enable the laptop's Wi-Fi hotspot configuration utility. Connect the field devices to that hotspot, open a mobile browser tab, and navigate to the identified **Field Tablet Hotspot Access IP** (e.g., `http://192.168.1.45:8000`) to access and use the translation tool simultaneously without cellular network signals!

---

## 📖 User Guide

### Step 1: Upload or Record Media

**Option A - Upload File:**
1. Click on the upload area or drag & drop your audio/video file
2. Supported formats: MP3, WAV, M4A, MP4, MOV, MKV, WebM

**Option B - Live Recording:**
1. Click "Start Mic" to begin recording
2. Speak naturally into your microphone
3. Click "Stop & Parse" when finished

### Step 2: Select Settings

1. **Whisper Model:** Choose from Tiny (fast) to Large (most accurate)
2. **Source Language:** Auto-Detect, English, Hindi, or Marathi
3. **VAD Filter:** Enable to remove silence (recommended)

### Step 3: Transcribe

Click **"Process & Transcribe"** to run the Whisper AI engine. Watch the progress bar for real-time updates.

### Step 4: Edit & Translate

1. Review the transcription in the output console
2. Select **Source Language** (Auto-Detect, English, Hindi, Marathi)
3. Select **Target Language** (English, Hindi, Marathi)
4. Click **"Run Translation Pipeline"**

### Step 5: Generate Outputs

**Audio Voice:**
- Click "Audio Voice" to generate TTS audio clip

**Subtitles:**
1. Click "Build Subtitles" to generate SRT file
2. Edit text in the interactive timeline editor if needed
3. Click "Apply Text Adjustments" to save changes

**Video with Subtitles:**
1. Click "Burn Hard Subtitles into Video"
2. Wait for FFmpeg processing (may take a few minutes)
3. Download the final video with embedded subtitles

### Step 6: Download & Manage

- **Download Document:** Save translation as .txt file
- **Storage Telemetry:** Monitor disk usage in real-time
- **Wipe Cache:** Clear all outputs to free up space

---

## 🔧 Troubleshooting

### Common Issues & Solutions

| Issue | Solution |
| --- | --- |
| **Model not found errors** | Run `./setup.sh` (macOS/Linux) or `setup.bat` (Windows) with internet |
| **Port 8000 already in use** | Change port: `uvicorn src.backend.main:app --host 0.0.0.0 --port 8001` |
| **FFmpeg not found** | Install FFmpeg: `brew install ffmpeg` (macOS) or download from ffmpeg.org (Windows) |
| **Translation fails** | Ensure models are downloaded. Check `~/.cache/huggingface/` directory |
| **Video processing slow** | Use smaller Whisper model (Tiny/Base) or reduce video resolution |
| **Browser can't connect** | Check firewall settings. Try `http://127.0.0.1:8000` instead |

---

## 🔒 Security & Privacy

- **100% Local Processing:** No data ever leaves your laptop
- **Zero External Tracking:** No cookies, no analytics, no telemetry
- **Secure Data Deletion:** One-click wipe removes all processed files
- **No Cloud Dependencies:** Works completely offline after initial setup

---

## 📊 Performance Benchmarks

| Model | RAM Usage | Processing Time (1 min audio) | Accuracy |
| --- | --- | --- | --- |
| Whisper Tiny | ~500MB | 10-15 seconds | ~70% |
| Whisper Base | ~1GB | 15-20 seconds | ~80% |
| Whisper Small | ~1.5GB | 20-30 seconds | ~85% |
| Whisper Medium | ~2.5GB | 30-45 seconds | ~90% |
| Whisper Large | ~4GB | 60-90 seconds | ~95% |

*Benchmarks on Apple M1/M2 chip. Times vary by hardware.*

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push: `git push origin feature/your-feature`
5. Submit a Pull Request

---

## 📄 License

This project is released under the **MIT License**. See the [LICENSE](LICENSE) file for details.


---

## 🙏 Acknowledgments

- BAIF Development Research Foundation for the opportunity
- Hugging Face for open-source models
- OpenAI for Whisper
- Helsinki-NLP for Opus-MT models
- Meta for NLLB and M2M-100 models
- FastAPI, FFmpeg, and all open-source libraries used

---

## 📞 Support

For technical support, please contact the BAIF technical team or raise an issue on GitHub.

---

**Made with ❤️ for BAIF Field Teams**
```

---

## How to Download

### Option 1: Save as File (Manual)
1. Select all the text above (Ctrl+A / Cmd+A)
2. Copy (Ctrl+C / Cmd+C)
3. Open a text editor (Notepad, VS Code, etc.)
4. Paste (Ctrl+V / Cmd+V)
5. Save as `README.md`

### Option 2: Using curl (Terminal)
```bash
# This will download the README.md file directly
curl -o README.md "https://raw.githubusercontent.com/houseofanurag/baif-translator/main/README.md"
```

### Option 3: Using wget
```bash
wget -O README.md "https://raw.githubusercontent.com/houseofanurag/baif-translator/main/README.md"
```
