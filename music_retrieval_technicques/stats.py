""""
pip install numpy librosa soundfile pydub matplotlib scipy

"""
import librosa
import numpy as np
import json
import matplotlib.pyplot as plt
import librosa.display
import soundfile as sf
from scipy.signal import find_peaks
from pydub import AudioSegment

def analyze_audio(file_path):
    """Extracts detailed stats from a song and generates a report."""
    
    # Load the audio file
    y, sr = librosa.load(file_path, sr=None)
    
    # Extract features
    bpm, _ = librosa.beat.beat_track(y=y, sr=sr)  # Tempo (BPM)
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)  # Harmonic content
    spectral_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)[0]  # Brightness
    spectral_rolloff = librosa.feature.spectral_rolloff(y=y, sr=sr)[0]  # High freq cutoff
    zero_crossings = np.sum(librosa.zero_crossings(y, pad=False))  # Perceptual rhythm
    rms_energy = librosa.feature.rms(y=y)  # Loudness
    pitches, magnitudes = librosa.piptrack(y=y, sr=sr)  # Pitch tracking
    
    # Detect Key & Scale
    key = np.argmax(np.mean(chroma, axis=1))  # Estimate key from chroma
    scale = "Major" if np.mean(chroma[key]) > np.mean(chroma[(key + 3) % 12]) else "Minor"

    # Amplitude peaks (to detect changes in energy)
    peaks, _ = find_peaks(rms_energy[0], height=np.mean(rms_energy) * 1.5)

    # Mel-frequency cepstral coefficients (MFCCs) for instrument classification
    mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
    mfcc_mean = np.mean(mfccs, axis=1).tolist()

    # Report generation
    report = {
        "BPM": round(float(bpm)),
        "Key": key,
        "Scale": scale,
        "Rhythm Features": {
            "Zero Crossings": int(zero_crossings),
            "Spectral Centroid (Brightness)": np.mean(spectral_centroid),
            "Spectral Rolloff (High Freq Cutoff)": np.mean(spectral_rolloff),
        },
        "Amplitude Features": {
            "RMS Energy": np.mean(rms_energy),
            "Loudest Moments (Amplitude Peaks)": len(peaks),
        },
        "Pitch Features": {
            "Dominant Pitches": [float(pitches[i].max()) for i in range(len(pitches)) if np.any(pitches[i])],
        },
        "Instrument Signature (MFCC)": mfcc_mean
    }

    # Save as JSON file
    with open("music_analysis.json", "w") as f:
        json.dump(report, f, indent=4)

    print("Music Analysis Report Saved as 'music_analysis.json' 🎵✅")
    return report

# Example usage
file_path = "./Samples/immersing-into-electro-swing-152574.mp3"  # Replace with the actual file path
report = analyze_audio(file_path)
print(json.dumps(report, indent=4))

def plot_waveform(file_path):
    """Plots the waveform of the audio file."""
    y, sr = librosa.load(file_path, sr=None)
    plt.figure(figsize=(12, 4))
    librosa.display.waveshow(y, sr=sr, alpha=0.7)
    plt.title("Waveform of the Song")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.show()

# Call function
plot_waveform("your_song.mp3")
