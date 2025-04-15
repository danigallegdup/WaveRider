import os
import librosa
import numpy as np
import json
from pathlib import Path

# === Configuration ===
DEFAULT_MUSIC_DIR = Path("../Resources/DefaultMusic")
FRAME_LENGTH = 2048
HOP_LENGTH = 512
ONSET_THRESHOLD = 0.1
ONSET_SPACING = 0.1

def process_wav_file(file_path):
    y, sr = librosa.load(file_path, sr=None)

    rms_envelope = librosa.feature.rms(y=y, frame_length=FRAME_LENGTH, hop_length=HOP_LENGTH)[0]
    nrms_envelope = librosa.util.normalize(np.diff(rms_envelope))
    times = librosa.times_like(nrms_envelope, sr=sr, hop_length=HOP_LENGTH)

    rms_est_onsets = [times[i] for i, r in enumerate(nrms_envelope) if r > ONSET_THRESHOLD]

    new_rms_est_onsets = []
    i = 0
    while i < len(rms_est_onsets):
        current = rms_est_onsets[i]
        new_rms_est_onsets.append(current)
        k = i + 1
        while k < len(rms_est_onsets) and rms_est_onsets[k] - current < ONSET_SPACING:
            k += 1
        i = k

    return np.unique(new_rms_est_onsets)

# === Batch Process ===
print("=== BATCH WAV ANALYSIS ===")

for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    # Skip any .wav.import files just in case
    if wav_file.name.endswith(".import"):
        continue

    try:
        print(f"Processing: {wav_file.name}")
        onsets = process_wav_file(wav_file)
        duration = librosa.get_duration(path=wav_file)

        output_data = {
            "filename": wav_file.name,
            "duration_sec": round(duration, 3),
            "num_onsets": len(onsets),
            "beats": [round(t, 3) for t in onsets]
        }
        out_path = Path(__file__).parent / (wav_file.stem + "_beat_extraction_report.json")

        with open(out_path, "w") as f:
            json.dump(output_data, f, indent=2)

        print(f"✅ Report saved to: {out_path}")

    except Exception as e:
        print(f"❌ Error processing {wav_file.name}: {str(e)}")
