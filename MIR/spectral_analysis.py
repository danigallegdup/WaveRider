import os
import librosa
import numpy as np
import json
from pathlib import Path

# === Configuration ===
DEFAULT_MUSIC_DIR = Path("../Resources/DefaultMusic")
FRAME_LENGTH = 2048
HOP_LENGTH = 512

def process_wav_file(file_path):
    """
    Process a WAV file to extract spectral energy features.
    
    The script computes the Mel spectrogram via librosa.feature.melspectrogram,
    then converts it to a decibel (dB) scale using librosa.power_to_db. 
    An average dB spectrum is also computed over time to summarize the energy per mel band,
    which can then be used to dynamically drive ambient visual effects.
    """
    # Load the audio file using its native sampling rate
    y, sr = librosa.load(file_path, sr=None)
    
    # Compute the Mel spectrogram (power spectrogram)
    mel_spec = librosa.feature.melspectrogram(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)
    
    # Convert the power spectrogram to decibels for better interpretability
    mel_db = librosa.power_to_db(mel_spec, ref=np.max)
    
    # Compute the average energy in dB for each mel band (averaged across time frames)
    avg_mel_db = np.mean(mel_db, axis=1)
    
    return avg_mel_db, mel_db

# === Batch Process ===
print("=== BATCH WAV ANALYSIS (Spectral Energy via Mel Spectrogram) ===")

# Iterate through each WAV file in the default music directory
for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    # Skip any file that ends with '.wav.import'
    if wav_file.name.endswith(".import"):
        continue

    try:
        print(f"Processing: {wav_file.name}")
        avg_mel_db, mel_db = process_wav_file(wav_file)
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
