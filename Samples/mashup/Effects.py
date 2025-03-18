from pydub import AudioSegment
import librosa
import numpy as np


def add_effects(audio_path, effect_type="reverb"):
    """Apply audio effects like reverb, echo, or stutter."""
    audio = AudioSegment.from_file(audio_path)

    if effect_type == "reverb":
        audio = audio.low_pass_filter(3000).overlay(audio - 10)
    elif effect_type == "echo":
        echo = audio - 20
        echo = echo.overlay(audio, position=200)
        audio = audio.overlay(echo)
    elif effect_type == "stutter":
        chunk = audio[:300]  # Take first 300ms
        stutter = chunk * 3  # Repeat it 3 times
        audio = stutter + audio

    audio.export("effect_applied.mp3", format="mp3")
    return "effect_applied.mp3"

# Example usage
add_effects("mashup.mp3", "stutter")
