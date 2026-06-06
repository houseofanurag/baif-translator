// ================================================
// BAIF Offline Translator - Complete Frontend Engine
// ================================================

let currentText = "";
let currentTranslatedText = "";
let currentSegments = [];
let currentFileName = "";
let currentSrtFileName = "";

// Microphone Capture Instances Tracking
let mediaRecorder;
let audioChunks = [];
let recordInterval;
let startTime;

function updateButtonStates() {
  const hasTranscription = currentText.trim().length > 0;
  const hasTranslation = currentTranslatedText.trim().length > 0 && currentTranslatedText !== currentText;
  
  document.getElementById('translateBtn').disabled = !hasTranscription;
  document.getElementById('srtBtn').disabled = !hasTranscription;
  document.getElementById('burnBtn').disabled = !hasSrtFile();
  document.getElementById('downloadBtn').disabled = !hasTranslation;
  document.getElementById('ttsBtn').disabled = !hasTranslation;

  // Update visual wizard steps based on active milestones
  const badge1 = document.getElementById('step1-badge');
  const badge2 = document.getElementById('step2-badge');
  const badge3 = document.getElementById('step3-badge');

  if (hasTranscription) {
    badge1.className = "w-8 h-8 rounded-full bg-emerald-500 text-white flex items-center justify-center text-xs font-bold";
    badge1.innerHTML = "✓";
    badge2.className = "w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center text-xs font-bold";
  }
  if (hasTranslation) {
    badge2.className = "w-8 h-8 rounded-full bg-emerald-500 text-white flex items-center justify-center text-xs font-bold";
    badge2.innerHTML = "✓";
    badge3.className = "w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center text-xs font-bold";
  }
}

function hasSrtFile() {
  return currentSrtFileName.trim().length > 0;
}

function handleFileSelect() {
  const fileInput = document.getElementById('mediaFile');
  const fileNameEl = document.getElementById('fileName');
  const uploadIcon = document.getElementById('uploadIcon');
  const uploadPrompt = document.getElementById('uploadPrompt');

  if (fileInput.files.length > 0) {
    currentFileName = fileInput.files[0].name;
    fileNameEl.textContent = currentFileName;
    fileNameEl.classList.remove('hidden');
    uploadPrompt.textContent = "Media Selected Ready";
    uploadIcon.className = "fas fa-check-circle text-2xl text-emerald-500";
    
    // Auto-setup simple video layout preview container if it's an MP4/MOV format
    const isVideo = fileInput.files[0].type.startsWith('video/') || currentFileName.endsWith('.mp4') || currentFileName.endsWith('.mov');
    if (isVideo) {
      const url = URL.createObjectURL(fileInput.files[0]);
      const previewVideo = document.getElementById('previewVideo');
      previewVideo.src = url;
      document.getElementById('videoContainer').classList.remove('hidden');
      document.getElementById('mediaPreviews').classList.remove('hidden');
    }
  }
}

function renderResult() {
  const container = document.getElementById('resultContent');
  if (!container) return;

  if (!currentText && !currentTranslatedText) {
    container.innerHTML = `
      <div class="text-center py-12 text-slate-400">
        <i class="fas fa-folder-open text-3xl mb-3 block text-slate-300"></i>
        <p class="text-sm">Results will appear here dynamically after processing local models.</p>
      </div>`;
    return;
  }

  let html = '<div class="grid md:grid-cols-2 gap-6">';

  if (currentText) {
    html += `
      <div class="space-y-2">
        <h4 class="text-xs font-bold text-blue-700 uppercase tracking-wider flex items-center gap-1.5">
          <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> Original Transcription Output
        </h4>
        <div class="bg-slate-50 p-4 border border-slate-200/50 rounded-2xl text-slate-700 text-sm leading-relaxed whitespace-pre-wrap max-h-[300px] overflow-y-auto">${currentText}</div>
      </div>`;
  }

  if (currentTranslatedText && currentTranslatedText !== currentText) {
    const targetLang = document.getElementById('targetLang').value.toUpperCase();
    html += `
      <div class="space-y-2">
        <h4 class="text-xs font-bold text-emerald-700 uppercase tracking-wider flex items-center gap-1.5">
          <span class="w-1.5 h-1.5 rounded-full bg-emerald-600"></span> Translated Language Text (${targetLang})
        </h4>
        <div class="bg-emerald-50 p-4 border border-emerald-200/50 rounded-2xl text-slate-800 text-sm leading-relaxed whitespace-pre-wrap max-h-[300px] overflow-y-auto font-medium">${currentTranslatedText}</div>
      </div>`;
  } else if (currentText) {
    html += `
      <div class="space-y-2 flex flex-col justify-center items-center bg-slate-50/50 border border-dashed border-slate-200 rounded-2xl p-4 text-slate-400 text-xs">
        <i class="fas fa-arrow-left text-lg mb-1 text-slate-300"></i>
        <span>Select target language above to apply local conversion models.</span>
      </div>`;
  }

  html += '</div>';
  container.innerHTML = html;
}

