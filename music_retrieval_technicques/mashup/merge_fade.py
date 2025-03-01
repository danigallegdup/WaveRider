from pydub import AudioSegment
import librosa
import numpy as np

def merge_tracks(track1_path, track2_path, crossfade_ms=5000):
    """Merge two tracks with a crossfade effect."""
    track1 = AudioSegment.from_file(track1_path)
    track2 = AudioSegment.from_file(track2_path)

    # Normalize volume
    track1 = track1 - track1.dBFS
    track2 = track2 - track2.dBFS

    # Apply crossfade
    mashup = track1.append(track2, crossfade=crossfade_ms)
    
    mashup.export("mashup.mp3", format="mp3")
    return "mashup.mp3"

# Example usage
merge_tracks("track1.mp3", "track2.mp3")
