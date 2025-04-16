import os
import librosa
import numpy as np
import json
from pathlib import Path

# === Configuration ===
DEFAULT_MUSIC_DIR = Path("../Resources/DefaultMusic")
FRAME_LENGTH = 2048
HOP_LENGTH = 512

def process_wav_file_harmonic(file_path):
    """
    Process a WAV file to extract chroma features using harmonic-percussive source separation.
    
    The script first isolates the harmonic component of the audio using 
    librosa.effects.harmonic. Then, it calculates the chroma features from 
    that harmonic signal via librosa.feature.chroma_stft.
    
    The computed average chroma vector (across time) is a concise summary of 
    the tonal content of the music track, suitable for visual theming and dynamic 
    environmental adjustments in interactive applications.
    """
    # Load the audio file (native sampling rate)
    y, sr = librosa.load(file_path, sr=None)
    
    # Extract the harmonic component from the audio
    y_harm = librosa.effects.harmonic(y)
    
    # Compute chroma features from the harmonic component
    chroma = librosa.feature.chroma_stft(y=y_harm, sr=sr, hop_length=HOP_LENGTH)
    
    # Compute average chroma across time (produces a 12-bin vector, one bin per pitch class)
    avg_chroma = np.mean(chroma, axis=1)
    
    return avg_chroma, chroma

# === Batch Process ===
print("=== BATCH WAV ANALYSIS (Chroma and Harmonic Analysis) ===")

# Iterate through all WAV files in the default music directory
for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    # Skip any files that end with '.wav.import'
    if wav_file.name.endswith(".import"):
        continue

    try:
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