function showStatus(message, statusType = "info") {
  const status = document.getElementById('status');
  if (!status) return;
  status.classList.remove('hidden');

  let icon = '<i class="fas fa-circle-notch animate-spin text-blue-400 text-sm"></i>';
  if (statusType === "success") icon = '<i class="fas fa-check-circle text-emerald-400 text-sm"></i>';
  if (statusType === "error") icon = '<i class="fas fa-exclamation-triangle text-rose-400 text-sm"></i>';

  status.innerHTML = `${icon} <span class="flex-1">${message}</span>`;
  
  if (statusType === "success" || statusType === "error") {
    setTimeout(() => status.classList.add('hidden'), 5000);
  }
}

// ==================== Local History Trackers ====================
function saveToHistory() {
  if (!currentTranslatedText) return;
  const history = JSON.parse(localStorage.getItem('baif_history') || '[]');
  const entry = {
    timestamp: new Date().toLocaleString('en-IN'),
    original: currentText.substring(0, 60) + (currentText.length > 60 ? '...' : ''),
    translated: currentTranslatedText.substring(0, 60) + (currentTranslatedText.length > 60 ? '...' : ''),
    targetLang: document.getElementById('targetLang').value.toUpperCase(),
    fileName: currentFileName || 'Local Track'
  };
  history.unshift(entry);
  localStorage.setItem('baif_history', JSON.stringify(history.slice(0, 5)));
  renderHistory();
}

function renderHistory() {
  const container = document.getElementById('historyList');
  if (!container) return;
  const history = JSON.parse(localStorage.getItem('baif_history') || '[]');
  if (history.length === 0) {
    container.innerHTML = '<p class="text-slate-400 text-xs italic py-2">No local operations processed in this browser engine session.</p>';
    return;
  }
  container.innerHTML = history.map(item => `
    <div class="bg-white p-3 rounded-xl text-xs border border-slate-200/60 shadow-2xs">
      <div class="flex justify-between text-[10px] text-slate-400 mb-1 font-medium">
        <span>${item.timestamp}</span>
        <span class="bg-slate-100 px-1.5 py-0.5 rounded text-slate-600 font-bold">${item.targetLang}</span>
      </div>
      <div class="font-semibold text-slate-800 line-clamp-1 mb-0.5">${item.translated}</div>
      <div class="text-[10px] text-slate-400 truncate"><i class="fas fa-paperclip mr-0.5"></i> ${item.fileName}</div>
    </div>
  `).join('');
}

// ==================== Clear All View States ====================
function clearAll() {
  if (!confirm("Flush all runtime localized text fields and cached instances?")) return;

  currentText = currentTranslatedText = "";
  currentSegments = [];
  currentFileName = "";
  currentSrtFileName = "";

  document.getElementById('mediaFile').value = "";
  const fileNameEl = document.getElementById('fileName');
  if (fileNameEl) {
    fileNameEl.textContent = "";
    fileNameEl.classList.add('hidden');
  }
  document.getElementById('uploadIcon').className = "fas fa-cloud-upload-alt text-2xl text-slate-400";
  document.getElementById('uploadPrompt').textContent = "Choose a file to begin";

  renderResult();
  document.getElementById('audioPlayer').innerHTML = "";
  document.getElementById('videoContainer').classList.add('hidden');
  document.getElementById('mediaPreviews').classList.add('hidden');
  document.getElementById('srtLink').innerHTML = "";
  document.getElementById('burnedVideoLink').innerHTML = "";
  document.getElementById('downloadLinksCard').classList.add('hidden');
  
  // Reset wizards
  document.getElementById('step1-badge').className = "w-8 h-8 rounded-full bg-blue-500 text-white flex items-center justify-center text-xs font-bold";
  document.getElementById('step1-badge').innerHTML = "1";
  document.getElementById('step2-badge').className = "w-8 h-8 rounded-full bg-white/20 text-white/60 flex items-center justify-center text-xs font-bold";
  document.getElementById('step3-badge').className = "w-8 h-8 rounded-full bg-white/20 text-white/60 flex items-center justify-center text-xs font-bold";

  updateButtonStates();
}

// ==================== Operational Core Tasks ====================

