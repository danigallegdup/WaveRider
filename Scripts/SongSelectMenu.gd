extends Control

@onready var song_list = $VBoxContainer/SongList
@onready var song_item_template = preload("res://Scenes/SongListItem.tscn")
@onready var audio_player = $AudioStreamPlayer

const SONGS_DIR = "res://Resources/DefaultMusic/"
const MAIN_SCENE_PATH = "res://Scenes/Main.tscn"  # Use a constant for the scene path

func _ready():
	populate_song_list()

func populate_song_list():
	song_list.clear()  # Clear the list to avoid duplicates
	var dir = DirAccess.open(SONGS_DIR)
	if dir == null:
		print("Error: Could not open directory: ", SONGS_DIR)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".wav"):
			var item = song_item_template.instantiate()
			item.get_node("HBoxContainer/SongName").text = file_name
			item.get_node("HBoxContainer/PlayButton").connect("pressed", _on_play_button_pressed.bind(file_name))
			item.get_node("HBoxContainer/SelectButton").connect("pressed", _on_select_button_pressed.bind(file_name))
			song_list.add_child(item)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_play_button_pressed(file_name):
	var stream = load(SONGS_DIR + file_name)
	if stream and stream is AudioStream:  # Validate the loaded resource
		audio_player.stream = stream
		audio_player.play()
	else:
		print("Error: Failed to load audio stream for file: ", file_name)

func _on_select_button_pressed(file_name):
	print("User selected: ", file_name)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)  # Use the constant for the scene path
