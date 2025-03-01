from pydub import AudioSegment
import os

# Define the folder where your audio files are stored
audio_folder = "..Samples"

# List of audio file names in the order they appear
audio_files = [
    "catchy-uplifting-inspiring-indie-pop-182349.mp3",
    "disco-pop-304671.mp3",
    "flamenco-2-302761.mp3",
    "hues-of-blues-263690.mp3",
    "immersing-into-electro-swing-152574.mp3",
    "piano-waltz-elegant-and-graceful-instrumental-music-285601.mp3",
    "short-salsa-141682.mp3",
    "soulful-groove-with-deep-bass-mellow-rhodes-and-jazzy-brass-304465.mp3",
    "stomping-rock-four-shots-111444.mp3",
    "tango-bleu-piano-accordeon-basse-304649.mp3",
    "uplifting-and-energetic-indie-pop-305512.mp3"
]

# Initialize an empty AudioSegment
mashup = AudioSegment.silent(duration=0)

# Set crossfade duration (smooth transition)
crossfade_duration = 1000  # 1 second

# Loop through each file and extract 11 seconds
for file in audio_files:
    file_path = os.path.join(audio_folder, file)
    
    # Load the audio file
    audio = AudioSegment.from_file(file_path)
    
    # Extract first 11 seconds
    snippet = audio[:11000]  # 11000 milliseconds (11 sec)
    
    # Concatenate with crossfade
    if len(mashup) == 0:
        mashup = snippet  # First track (no crossfade needed)
    else:
        mashup = mashup.append(snippet, crossfade=crossfade_duration)

# Export the final mashup as an MP3 file
output_path = os.path.join(audio_folder, "final_mashup.mp3")
mashup.export(output_path, format="mp3")

print(f"Mashup successfully created: {output_path}")
