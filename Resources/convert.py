from pydub import AudioSegment
import os

def convert_all_mp3s_in_folder(folder_path):
    if not os.path.exists(folder_path):
        print(f"❌ Folder does not exist: {folder_path}")
        return

    for filename in os.listdir(folder_path):
        if filename.lower().endswith(".mp3"):
            mp3_path = os.path.join(folder_path, filename)
            wav_path = os.path.splitext(mp3_path)[0] + ".wav"

            print(f"🎵 Converting: {filename}")
            try:
                audio = AudioSegment.from_mp3(mp3_path)
                audio.export(wav_path, format="wav")
                print(f"✅ Saved: {os.path.basename(wav_path)}")
            except Exception as e:
                print(f"⚠️ Error converting {filename}: {e}")

if __name__ == "__main__":
    samples_folder = "../Samples"
    convert_all_mp3s_in_folder(samples_folder)
