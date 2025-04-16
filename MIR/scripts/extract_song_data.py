import librosa
import numpy as np
import json
from pathlib import Path

# === Configuration ===
DEFAULT_MUSIC_DIR = Path("../../Resources/DefaultMusic")
OUTPUT_DIR = Path("../GeneratedSongData")
FRAME_LENGTH = 2048
HOP_LENGTH = 512
ONSET_THRESHOLD = 0.1
ONSET_SPACING = 0.1

# Ensure output directory exists
OUTPUT_DIR.mkdir(exist_ok=True)

# Function definitions from your provided scripts
def extract_chroma_harmonic(file_path):
    y, sr = librosa.load(file_path, sr=None)
    y_harm = librosa.effects.harmonic(y)
    chroma = librosa.feature.chroma_stft(y=y_harm, sr=sr, hop_length=HOP_LENGTH)
    avg_chroma = np.mean(chroma, axis=1)
    return avg_chroma.tolist(), chroma.shape

def extract_beats(file_path):
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

    return sorted(set(new_rms_est_onsets))

def extract_onsets(file_path):
    y, sr = librosa.load(file_path, sr=None)
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=HOP_LENGTH, aggregate=np.median)
    onset_frames = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr, hop_length=HOP_LENGTH, 
                                              backtrack=False, pre_max=20, post_max=20, pre_avg=100, 
                                              post_avg=100, delta=ONSET_THRESHOLD, wait=0)
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=HOP_LENGTH)
    return sorted(set(onset_times))

def extract_spectral(file_path):
    y, sr = librosa.load(file_path, sr=None)
    mel_spec = librosa.feature.melspectrogram(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)
    mel_db = librosa.power_to_db(mel_spec, ref=np.max)
    avg_mel_db = np.mean(mel_db, axis=1)
    return avg_mel_db.tolist(), mel_db.shape

# Main processing loop
print("=== started song data extraction ===")
for wav_file in DEFAULT_MUSIC_DIR.glob("*.wav"):
    if wav_file.name.endswith(".import"):
        continue

    print(f"Processing: {wav_file.name}")

    try:
        # Duration
        duration = librosa.get_duration(path=wav_file)

        # Chroma harmonic
        avg_chroma, chroma_shape = extract_chroma_harmonic(wav_file)

        # Beat extraction
        beats = extract_beats(wav_file)

        # Onset extraction
        onsets = extract_onsets(wav_file)

        # Spectral analysis
        avg_mel_db, mel_spec_shape = extract_spectral(wav_file)

        # Consolidate data
        data = {
            "filename": wav_file.name,
            "duration_sec": round(duration, 3),
            "chroma_harmonic": {
                "avg_chroma": [round(val, 3) for val in avg_chroma],
                "chroma_shape": chroma_shape
            },
            "beat_extraction": {
                "num_beats": len(beats),
                "beats": [round(t, 3) for t in beats]
            },
            "onset_extraction": {
                "num_onsets": len(onsets),
                "onsets": [round(t, 3) for t in onsets]
            },
            "spectral_analysis": {
                "avg_mel_db": [round(val, 3) for val in avg_mel_db],
                "mel_spectrogram_shape": mel_spec_shape
            }
        }

        # Write  data to JSON
        out_path = OUTPUT_DIR / (wav_file.stem + "_song_data.json")
        with open(out_path, "w") as f:
            json.dump(data, f, indent=2)

        print(f"✅ report saved to: {out_path}")

    except Exception as e:
        print(f"❌ Error processing {wav_file.name}: {str(e)}")
