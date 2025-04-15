import json
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
import librosa
import librosa.display

# === Configuration ===
# Change this base name to match your song's file names.
song_base = "catchy-uplifting-inspiring-indie-pop-182349"  # Example: if your audio file is catchy-uplifting-inspiring-indie-pop-182349.wav
report_dir = Path(__file__).parent

# Construct expected file paths for the reports
onset_report_file    = report_dir / f"{song_base}_onset_extraction_report.json"
chroma_report_file   = report_dir / f"{song_base}_chroma_report.json"
spectral_report_file = report_dir / f"{song_base}_spectral_report.json"
beat_report_file     = report_dir / f"{song_base}beat_extraction_report.json"  # Note the underscore for consistency

# Attempt to load the JSON data from each report
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

# === Extract Data from JSON Reports ===

# Onset data
onsets = onset_data.get("onsets", [])
duration = onset_data.get("duration_sec", 0)

# Chroma data: expect a 12-value vector
avg_chroma = chroma_data.get("avg_chroma", [])
pitch_classes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

# Spectral analysis data: average Mel dB values across mel bands
avg_mel_db = spectral_data.get("avg_mel_db", [])
mel_band_indices = np.arange(len(avg_mel_db))

# Beat data: expect a list of beat times (in seconds)
beats = beat_data.get("beats", [])

# === Load the Audio File for Waveform Analysis ===
# Assuming the audio file is in ../Resources/DefaultMusic with the same base name and .wav extension
audio_path = Path(__file__).parent / "../Resources/DefaultMusic" / f"{song_base}.wav"
try:
    y, sr = librosa.load(audio_path, sr=None)
    audio_duration = librosa.get_duration(y=y, sr=sr)
    # Create a time axis for the waveform plot
    t = np.linspace(0, audio_duration, num=len(y))
except Exception as e:
    print(f"Error loading audio file: {e}")
    y, sr, t = None, None, None

# === Create Dashboard ===

# Create a figure that fills the screen; adjust size as needed
plt.figure(figsize=(16, 12))

# Add an overall title with the song name at the top (centered)
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
    plt.text(0.5, 0.5, "No audio data available", horizontalalignment='center', transform=plt.gca().transAxes)
plt.grid(True)

# Subplot 2: Onset Detection Timeline
plt.subplot(5, 1, 2)
plt.title("Onset Detection Timeline")
plt.xlabel("Time (s)")
# Plot each onset time as a marker along a horizontal line
if onsets:
    plt.plot(onsets, np.ones_like(onsets), 'o', markersize=5, label="Detected Onsets")
plt.xlim(0, duration)
plt.yticks([])  # Remove y-axis ticks for clarity
plt.legend()
plt.grid(True)

# Subplot 3: Beat Extraction Timeline
plt.subplot(5, 1, 3)
plt.title("Beat Extraction Timeline")
plt.xlabel("Time (s)")
# Plot detected beats as vertical dashed lines
if beats:
    for i, beat in enumerate(beats):
        plt.axvline(x=beat, color='green', linestyle='--', linewidth=1, label='Beat' if i==0 else "")
plt.xlim(0, duration)
plt.yticks([])  # Remove y-axis ticks for clarity
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
    plt.text(0.5, 0.5, "No chroma data available", horizontalalignment='center', transform=plt.gca().transAxes)
plt.grid(True)

# Subplot 5: Spectral Analysis – Average Mel Spectral Energy
plt.subplot(5, 1, 5)
plt.title("Average Mel Spectral Energy (dB)")
plt.xlabel("Mel Band Index")
plt.ylabel("Average dB")
if avg_mel_db:
    plt.plot(mel_band_indices, avg_mel_db, marker='o', linestyle='-', color='magenta')
else:
    plt.text(0.5, 0.5, "No spectral energy data available", horizontalalignment='center', transform=plt.gca().transAxes)
plt.grid(True)

plt.tight_layout(rect=[0, 0, 1, 0.96])  # Leave space for the suptitle

# Maximize the figure window (works with some backends)
manager = plt.get_current_fig_manager()
try:
    manager.window.showMaximized()
except AttributeError:
    # If 'showMaximized' is not available, you may adjust the figure size manually.
    pass

plt.show()
