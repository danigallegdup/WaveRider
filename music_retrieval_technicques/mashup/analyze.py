from pydub import AudioSegment
import librosa
import numpy as np

def load_audio(file_path):
    """Load an audio file and return an AudioSegment object."""
    return AudioSegment.from_file(file_path)

def analyze_audio(file_path):
    """Detect BPM and key of a track using Librosa."""
    y, sr = librosa.load(file_path, sr=None)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)
    key_estimate = np.argmax(np.mean(chroma, axis=1))  # Estimate key

    return {"BPM": round(tempo), "Key": key_estimate}

# Example usage
file_path = "../Samples/catchy-uplifting-inspiring-indie-pop-182349.mp3"  # Change to your file
track_info = analyze_audio(file_path)
print(track_info)
