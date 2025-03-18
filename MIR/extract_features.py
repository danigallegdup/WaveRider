"""
python extract_features.py path/to/audio/file.mp3 path/to/output/

How It Works
Extracts music features using Librosa:

Tempo & Beat Tracking → Controls game speed and obstacle frequency.
Onset Detection → Determines obstacle placement.
Chord Progression → Provides harmony-based environment adaptation.
Spectrogram Analysis → Aids in background visuals.
Saves features in JSON format, making it easy to use in Wave Rider.

"""

import librosa
import librosa.display
import numpy as np
import json
import os

def extract_tempo_and_beats(audio_file):
    y, sr = librosa.load(audio_file, sr=None)
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)
    return tempo, beat_times.tolist()

def detect_onsets(audio_file):
    y, sr = librosa.load(audio_file, sr=None)
    onset_frames = librosa.onset.onset_detect(y=y, sr=sr)
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)
    return onset_times.tolist()

def get_chord_progression(audio_file):
    y, sr = librosa.load(audio_file, sr=None)
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    chord_changes = np.argmax(chroma, axis=0)
    return chord_changes.tolist()

def compute_spectrogram(audio_file):
    y, sr = librosa.load(audio_file, sr=None)
    spectrogram = np.abs(librosa.stft(y))
    spectral_centroid = librosa.feature.spectral_centroid(S=spectrogram, sr=sr)
    return spectral_centroid.mean(axis=1).tolist()

def save_features_to_json(audio_file, output_path):
    features = {}
    
    print(f"Processing: {audio_file}")
    try:
        features['tempo'], features['beats'] = extract_tempo_and_beats(audio_file)
        features['onsets'] = detect_onsets(audio_file)
        features['chord_progression'] = get_chord_progression(audio_file)
        features['spectral_data'] = compute_spectrogram(audio_file)
    except Exception as e:
        print(f"Error processing {audio_file}: {e}")
        return
    
    filename = os.path.splitext(os.path.basename(audio_file))[0] + ".json"
    output_file = os.path.join(output_path, filename)
    
    with open(output_file, 'w') as f:
        json.dump(features, f, indent=4)
    
    print(f"Features saved to {output_file}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Extract MIR features from audio files.")
    parser.add_argument("audio_file", type=str, help="Path to the input audio file.")
    parser.add_argument("output_path", type=str, help="Path to save the extracted features JSON.")
    args = parser.parse_args()
    
    save_features_to_json(args.audio_file, args.output_path)
