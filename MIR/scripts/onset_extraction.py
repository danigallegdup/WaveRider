import os
import librosa
import numpy as np
import json
from pathlib import Path

# === Configuration ===
DEFAULT_MUSIC_DIR = Path("../Resources/DefaultMusic")
FRAME_LENGTH = 2048
HOP_LENGTH = 512
# You may adjust these thresholds as needed for your audio material:
ONSET_THRESHOLD = 0.1  # Can be tuned for sensitivity of the onset detection

def process_wav_file_onset(file_path):
    """
    Process a WAV file to extract onset timings using Librosa's onset detection.
    
    This implementation employs:
      - librosa.onset.onset_strength: Computes an onset envelope indicating sudden energy increases.
      - librosa.onset.onset_detect: Identifies frame indices corresponding to percussive events.
    
    The resulting onset times are then used to simulate game events (e.g., obstacle spawns).
    """
    # Load the audio file (using the file's native sampling rate)
    y, sr = librosa.load(file_path, sr=None)

    # Compute the onset strength envelope
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=HOP_LENGTH, aggregate=np.median)
    
    # Perform onset detection: this returns frame indices where onsets occur.
    onset_frames = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, hop_length=HOP_LENGTH, backtrack=False, pre_max=20, post_max=20, pre_avg=100, post_avg=100, delta=ONSET_THRESHOLD, wait=0)
    
    # Convert frame indices to time values (in seconds)
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=HOP_LENGTH)
    
    # Return unique onset times
    return np.unique(onset_times)

# === Batch Process ===
print("=== BATCH WAV ANALYSIS (Onset Detection) ===")

# Iterate through each WAV file in the specified directory
for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    # Skip any '.wav.import' files if present
    if wav_file.name.endswith(".import"):
        continue

    try:
        print(f"Processing: {wav_file.name}")
        onsets = process_wav_file_onset(wav_file)
        duration = librosa.get_duration(path=wav_file)

        # Prepare output data with onset detection details
        output_data = {
            "filename": wav_file.name,
            "duration_sec": round(duration, 3),
            "num_onsets": int(len(onsets)),
            "onsets": [round(t, 3) for t in onsets]
        }
        
        # Create output file in the same directory as this script with a unique report name.
        out_path = Path(__file__).parent / (wav_file.stem + "_onset_extraction_report.json")
        with open(out_path, "w") as f:
            json.dump(output_data, f, indent=2)

        print(f"✅ Report saved to: {out_path}")
    except Exception as e:
        print(f"❌ Error processing {wav_file.name}: {str(e)}")
