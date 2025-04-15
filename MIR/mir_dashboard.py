import json
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
import librosa
import librosa.display

# === Configuration ===
song_base = "catchy-uplifting-inspiring-indie-pop-182349"  # Change to match your file naming
report_dir = Path(__file__).parent

# Construct file paths for reports
onset_report_file    = report_dir / f"{song_base}_onset_extraction_report.json"
chroma_report_file   = report_dir / f"{song_base}_chroma_report.json"
spectral_report_file = report_dir / f"{song_base}_spectral_report.json"
beat_report_file     = report_dir / f"{song_base}_beat_extraction_report.json"

# Load the JSON data for each report
try:
    with open(onset_report_file, "r") as f:
        onset_data = json.load(f)
except Exception as e:
    print(f"Error loading onset data: {e}")
    onset_data = {}

try:
    with open(chroma_report_file, "r") as f:
        chroma_data = json.load(f)
except Exception as e:
    print(f"Error loading chroma data: {e}")
    chroma_data = {}

try:
    with open(spectral_report_file, "r") as f:
        spectral_data = json.load(f)
except Exception as e:
    print(f"Error loading spectral data: {e}")
    spectral_data = {}

try:
    with open(beat_report_file, "r") as f:
        beat_data = json.load(f)
except Exception as e:
    print(f"Error loading beat data: {e}")
    beat_data = {}

# === Extract Data from Reports ===
onsets = onset_data.get("onsets", [])
duration = onset_data.get("duration_sec", 0)

avg_chroma = chroma_data.get("avg_chroma", [])
pitch_classes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

avg_mel_db = spectral_data.get("avg_mel_db", [])
mel_band_indices = np.arange(len(avg_mel_db))

# Beat times (in seconds)
beats = beat_data.get("beats", [])
print("Onsets (from onset_data):", onsets)
print("Beats (from beat_data):", beats)


# === Load the Audio for Waveform Analysis ===
audio_path = Path(__file__).parent / "../Resources/DefaultMusic" / f"{song_base}.wav"
try:
    y, sr = librosa.load(audio_path, sr=None)
    audio_duration = librosa.get_duration(y=y, sr=sr)
    t = np.linspace(0, audio_duration, num=len(y))
except Exception as e:
    print(f"Error loading audio file: {e}")
    y, sr, t = None, None, None

# === Create Dashboard ===
plt.figure(figsize=(16, 12))
plt.suptitle(song_base, fontsize=20, y=0.98)

# Subplot 1: Waveform Analysis
plt.subplot(5, 1, 1)
plt.title("Waveform Analysis")
plt.xlabel("Time (s)")
plt.ylabel("Amplitude")
if y is not None and t is not None:
    plt.plot(t, y, color='C0')
    plt.xlim(0, audio_duration)
else:
    plt.text(0.5, 0.5, "No audio data available",
             horizontalalignment='center',
             transform=plt.gca().transAxes)
plt.grid(True)

# Subplot 2: Onset Detection Timeline
plt.subplot(5, 1, 2)
plt.title("Onset Detection Timeline")
plt.xlabel("Time (s)")
if onsets:
    plt.plot(onsets, np.ones_like(onsets), 'o', markersize=5,
             label="Detected Onsets")
plt.xlim(0, duration)
plt.yticks([])  # Remove y-axis ticks for clarity
plt.legend()
plt.grid(True)

# Subplot 3: Beat Extraction Timeline (Modified Visualization)
plt.subplot(5, 1, 3)
plt.title("Beat Extraction Timeline")
plt.xlabel("Time (s)")
if beats and duration > 0:
    # Calculate BPM from beat count and duration
    bpm = len(beats) / duration * 60
    # Plot beats as scatter markers along y=1
    plt.scatter(beats, np.full_like(beats, 1), color='green', s=100,
                label="Beat")
    # Add a dashed horizontal baseline for clarity
    plt.hlines(1, 0, duration, colors='grey', linestyles='--', linewidth=1)
    # Annotate BPM on the plot
    plt.text(duration * 0.65, 1.15, f"BPM: {bpm:.1f}",
             fontsize=12, color='red', weight='bold')
plt.xlim(0, duration)
plt.ylim(0.8, 1.3)
plt.yticks([])  # Clean up y-axis
if beats:
    plt.legend()
plt.grid(True)

# Subplot 4: Chroma Analysis – Average Chroma Bar Chart
plt.subplot(5, 1, 4)
plt.title("Average Chroma (Harmonic Analysis)")
plt.xlabel("Pitch Class")
plt.ylabel("Amplitude")
if avg_chroma and len(avg_chroma) == 12:
    plt.bar(pitch_classes, avg_chroma, color='skyblue')
else:
    plt.text(0.5, 0.5, "No chroma data available",
             horizontalalignment='center',
             transform=plt.gca().transAxes)
plt.grid(True)

# Subplot 5: Spectral Analysis – Average Mel Spectral Energy
plt.subplot(5, 1, 5)
plt.title("Average Mel Spectral Energy (dB)")
plt.xlabel("Mel Band Index")
plt.ylabel("Average dB")
if avg_mel_db:
    plt.plot(mel_band_indices, avg_mel_db, marker='o', linestyle='-',
             color='magenta')
else:
    plt.text(0.5, 0.5, "No spectral energy data available",
             horizontalalignment='center',
             transform=plt.gca().transAxes)
plt.grid(True)

plt.tight_layout(rect=[0, 0, 1, 0.96])
manager = plt.get_current_fig_manager()
try:
    manager.window.showMaximized()
except AttributeError:
    pass

plt.show()
