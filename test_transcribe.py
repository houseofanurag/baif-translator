import mlx_whisper
import time

print("Loading tiny model and testing transcription...")

start = time.time()

# Using tiny model (lightest, best for 8GB RAM)
result = mlx_whisper.transcribe(
    "test_audio.mp3",           # we'll create a dummy one
    path_or_hf_repo="mlx-community/whisper-tiny", 
    verbose=True
)

print("\n✅ Transcription completed in", round(time.time()-start, 2), "seconds")
print("Text:", result["text"])
