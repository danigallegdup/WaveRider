import argparse
import json
import os
import shutil
from pathlib import Path

import librosa
import numpy as np


# Parse command line arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description="Extract audio features from music files")
    parser.add_argument(
        "--frame-length", type=int, default=2048, help="Frame length for audio processing (default: 2048)"
    )
    parser.add_argument("--hop-length", type=int, default=512, help="Hop length for audio processing (default: 512)")
    parser.add_argument(
        "--onset-threshold", type=float, default=0.1, help="Threshold for onset detection (default: 0.1)"
    )
    parser.add_argument(
        "--onset-spacing", type=float, default=0.1, help="Minimum spacing between onsets in seconds (default: 0.1)"
    )
    parser.add_argument(
        "--file-name", type=str, help="Input audio file", required=True
    )
    parser.add_argument("--name", type=str, help="Name of the song", required=True)
    parser.add_argument("--genre", type=str, help="Genre of the song", required=True)
    parser.add_argument("--artist", type=str, help="Artist of the song", required=True)
    return parser.parse_args()


# Get args and set configuration
args = parse_arguments()

# === Configuration ===
# Always use %appdata%/Wave Rider as output directory
APP_DATA_DIR = Path(os.path.expandvars("%appdata%")) / "Wave Rider"
OUTPUT_DIR = APP_DATA_DIR
FRAME_LENGTH = args.frame_length
HOP_LENGTH = args.hop_length
ONSET_THRESHOLD = args.onset_threshold
ONSET_SPACING = args.onset_spacing
FILE_NAME = args.file_name
SONG_NAME = args.name
SONG_GENRE = args.genre
SONG_ARTIST = args.artist

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
    onset_frames = librosa.onset.onset_detect(
        onset_envelope=onset_env,
        sr=sr,
        hop_length=HOP_LENGTH,
        backtrack=False,
        pre_max=20,
        post_max=20,
        pre_avg=100,
        post_avg=100,
        delta=ONSET_THRESHOLD,
        wait=0,
    )
    onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=HOP_LENGTH)
    return sorted(set(onset_times))


def extract_spectral(file_path):
    y, sr = librosa.load(file_path, sr=None)
    mel_spec = librosa.feature.melspectrogram(y=y, sr=sr, n_fft=FRAME_LENGTH, hop_length=HOP_LENGTH)
    mel_db = librosa.power_to_db(mel_spec, ref=np.max)
    avg_mel_db = np.mean(mel_db, axis=1)
    return avg_mel_db.tolist(), mel_db.shape


# Function to copy music file to the appdata directory if needed
def ensure_file_in_appdata(file_path):
    """
    If the file is not already in the appdata directory, copy it there.
    Returns the path to the file in the appdata directory.
    """
    # Convert to absolute path if it's not already
    file_path = Path(file_path).resolve()

    # Check if the file is already in the appdata directory
    if APP_DATA_DIR in file_path.parents or APP_DATA_DIR == file_path.parent:
        return file_path

    # Destination path in appdata
    dest_path = APP_DATA_DIR / file_path.name

    # Copy the file if it doesn't already exist in appdata
    if not dest_path.exists():
        print(f"Copying {file_path.name} to {APP_DATA_DIR}...")
        shutil.copy2(file_path, dest_path)
    else:
        print(f"{file_path.name} already exists in {APP_DATA_DIR}")

    return dest_path


# Main processing function
def main():
    print("=== started song data extraction ===")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Frame length: {FRAME_LENGTH}")
    print(f"Hop length: {HOP_LENGTH}")
    print(f"Onset threshold: {ONSET_THRESHOLD}")
    print(f"Onset spacing: {ONSET_SPACING}")
    print(f"File pattern: {FILE_NAME}")
    if SONG_NAME:
        print(f"Song name: {SONG_NAME}")
    if SONG_GENRE:
        print(f"Song genre: {SONG_GENRE}")
    if SONG_ARTIST:
        print(f"Song artist: {SONG_ARTIST}")

    print(f"Processing: {FILE_NAME}")

    try:
        # Ensure the file is in the appdata directory
        appdata_file_path = ensure_file_in_appdata(FILE_NAME)

        # Duration
        duration = librosa.get_duration(path=appdata_file_path)

        # Chroma harmonic
        avg_chroma, chroma_shape = extract_chroma_harmonic(appdata_file_path)

        # Beat extraction
        beats = extract_beats(appdata_file_path)

        # Onset extraction
        onsets = extract_onsets(appdata_file_path)

        # Spectral analysis
        avg_mel_db, mel_spec_shape = extract_spectral(appdata_file_path)

        # Consolidate data with new metadata fields
        data = {
            "filename": appdata_file_path.name,
            "duration_sec": round(duration, 3),
        }

        # Add metadata if provided
        if SONG_NAME:
            data["name"] = SONG_NAME
        if SONG_GENRE:
            data["genre"] = SONG_GENRE
        if SONG_ARTIST:
            data["artist"] = SONG_ARTIST

        # Add audio analysis data
        data.update(
            {
                "chroma_harmonic": {
                    "avg_chroma": [round(val, 3) for val in avg_chroma],
                    "chroma_shape": chroma_shape,
                },
                "beat_extraction": {"num_beats": len(beats), "beats": [round(t, 3) for t in beats]},
                "onset_extraction": {"num_onsets": len(onsets), "onsets": [round(t, 3) for t in onsets]},
                "spectral_analysis": {
                    "avg_mel_db": [round(val, 3) for val in avg_mel_db],
                    "mel_spectrogram_shape": mel_spec_shape,
                },
            }
        )

        # Write data to JSON
        out_path = OUTPUT_DIR / (appdata_file_path.stem + "_song_data.json")
        with open(out_path, "w") as f:
            json.dump(data, f, indent=2)

        print(f"✅ report saved to: {out_path}")

    except Exception as e:
        print(f"❌ Error processing {FILE_NAME}: {str(e)}")


# Run the main function if script is executed directly
if __name__ == "__main__":
    main()
