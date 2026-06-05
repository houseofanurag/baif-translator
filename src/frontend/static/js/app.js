// ================================================
// BAIF Offline Translator - Complete Working JS
// ================================================

let currentText = "";
let currentTranslatedText = "";
let currentSegments = [];
let currentFileName = "";
let currentSrtFileName = "";

function updateButtonStates() {
  const hasTranscription = currentText.length > 0;
  const hasTranslation = currentTranslatedText.length > 0;
  
  if (document.getElementById('translateBtn')) document.getElementById('translateBtn').disabled = !hasTranscription;
  if (document.getElementById('srtBtn')) document.getElementById('srtBtn').disabled = !hasTranscription;
  if (document.getElementById('burnBtn')) document.getElementById('burnBtn').disabled = !hasTranscription;
  if (document.getElementById('downloadBtn')) document.getElementById('downloadBtn').disabled = !hasTranslation;
  if (document.getElementById('ttsBtn')) document.getElementById('ttsBtn').disabled = !hasTranscription;
}

function renderResult() {
  const container = document.getElementById('resultContent');
  if (!container) return;

  let html = '';

  if (currentText) {
    html += `
      <div>
        <h4 class="font-semibold text-blue-700 mb-3 flex items-center gap-2">
          <i class="fas fa-file-alt"></i> Original Text
        </h4>
        <div class="bg-slate-50 p-6 rounded-2xl text-slate-700 leading-relaxed whitespace-pre-wrap">${currentText}</div>
      </div>`;
  }

  if (currentTranslatedText) {
    const targetLang = document.getElementById('targetLang').value.toUpperCase();
    html += `
      <div>
        <h4 class="font-semibold text-emerald-700 mb-3 flex items-center gap-2">
          <i class="fas fa-language"></i> Translated (${targetLang})
        </h4>
        <div class="bg-emerald-50 p-6 rounded-2xl text-slate-700 leading-relaxed whitespace-pre-wrap">${currentTranslatedText}</div>
      </div>`;
  }

  container.innerHTML = html || '<p class="text-slate-400 text-center py-16">Results will appear here after transcription...</p>';
}

function showStatus(message, isError = false) {
  const status = document.getElementById('status');
  if (!status) return;
  status.classList.remove('hidden');
  status.innerHTML = message;
  status.style.color = isError ? '#ef4444' : '#10b981';
  setTimeout(() => status.classList.add('hidden'), 7000);
}

// ==================== History ====================
function saveToHistory() {
  if (!currentTranslatedText) return;
  const history = JSON.parse(localStorage.getItem('baif_history') || '[]');
  const entry = {
    timestamp: new Date().toLocaleString('en-IN'),
    original: currentText.substring(0, 80) + (currentText.length > 80 ? '...' : ''),
    translated: currentTranslatedText.substring(0, 80) + (currentTranslatedText.length > 80 ? '...' : ''),
    targetLang: document.getElementById('targetLang').value.toUpperCase(),
    fileName: currentFileName || 'Untitled'
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
    container.innerHTML = '<p class="text-slate-400 text-sm italic">No previous translations yet.</p>';
    return;
  }
  container.innerHTML = history.map(item => `
    <div class="bg-slate-50 p-4 rounded-2xl text-sm border border-slate-100">
      <div class="text-xs text-slate-500 mb-1">${item.timestamp} • ${item.targetLang}</div>
      <div class="font-medium text-slate-700 line-clamp-2">${item.translated}</div>
    </div>
  `).join('');
}

// ==================== Clear All ====================
function clearAll() {
  if (!confirm("Clear all current results?")) return;

  currentText = currentTranslatedText = "";
  currentSegments = [];
  currentFileName = "";
  currentSrtFileName = "";

  document.getElementById('mediaFile').value = "";
  const fileNameEl = document.getElementById('fileName');
  if (fileNameEl) fileNameEl.textContent = "";

  renderResult();
  document.getElementById('audioPlayer').innerHTML = "";
  document.getElementById('srtLink').innerHTML = "";
  document.getElementById('burnedVideoLink').innerHTML = "";
  updateButtonStates();
}

// ==================== Core Functions ====================

