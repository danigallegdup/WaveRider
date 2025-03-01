from pydub import AudioSegment
import librosa
import numpy as np

def change_tempo(audio_path, target_bpm):
    """Adjusts the tempo of a track to match the target BPM."""
    y, sr = librosa.load(audio_path, sr=None)
    original_bpm, _ = librosa.beat.beat_track(y=y, sr=sr)
    speed_factor = target_bpm / original_bpm

    y_fast = librosa.effects.time_stretch(y, speed_factor)
    librosa.output.write_wav("tempo_adjusted.wav", y_fast, sr)

    return "tempo_adjusted.wav"

def change_key(audio_path, target_key):
    """Shifts the key of a track to match the target key."""
    y, sr = librosa.load(audio_path, sr=None)
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)
    current_key = np.argmax(np.mean(chroma, axis=1))

    shift_steps = target_key - current_key
    y_shifted = librosa.effects.pitch_shift(y, sr, n_steps=shift_steps)
    
    librosa.output.write_wav("key_adjusted.wav", y_shifted, sr)
    return "key_adjusted.wav"
