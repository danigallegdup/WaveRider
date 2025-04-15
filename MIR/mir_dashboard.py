import json
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# === Configuration ===
# Change this base name to match your song's file names.
song_base = "mysong"  # For example, if your audio file is mysong.wav
report_dir = Path(__file__).parent

# Construct expected file paths for the reports
onset_report_file    = report_dir / f"{song_base}_report.json"
chroma_report_file   = report_dir / f"{song_base}_chroma_report.json"
spectral_report_file = report_dir / f"{song_base}_spectral_report.json"

# === Load JSON Data ===
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

# === Extract Data ===
# Onset Detection Data
onsets = onset_data.get("onsets", [])
duration = onset_data.get("duration_sec", 0)

# Chroma Data: average chroma vector (should be 12 values, one per pitch class)
avg_chroma = chroma_data.get("avg_chroma", [])
pitch_classes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

# Spectral Analysis Data: average Mel dB values (one per mel band)
avg_mel_db = spectral_data.get("avg_mel_db", [])
mel_band_indices = np.arange(len(avg_mel_db))

# === Create Dashboard ===
plt.figure(figsize=(12, 10))

# Subplot 1: Onset Detection Timeline
plt.subplot(3, 1, 1)
plt.title("Onset Detection Timeline")
plt.xlabel("Time (s)")
plt.ylabel("Onset Indicator")
# Plot each onset time as a marker along a horizontal line
if onsets:
    plt.plot(onsets, np.ones_like(onsets), 'o', markersize=5, label="Detected Onsets")
plt.xlim(0, duration)
plt.yticks([])  # Remove the default y-axis ticks
plt.legend()
plt.grid(True)

# Subplot 2: Chroma Analysis – Average Chroma Bar Chart
plt.subplot(3, 1, 2)
plt.title("Average Chroma (Harmonic Analysis)")
plt.xlabel("Pitch Class")
plt.ylabel("Amplitude")
if avg_chroma and len(avg_chroma) == 12:
    plt.bar(pitch_classes, avg_chroma, color='skyblue')
else:
    plt.text(0.5, 0.5, "No chroma data available", horizontalalignment='center')
plt.grid(True)

# Subplot 3: Spectral Analysis – Average Mel Spectral Energy
plt.subplot(3, 1, 3)
plt.title("Average Mel Spectral Energy (dB)")
plt.xlabel("Mel Band Index")
plt.ylabel("Average dB")
if avg_mel_db:
    plt.plot(mel_band_indices, avg_mel_db, marker='o', linestyle='-', color='magenta')
else:
    plt.text(0.5, 0.5, "No spectral energy data available", horizontalalignment='center')
plt.grid(True)

plt.tight_layout()
plt.show()
