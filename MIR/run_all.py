import os
import librosa
import numpy as np
import json
from pathlib import Path
from onset_extraction import process_wav_file_onset
from chroma_harmonic_extraction import process_wav_file_harmonic
from extract_beat import process_wav_file_beats
from spectral_analysis import process_wav_file_spectral

# === Configuration ===
pathname = "../Resources/DefaultMusic"
DEFAULT_MUSIC_DIR = Path(pathname)
FRAME_LENGTH = 2048
HOP_LENGTH = 512
ONSET_THRESHOLD = 0.1
ONSET_SPACING = 0.1

# === Batch Process ===
print("=== BATCH WAV ANALYSIS ===")

# Iterate through each WAV file in the default music directory
step = 0
for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    # Skip any file that ends with '.wav.import'
    if wav_file.name.endswith(".import"):
        continue

    try:
        if step<1:
            step += 1
            print("Processing spectral analysis...")
        print(f"Processing: {wav_file.name}")
        avg_mel_db, mel_db = process_wav_file_spectral(wav_file)
        duration = librosa.get_duration(path=wav_file)

        # Prepare output data for the report
        output_data = {
            "filename": wav_file.name,
            "duration_sec": round(duration, 3),
            "mel_spectrogram_shape": mel_db.shape,  # (n_mels, n_frames)
            "avg_mel_db": [round(float(val), 3) for val in avg_mel_db]
        }

        # Define the output file path for the JSON report
        out_path = Path(__file__).parent / (wav_file.stem + "_spectral_report.json")
        with open(out_path, "w") as f:
            json.dump(output_data, f, indent=2)

        print(f"✅ Report saved to: {out_path}")
    except Exception as e:
        print(f"❌ Error processing {wav_file.name}: {str(e)}")

    try:
        if step<2:
            step += 1
            print("Processing harmonic extraction...")
        print(f"Processing: {wav_file.name}")
        avg_chroma, chroma = process_wav_file_harmonic(wav_file)
        duration = librosa.get_duration(path=wav_file)

        # Prepare output data
        output_data = {
            "filename": wav_file.name,
            "duration_sec": round(duration, 3),
            "avg_chroma": [round(float(val), 3) for val in avg_chroma],
            "chroma_shape": chroma.shape  # Provides (n_chroma, n_frames)
        }

        # Define output report file path
        out_path = Path(__file__).parent / (wav_file.stem + "_chroma_report.json")
        with open(out_path, "w") as f:
            json.dump(output_data, f, indent=2)

        print(f"✅ Report saved to: {out_path}")
    except Exception as e:
        print(f"❌ Error processing {wav_file.name}: {str(e)}")

    try:
        if step<3:
            step += 1
            print("Processing onset extraction...")
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

    try:
        if step<4:
            step += 1
            print("Processing beats extraction...")
        print(f"Processing: {wav_file.name}")
        onsets = process_wav_file_beats(wav_file)
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

