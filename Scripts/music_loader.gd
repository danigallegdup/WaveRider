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
const MUSIC_DIR = "user://"
func load_custom_songs():
	# Process all WAV files in the music directory
	var dir = DirAccess.open(MUSIC_DIR)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
			Util.process_file(MUSIC_DIR + "/" + file_name)
		file_name = dir.get_next()
	print("=== Song data extraction completed ===")
	
func play_song(song_data):
	if Util.IS_WEB_EXPORT:
		# Check if compressed version of the song exists; switch
		var small_song = Util.locate_song(song_data).rstrip(".wav").rstrip(".mp3") + "_small.mp3"
		if ResourceLoader.exists(small_song):
			# Change resource path to compressed song
			print("Found smaller version of song! Switching...")
			song_data.data.default_resource_location = small_song
	if not main_link:
		print("ERROR: Main link was not initialized")
		return
	main_link.start_game(song_data)
