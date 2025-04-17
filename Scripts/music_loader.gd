extends Node
'''
AUTOLOAD: MusicLoader

This script is an autoload, meaning it can be accessed from any other script at will.

The methods in this script will load song data for song selection menu to present, and will load
the selected song into the game scene.

Song data will have the following layout:
	{
		"name": "Display Name of Song",
		"artist": "Display Name of Artist",
		"genre": "Genre",
		"data": {
			"file_name": "my_song_file.wav",
			"file_checksum": "abc123...xyz",
			"duration": 192.0,
			"tempo_beats": [0.0, 0.1, 0.2],
			"obstacles": [0.5, 0.9, 1.2],
			"coins": [0.2, 0.4, 0.6, 0.8]
		}
	}
'''

var song_library = []
var main_link: Node3D

# Mapping chroma values to emotions or genres
var genre_mapping = {
	"rock": {"hue_shift": 0.1, "saturation_range": [0.6, 1.0], "brightness_range": [0.7, 1.0]},
	"disco": {"hue_shift": 0.1, "saturation_range": [0.6, 1.0], "brightness_range": [0.7, 1.0]},
	"pop": {"hue_shift": 0.5, "saturation_range": [0.3, 0.6], "brightness_range": [0.4, 0.8]},
	"classical": {"hue_shift": 0.8, "saturation_range": [0.2, 0.5], "brightness_range": [0.2, 0.5]},
	"neutral": {"hue_shift": 0.4, "saturation_range": [0.4, 0.7], "brightness_range": [0.5, 0.7]}
}

# Function to calculate average chroma intensity (can be modified for better genre mapping)
func calculate_average_chroma(chroma_array: Array) -> float:
	var total = 0.0
	for value in chroma_array:
		total += value
	return total / chroma_array.size()

func get_colour_palette(chroma_array, genre):
	var avg_chroma = calculate_average_chroma(chroma_array)
	var genre_settings = genre_mapping.get(genre.to_lower(), genre_mapping["neutral"])
	
	var hue_shift = genre_settings["hue_shift"]
	var saturation_min = genre_settings["saturation_range"][0]
	var saturation_max = genre_settings["saturation_range"][1]
	var brightness_min = genre_settings["brightness_range"][0]
	var brightness_max = genre_settings["brightness_range"][1]

	# Normalize chroma values to fit the saturation and brightness range
	var colour_palette = []
	for i in chroma_array.size():
		var normalized_chroma = (chroma_array[i] - chroma_array.min()) / (chroma_array.max() - chroma_array.min())
		
		var hue = fmod(i * 0.083 + hue_shift, 1.0)  # Spread hues with added genre-based shift
		var saturation = lerp(saturation_min, saturation_max, normalized_chroma)
		var brightness = lerp(brightness_min, brightness_max, normalized_chroma)
		
		colour_palette.append(Color.from_hsv(hue, saturation, brightness))
	return colour_palette

