// BAIF Offline Translator - Main JavaScript

let currentText = "";
let currentTranslatedText = "";
let currentSegments = [];
let currentFileName = "";
let currentSrtFileName = "";

function updateButtonStates() {
  const hasTranscription = currentText.length > 0;
  const hasTranslation = currentTranslatedText.length > 0;
  
  document.getElementById('translateBtn').disabled = !hasTranscription;
  document.getElementById('srtBtn').disabled = !hasTranscription;
  document.getElementById('burnBtn').disabled = !hasTranscription;
  document.getElementById('downloadBtn').disabled = !hasTranslation;
  document.getElementById('ttsBtn').disabled = !hasTranscription;
}

function renderResult() {
  const container = document.getElementById('resultContent');
  let html = '';

  if (currentText) {
    html += `
      <div>
        <h4 class="font-semibold text-blue-700 mb-3 flex items-center gap-2">
          <i class="fas fa-file-alt"></i> Original Text
        </h4>
        <div class="bg-slate-50 p-5 rounded-2xl text-slate-700 leading-relaxed whitespace-pre-wrap">${currentText}</div>
      </div>`;
  }

  if (currentTranslatedText) {
    const targetLang = document.getElementById('targetLang').value.toUpperCase();
    html += `
      <div>
        <h4 class="font-semibold text-emerald-700 mb-3 flex items-center gap-2">
          <i class="fas fa-language"></i> Translated (${targetLang})
        </h4>
        <div class="bg-emerald-50 p-5 rounded-2xl text-slate-700 leading-relaxed whitespace-pre-wrap">${currentTranslatedText}</div>
      </div>`;
  }

  container.innerHTML = html || '<p class="text-slate-400 text-center py-12">Results will appear here after transcription...</p>';
}

// ==================== Core Functions ====================

async function transcribe() {
  const fileInput = document.getElementById('mediaFile');
  const status = document.getElementById('status');

  if (!fileInput.files.length) return alert("Please select a file");

  currentFileName = fileInput.files[0].name;
  document.getElementById('fileName').textContent = `File: ${currentFileName}`;

  // Clear previous results
  currentText = currentTranslatedText = "";
  currentSegments = [];
  document.getElementById('resultContent').innerHTML = "";
  document.getElementById('audioPlayer').innerHTML = "";
  document.getElementById('srtLink').innerHTML = "";
  document.getElementById('burnedVideoLink').innerHTML = "";

  status.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Transcribing ${currentFileName}...`;

  const formData = new FormData();
  formData.append("file", fileInput.files[0]);

  try {
    const res = await fetch("/transcribe", { method: "POST", body: formData });
    const data = await res.json();
    
    if (data.status === "success") {
      currentText = currentTranslatedText = data.transcribed_text;
      currentSegments = data.segments || [];
      status.innerHTML = `✅ Transcription Completed`;
      renderResult();
      updateButtonStates();
    }
  } catch (e) {
    status.innerHTML = `❌ Transcription Failed`;
  }
}

async function translateText() {
  const status = document.getElementById('status');
  const targetLang = document.getElementById('targetLang').value;

  if (!currentText) return;

  status.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Translating...`;

  const formData = new FormData();
  formData.append("text", currentText);
  formData.append("target_lang", targetLang);

  try {
    const res = await fetch("/translate", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      currentTranslatedText = data.translated;
      status.innerHTML = `✅ Translation Completed`;
      renderResult();
      updateButtonStates();
    }
  } catch (e) {
    status.innerHTML = `❌ Translation Failed`;
  }
}

async function generateTTS() {
  const status = document.getElementById('status');
  const audioDiv = document.getElementById('audioPlayer');
  const targetLang = document.getElementById('targetLang').value;

  if (!currentTranslatedText) return;

  status.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Generating Voice...`;

  const formData = new FormData();
  formData.append("text", currentTranslatedText);
  formData.append("lang", targetLang);

  try {
    const res = await fetch("/tts", { method: "POST", body: formData });
    const data = await res.json();

    if (data.status === "success" && data.audio_url) {
      status.innerHTML = `✅ Voice Generated!`;
      audioDiv.innerHTML = `<audio controls class="w-full mt-4"><source src="${data.audio_url}" type="audio/mp3"></audio>`;
    } else {
      status.innerHTML = data.message || `Voice not available for ${targetLang.toUpperCase()} yet`;
    }
  } catch (e) {
    status.innerHTML = `❌ Voice Generation Failed`;
  }
}

async function generateSRT() {
  const status = document.getElementById('status');
  const srtDiv = document.getElementById('srtLink');

  if (currentSegments.length === 0) {
    alert("Please transcribe first!");
    return;
  }

  status.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Generating SRT...`;

  const formData = new FormData();
  formData.append("segments", JSON.stringify(currentSegments));
  formData.append("filename", currentFileName || "baif_recording");

  try {
    const res = await fetch("/generate_srt", { method: "POST", body: formData });
    const data = await res.json();
    
    if (data.status === "success") {
      currentSrtFileName = data.srt_url.split('/').pop();
      status.innerHTML = `✅ SRT Generated!`;
      srtDiv.innerHTML = `
        <a href="${data.srt_url}" download 
           class="inline-flex items-center gap-3 bg-amber-600 text-white px-8 py-4 rounded-3xl hover:bg-amber-700">
          📥 Download SRT Subtitle File
        </a>`;
    }
  } catch (e) {
    status.innerHTML = `❌ SRT Generation Failed`;
  }
}

async function burnSubtitles() {
  const status = document.getElementById('status');
  const burnedDiv = document.getElementById('burnedVideoLink');

  if (currentSegments.length === 0) return alert("Please generate SRT first!");

  status.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i> Burning subtitles into video...`;

  const fileInput = document.getElementById('mediaFile');
  if (!fileInput.files.length) return alert("Please upload the original video again");

  const formData = new FormData();
  formData.append("original_video", fileInput.files[0]);
  formData.append("srt_filename", currentSrtFileName);

  try {
    const res = await fetch("/burn_subtitles", { method: "POST", body: formData });
    const data = await res.json();
    if (data.status === "success") {
      status.innerHTML = `✅ Subtitles Burned!`;
      burnedDiv.innerHTML = `
        <a href="${data.video_url}" download 
           class="inline-flex items-center gap-3 bg-red-600 text-white px-8 py-4 rounded-3xl hover:bg-red-700">
          📥 Download Video with Burned Subtitles
        </a>`;
    } else {
      status.innerHTML = `❌ ${data.message}`;
    }
  } catch (e) {
    status.innerHTML = `❌ Failed to burn subtitles`;
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
});