async function transcribe() {
  const fileInput = document.getElementById('mediaFile');
  if (!fileInput.files.length) return alert("Please map an operational audio or video media file first.");

  currentFileName = fileInput.files[0].name;
  currentText = ""; 
  currentTranslatedText = "";
  currentSegments = [];
  currentSrtFileName = "";
  renderResult();
  updateButtonStates();

  showStatus(`MLX Whisper initializing local compute cores for ${currentFileName}...`, "info");

  const formData = new FormData();
  formData.append("file", fileInput.files[0]);

  try {
    const res = await fetch("/transcribe", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentText = data.transcribed_text;
      currentSegments = data.segments || [];
      showStatus("✅ MLX Core Transcription Finished", "success");
      renderResult();
      updateButtonStates();
    } else {
      showStatus(`❌ Error: ${data.message}`, "error");
    }
  } catch (e) {
    showStatus("❌ Transcription engine execution dropped or timed out.", "error");
  }
}

async function translateText() {
  if (!currentText) return alert("Missing base context transcript. Run transcription first.");
  const targetLang = document.getElementById('targetLang').value;
  showStatus(`Loading local HuggingFace Pipeline Transformer for target syntax: [${targetLang.toUpperCase()}]...`, "info");

  const formData = new FormData();
  formData.append("text", currentText);
  formData.append("target_lang", targetLang);

  try {
    const res = await fetch("/translate", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentTranslatedText = data.translated;
      showStatus(`✅ Translation complete to [${targetLang.toUpperCase()}]`, "success");
      renderResult();
      updateButtonStates();
      saveToHistory();
    }
  } catch (e) {
    showStatus("❌ Translation framework compute encountered an error.", "error");
  }
}

async function generateTTS() {
  if (!currentTranslatedText) return alert("Please process translation before building speech synthesis.");
  const targetLang = document.getElementById('targetLang').value;

  showStatus("Executing hardware-accelerated speech synthesis command pipelines...", "info");

  const formData = new FormData();
  formData.append("text", currentTranslatedText);
  formData.append("lang", targetLang);

  try {
    const res = await fetch("/tts", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success" && data.audio_url) {
      showStatus("✅ Localized Audio Clip Created!", "success");
      document.getElementById('mediaPreviews').classList.remove('hidden');
      
      const readableLang = targetLang === "en" ? "English" : targetLang === "hi" ? "Hindi" : "Marathi";
      document.getElementById('audioPlayer').innerHTML = `
        <label class="text-[10px] font-bold text-emerald-600 block mb-1 uppercase tracking-wider">Synthesized ${readableLang} Voice Output</label>
        <audio controls class="w-full rounded-lg bg-slate-50 border p-1"><source src="${data.audio_url}" type="audio/mp3"></audio>`;
    } else {
      showStatus(`❌ Engine feedback details: ${data.message}`, "error");
    }
  } catch (e) {
    showStatus("❌ Local speech engine pipeline processing dropped.", "error");
  }
}

async function generateSRT() {
  if (currentSegments.length === 0) return alert("No active timeline matrices found. Transcribe your target video first.");

  showStatus("Calculating target language timestamps and packing subtitle data structure...", "info");

  const targetLang = document.getElementById('targetLang').value;
  const formData = new FormData();
  formData.append("segments", JSON.stringify(currentSegments));
  formData.append("filename", currentFileName || "baif_recording");
  formData.append("target_lang", targetLang);

  try {
    const res = await fetch("/generate_srt", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentSrtFileName = data.srt_url.split('/').pop();
      showStatus("✅ Structured SRT Matrix Compiled Successfully", "success");
      
      document.getElementById('downloadLinksCard').classList.remove('hidden');
      document.getElementById('srtLink').innerHTML = `
        <a href="${data.srt_url}" download class="flex items-center justify-between bg-amber-50 border border-amber-200 text-amber-800 text-xs px-4 py-3 rounded-xl hover:bg-amber-100 transition font-semibold">
          <span><i class="fas fa-file-subtitles mr-1.5"></i> Download Subtitle File (.srt)</span>
          <i class="fas fa-download text-amber-600"></i>
        </a>`;
      updateButtonStates();
    }
  } catch (e) {
    showStatus("❌ Subtitle generation stack encountered a matrix layout error.", "error");
  }
}

async function burnSubtitles() {
  if (!hasSrtFile()) return alert("Please build standard subtitle assets before firing burning routines.");

  showStatus("Processing high-intensity FFmpeg multi-pass overlay. Do not close app...", "info");

  const fileInput = document.getElementById('mediaFile');
  if (!fileInput.files.length) return alert("Original file trace is missing. Re-map media link.");

  const formData = new FormData();
  formData.append("original_video", fileInput.files[0]);
  formData.append("srt_filename", currentSrtFileName);

  try {
    const res = await fetch("/burn_subtitles", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      showStatus("✅ Video Burn Processing Executed Perfectly!", "success");
      
      document.getElementById('downloadLinksCard').classList.remove('hidden');
      document.getElementById('burnedVideoLink').innerHTML = `
        <a href="${data.video_url}" download class="flex items-center justify-between bg-red-50 border border-red-200 text-red-800 text-xs px-4 py-3 rounded-xl hover:bg-red-100 transition font-semibold">
          <span><i class="fas fa-film mr-1.5"></i> Download Embedded Subtitle Video</span>
          <i class="fas fa-download text-red-600"></i>
        </a>`;
      
      const previewVideo = document.getElementById('previewVideo');
      previewVideo.src = data.video_url;
    } else {
      showStatus(`❌ Engine feedback details: ${data.message}`, "error");
    }
  } catch (e) {
    showStatus("❌ Video hard rendering logic broke. Check system asset logs.", "error");
  }
}