func _ready():
	#load_custom_songs()
	
	const local_directory_path = "res://MIR/GeneratedSongData"
	var dir = DirAccess.open(local_directory_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = local_directory_path + "/" + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			
			if file:
				var json_string = file.get_as_text()
				file.close()
				var result = JSON.parse_string(json_string)

				if result != null:
					song_library.append({
						"name": result["name"],
						"type": "local",
						"artist": result["artist"],
						"genre": result["genre"],
						"data": {
							"file_checksum": 000000,
							"duration": result["duration_sec"],
							"tempo_beats": result["beat_extraction"]["beats"],
							"obstacles": result["onset_extraction"]["onsets"],
							"coins": result["beat_extraction"]["beats"],
							"colours": get_colour_palette(result["chroma_harmonic"]["avg_chroma"], result["genre"]),
							"url_ref": "https://pixabay.com/music/indie-pop-catchy-uplifting-inspiring-indie-pop-182349/",
							"default_resource_location": "res://Resources/DefaultMusic/" + result["filename"]
						}
					})
				else:
					print("Failed to parse JSON from:", file_path)
					
				print("added ", file_name)
		file_name = dir.get_next()
	
	
	const user_directory_path = "user://"
	dir = DirAccess.open(user_directory_path)
	dir.list_dir_begin()
	file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = user_directory_path + "/" + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			
			if file:
				var json_string = file.get_as_text()
				file.close()
				var result = JSON.parse_string(json_string)

				if result != null:
					song_library.append({
						"name": result["name"],
						"type": "user",
						"artist": result["artist"],
						"genre": result["genre"],
						"data": {
							"file_checksum": 000000,
							"duration": result["duration_sec"],
							"tempo_beats": result["beat_extraction"]["beats"],
							"obstacles": result["onset_extraction"]["onsets"],
							"coins": result["beat_extraction"]["beats"],
							"colours": get_colour_palette(result["chroma_harmonic"]["avg_chroma"], result["genre"]),
							"url_ref": "https://pixabay.com/music/indie-pop-catchy-uplifting-inspiring-indie-pop-182349/",
							"default_resource_location": "user://" + result["filename"]
						}
					})
				else:
					print("Failed to parse JSON from:", file_path)
					
				print("added ", file_name)
		file_name = dir.get_next()
	
	
# This method will read AppData to load any additional songs the user has processed
func load_custom_songs():
	# Process all WAV files in the music directory
	var dir = DirAccess.open(MUSIC_DIR)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
			process_file(MUSIC_DIR + "/" + file_name)
		file_name = dir.get_next()
	print("=== Song data extraction completed ===")
	
func play_song(song_data):
	if not main_link:
		print("ERROR: Main link was not initialized")
		return
	main_link.start_game(song_data)









# Configuration constants
const FRAME_LENGTH = 2048
const HOP_LENGTH = 512
const ONSET_THRESHOLD = 0.1
const ONSET_SPACING = 0.1
const MUSIC_DIR = "user://"
const OUTPUT_DIR = "user://"

func process_file(wav_path: String) -> void:
	print("Processing: " + wav_path.get_file())
	
	# Load audio stream
	var song_file = FileAccess.open(wav_path, FileAccess.READ)
	var mp3_data = song_file.get_buffer(song_file.get_length())
	song_file.close()
	var stream = AudioStreamWAV.new()
	stream.data = mp3_data

	if not stream:
		print("❌ Error loading " + wav_path.get_file())
		return
	
	var sr = stream.get_mix_rate()
	var duration = stream.get_length()
	var samples = get_samples(stream)
	
	# Extract features
	var rms = compute_rms(samples)
	var onsets = detect_onsets(rms, sr)
	var spectrogram = compute_spectrogram(samples)
	var avg_spec = compute_avg_spectrogram(spectrogram)
	var chroma = compute_chroma(spectrogram, sr)
	
	# Consolidate data into dictionary
	var data = {
		"filename": wav_path.get_file(),
		"duration_sec": round(duration * 1000) / 1000.0,
		"chroma_harmonic": {
			"avg_chroma": chroma.map(func(val): return round(val * 1000) / 1000.0),
			"chroma_shape": [12, len(spectrogram)]
		},
		"beat_extraction": {
			"num_beats": len(onsets),
			"beats": onsets.map(func(t): return round(t * 1000) / 1000.0)
		},
		"onset_extraction": {
			"num_onsets": len(onsets),
			"onsets": onsets.map(func(t): return round(t * 1000) / 1000.0)
		},
		"spectral_analysis": {
			"avg_mel_db": avg_spec.map(func(val): return round(val * 1000) / 1000.0),
			"mel_spectrogram_shape": [len(avg_spec), len(spectrogram)]
		}
	}
	
	# Save to JSON
	var json_path = OUTPUT_DIR + "/" + wav_path.get_basename().get_file() + "_song_data.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file != null:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
		print("✅ Report saved to: " + json_path)
	else:
		print("❌ Error saving " + json_path)

func get_samples(stream: AudioStreamWAV) -> Array:
	# Convert PoolByteArray to float array (assuming 16-bit mono WAV)
	var data = stream.get_data()
	var samples = []
	for i in range(0, data.size() - 1, 2):
		var sample = data[i] | (data[i + 1] << 8)
		if sample >= 32768:
			sample -= 65536
		samples.append(sample / 32768.0)
	return samples

func compute_rms(samples: Array) -> Array:
	# Compute RMS envelope over frames
	var rms = []
	for i in range(0, len(samples) - FRAME_LENGTH + 1, HOP_LENGTH):
		var frame = samples.slice(i, i + FRAME_LENGTH)
		var sum_sq = 0.0
		for s in frame:
			sum_sq += s * s
		rms.append(sqrt(sum_sq / FRAME_LENGTH))
	return rms

func detect_onsets(rms: Array, sr: float) -> Array:
	# Compute normalized RMS difference and detect onsets
	var nrms = []
	for i in range(1, len(rms)):
		nrms.append(rms[i] - rms[i - 1])
	
	if nrms.is_empty():
		return []
	
	# Normalize
	var max_nrms = nrms.max()
	var min_nrms = nrms.min()
	var range_nrms = max_nrms - min_nrms
	if range_nrms > 0:
		for i in range(len(nrms)):
			nrms[i] = (nrms[i] - min_nrms) / range_nrms
	
	# Detect onsets with spacing
	var onset_times = []
	var times = []
	for i in range(len(nrms)):
		times.append(i * HOP_LENGTH / sr)
	
	var last_onset = -ONSET_SPACING - 1
	for i in range(len(nrms)):
		if nrms[i] > ONSET_THRESHOLD and (times[i] - last_onset) >= ONSET_SPACING:
			onset_times.append(times[i])
			last_onset = times[i]
	
	return onset_times

func compute_spectrogram(samples: Array) -> Array:
	# Placeholder FFT-based spectrogram (requires external FFT implementation)
	var spectrogram = []
	for i in range(0, len(samples) - FRAME_LENGTH + 1, HOP_LENGTH):
		var frame = samples.slice(i, i + FRAME_LENGTH)
		var fft_result = fft(frame)  # Assume fft() returns complex array
		var magnitudes = []
		for c in fft_result:
			magnitudes.append(sqrt(c.real * c.real + c.imag * c.imag))
		spectrogram.append(magnitudes.slice(0, FRAME_LENGTH / 2 + 1))
	return spectrogram

func compute_avg_spectrogram(spectrogram: Array) -> Array:
	# Compute average spectrogram across time
	if spectrogram.is_empty():
		return []
	var num_bins = len(spectrogram[0])
	var avg_spec = []
	for bin in range(num_bins):
		var sum = 0.0
		for frame in spectrogram:
			sum += frame[bin]
		avg_spec.append(sum / len(spectrogram))
	return avg_spec

func compute_chroma(spectrogram: Array, sr: float) -> Array:
	# Crude chroma approximation by mapping frequencies to pitch classes
	if spectrogram.is_empty():
		return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var chroma = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var frame_count = len(spectrogram)
	for frame in spectrogram:
		for k in range(len(frame)):
			var freq = k * sr / FRAME_LENGTH
			if freq > 0:
				var note = 69 + 12 * log2(freq / 440.0)
				var pc = int(round(note)) % 12
				chroma[pc] += frame[k]
	# Average over frames
	for i in range(12):
		chroma[i] /= frame_count
	return chroma

# Complex number class for FFT
class Complex:
	var real: float
	var imag: float

	func _init(r: float = 0.0, i: float = 0.0):
		real = r
		imag = i

	func mul(other: Complex) -> Complex:
		return Complex.new(
			real * other.real - imag * other.imag,
			real * other.imag + imag * other.real
		)

	func add(other: Complex) -> Complex:
		return Complex.new(real + other.real, imag + other.imag)

	func sub(other: Complex) -> Complex:
		return Complex.new(real - other.real, imag - other.imag)

	static func exp(theta: float) -> Complex:
		return Complex.new(cos(theta), sin(theta))

# FFT function
func fft(frame: Array) -> Array:
	var N = frame.size()
	if N <= 1:
		return [Complex.new(frame[0], 0.0)] if N == 1 else []

	var even = []
	var odd = []
	for i in range(0, N, 2):
		even.append(frame[i])
		odd.append(frame[i + 1])

	var even_fft = fft(even)
	var odd_fft = fft(odd)

	var result = []
	for k in range(N):
		result.append(Complex.new(0.0, 0.0))

	for k in range(N / 2):
		var twiddle = Complex.exp(-2.0 * PI * k / N)
		var t = odd_fft[k].mul(twiddle)
		result[k] = even_fft[k].add(t)
		result[k + N / 2] = even_fft[k].sub(t)

	return result

const PI = 3.141592653589793

func log2(x: float) -> float:
	# GDScript doesn't have log2, so use ln(x) / ln(2)
	return log(x) / log(2)