async function transcribe() {
  const fileInput = document.getElementById('mediaFile');
  if (!fileInput.files.length) return alert("Please select a file");

  currentFileName = fileInput.files[0].name;
  const fileNameEl = document.getElementById('fileName');
  if (fileNameEl) fileNameEl.textContent = `File: ${currentFileName}`;

  currentText = currentTranslatedText = "";
  currentSegments = [];
  renderResult();

  showStatus(`Transcribing ${currentFileName}...`);

  const formData = new FormData();
  formData.append("file", fileInput.files[0]);

  try {
    const res = await fetch("/transcribe", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentText = currentTranslatedText = data.transcribed_text;
      currentSegments = data.segments || [];
      showStatus("✅ Transcription Completed");
      renderResult();
      updateButtonStates();
    }
  } catch (e) {
    showStatus("❌ Transcription Failed", true);
  }
}

async function translateText() {
  if (!currentText) return alert("Please transcribe first");
  const targetLang = document.getElementById('targetLang').value;
  showStatus("Translating...");

  const formData = new FormData();
  formData.append("text", currentText);
  formData.append("target_lang", targetLang);

  try {
    const res = await fetch("/translate", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentTranslatedText = data.translated;
      showStatus("✅ Translation Completed");
      renderResult();
      updateButtonStates();
      saveToHistory();
    }
  } catch (e) {
    showStatus("❌ Translation Failed", true);
  }
}

async function generateTTS() {
  if (!currentTranslatedText) return alert("Please translate first");
  const targetLang = document.getElementById('targetLang').value;

  if (targetLang !== "en") {
    showStatus("🔊 Voice generation is currently available only for English.<br>Hindi & Marathi voices coming soon.", false);
    return;
  }

  showStatus("Generating voice...");

  const formData = new FormData();
  formData.append("text", currentTranslatedText);
  formData.append("lang", "en");

  try {
    const res = await fetch("/tts", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success" && data.audio_url) {
      showStatus("✅ Voice Generated!");
      document.getElementById('audioPlayer').innerHTML = `<audio controls class="w-full mt-4"><source src="${data.audio_url}" type="audio/mp3"></audio>`;
    }
  } catch (e) {
    showStatus("❌ Voice Generation Failed", true);
  }
}

async function generateSRT() {
  if (currentSegments.length === 0) return alert("Please transcribe first!");

  showStatus("Generating SRT...");

  const formData = new FormData();
  formData.append("segments", JSON.stringify(currentSegments));
  formData.append("filename", currentFileName || "baif_recording");

  try {
    const res = await fetch("/generate_srt", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentSrtFileName = data.srt_url.split('/').pop();
      showStatus("✅ SRT Generated!");
      document.getElementById('srtLink').innerHTML = `
        <a href="${data.srt_url}" download class="inline-flex items-center gap-3 bg-amber-600 text-white px-8 py-4 rounded-3xl hover:bg-amber-700">
          📥 Download SRT Subtitle File
        </a>`;
    }
  } catch (e) {
    showStatus("❌ SRT Generation Failed", true);
  }
}

async function burnSubtitles() {
  if (currentSegments.length === 0) return alert("Please generate SRT first!");

  showStatus("Burning subtitles into video...");

  const fileInput = document.getElementById('mediaFile');
  if (!fileInput.files.length) return alert("Please upload the original video again");

  const formData = new FormData();
  formData.append("original_video", fileInput.files[0]);
  formData.append("srt_filename", currentSrtFileName);

  try {
    const res = await fetch("/burn_subtitles", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      showStatus("✅ Subtitles Burned!");
      document.getElementById('burnedVideoLink').innerHTML = `
        <a href="${data.video_url}" download class="inline-flex items-center gap-3 bg-red-600 text-white px-8 py-4 rounded-3xl hover:bg-red-700">
          📥 Download Video with Burned Subtitles
        </a>`;
    } else {
      showStatus(`❌ ${data.message}`, true);
    }
  } catch (e) {
    showStatus("❌ Failed to burn subtitles", true);
  }
}

function downloadTranslatedText() {
  if (!currentTranslatedText) return alert("No translated text available");
  const targetLang = document.getElementById('targetLang').value;
  const blob = new Blob([currentTranslatedText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `translated_${targetLang}_${currentFileName || 'output'}.txt`;
  a.click();
  URL.revokeObjectURL(url);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  updateButtonStates();
  renderResult();
  renderHistory();
});