function downloadTranslatedText() {
  if (!currentTranslatedText) return alert("No operational translation output is active.");
  const targetLang = document.getElementById('targetLang').value;
  const blob = new Blob([currentTranslatedText], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `BAIF_Translated_${targetLang.toUpperCase()}_${currentFileName || 'document'}.txt`;
  a.click();
  URL.revokeObjectURL(url);
}

// ================================================
// LIVE MIC RECORDING CAPTURE SUB-SYSTEM
// ================================================

async function startRecording() {
  audioChunks = [];
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    
    // Auto-detect container structures based on browser engine specifications
    const options = MediaRecorder.isTypeSupported('audio/webm') ? { mimeType: 'audio/webm' } : { mimeType: 'audio/mp4' };
    mediaRecorder = new MediaRecorder(stream, options);
    
    mediaRecorder.ondataavailable = event => {
      if (event.data.size > 0) audioChunks.push(event.data);
    };

    mediaRecorder.onstop = async () => {
      const extension = options.mimeType.includes('webm') ? 'webm' : 'mp4';
      const audioBlob = new Blob(audioChunks, { type: options.mimeType });
      const audioFile = new File([audioBlob], `live_capture_${Date.now()}.${extension}`, { type: options.mimeType });
      
      // Release hardware audio track bindings cleanly
      stream.getTracks().forEach(track => track.stop());
      
      // Relay audio payload straight into processing pipeline
      await uploadLiveRecording(audioFile);
    };

    // UI Configuration Mapping
    document.getElementById('startRecordBtn').disabled = true;
    document.getElementById('startRecordBtn').classList.add('opacity-40', 'cursor-not-allowed');
    
    const stopBtn = document.getElementById('stopRecordBtn');
    stopBtn.disabled = false;
    stopBtn.className = "flex-1 bg-rose-600 text-white text-xs px-4 py-3.5 rounded-xl font-semibold hover:bg-rose-700 transition flex items-center justify-center gap-2 shadow-sm";

    // Launch running elapsed clock matrix
    startTime = Date.now();
    const timerEl = document.getElementById('recordingTimer');
    timerEl.classList.remove('hidden', 'text-slate-400');
    timerEl.classList.add('text-rose-600', 'animate-pulse');
    
    recordInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000);
      const mins = String(Math.floor(elapsed / 60)).padStart(2, '0');
      const secs = String(elapsed % 60).padStart(2, '0');
      timerEl.textContent = `${mins}:${secs}`;
    }, 1000);

    mediaRecorder.start();
    showStatus("🔴 Microphone is live. Recording audio...", "info");

  } catch (err) {
    console.error("Mic Access Denied:", err);
    alert("Microphone hardware access denied. Check browser privacy credentials.");
  }
}

function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== "inactive") {
    mediaRecorder.stop();
    
    clearInterval(recordInterval);
    const timerEl = document.getElementById('recordingTimer');
    timerEl.classList.add('hidden');
    
    document.getElementById('startRecordBtn').disabled = false;
    document.getElementById('startRecordBtn').classList.remove('opacity-40', 'cursor-not-allowed');
    
    const stopBtn = document.getElementById('stopRecordBtn');
    stopBtn.disabled = true;
    stopBtn.className = "flex-1 bg-slate-100 text-slate-400 text-xs px-4 py-3.5 rounded-xl font-semibold transition flex items-center justify-center gap-2 cursor-not-allowed";
  }
}

async function uploadLiveRecording(file) {
  currentFileName = file.name;
  currentText = ""; 
  currentTranslatedText = "";
  currentSegments = [];
  currentSrtFileName = "";
  renderResult();
  updateButtonStates();

  showStatus("Processing live recording audio bytes through local MLX Whisper compute layers...", "info");

  const formData = new FormData();
  formData.append("file", file);

  try {
    const res = await fetch("/transcribe", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentText = data.transcribed_text;
      currentSegments = data.segments || [];
      showStatus("✅ Live clip safely transcribed inside system core memory structures", "success");
      renderResult();
      updateButtonStates();
    } else {
      showStatus(`❌ Error processing live stream: ${data.message}`, "error");
    }
  } catch (e) {
    showStatus("❌ Local processing of real-time speech dropped down.", "error");
  }
}

document.addEventListener('DOMContentLoaded', () => {
  updateButtonStates();
  renderResult();
  renderHistory();
});