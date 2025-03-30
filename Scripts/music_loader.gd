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
const DEFAULT_FILE_NAME = "<default>"
const DEFAULT_FILE_CHECKSUM = "000000"
const DEFAULT_SONGS = [
	{
		"name": "Electro Cabello",
		"artist": "Kevin MacLeod",
		"genre": "Disco",
		"data": {
			"file_name": DEFAULT_FILE_NAME,
			"file_checksum": DEFAULT_FILE_CHECKSUM,
			"duration": 190.82,
			"tempo_beats": [],
			"obstacles": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
			"coins": [0.5, 1.5, 2.0, 3.5],
			"default_resource_location": "res://Resources/DefaultMusic/Electro_Cabello.wav"
		}
	},
	{
		"name": "Electro Cabello2",
		"artist": "Kevin MacLeod",
		"genre": "Disco",
		"data": {
			"file_name": DEFAULT_FILE_NAME,
			"file_checksum": DEFAULT_FILE_CHECKSUM,
			"duration": 190.82,
			"tempo_beats": [],
			"obstacles": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
			"coins": [0.5, 1.5, 2.0, 3.5],
			"default_resource_location": "res://Resources/DefaultMusic/Electro_Cabello.wav"
		}
	},
	{
		"name": "Electro Cabello3",
		"artist": "Kevin MacLeod",
		"genre": "Disco",
		"data": {
			"file_name": DEFAULT_FILE_NAME,
			"file_checksum": DEFAULT_FILE_CHECKSUM,
			"duration": 190.82,
			"tempo_beats": [],
			"obstacles": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
			"coins": [0.5, 1.5, 2.0, 3.5],
			"default_resource_location": "res://Resources/DefaultMusic/Electro_Cabello.wav"
		}
	}
]

var song_library = DEFAULT_SONGS

func _ready():
	load_custom_songs()
	
	
# This method will read AppData to load any additional songs the user has processed
func load_custom_songs():
	# Read AppData
	# Modify song_library list
	pass
