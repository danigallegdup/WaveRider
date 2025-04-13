extends CenterContainer

'''
Menus

This script will be used to power menu transitions, game start, and pauses.
'''

@onready var menus = {
		"main": $Main,
		"song_select": $SongSelect,
		"options": $Options,
		"pause": $Pause,
		"game_over": $GameOver,
	}
@onready var cur_menu: Control = menus.main

@onready var song_list = $SongSelect/VBoxContainer/HBoxContainer/ScrollContainer/SongList
@onready var song_list_item = preload("res://Scenes/SongListItem.tscn")
@onready var song_details_display = $SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay

func _ready():
	switch_menu(menus.main)
	#switch_menu(menus.song_select)
	self.hide()
	# Set up SongSelect menu
	MusicLoader.load_custom_songs()
	display_song_details(false)
	for s in MusicLoader.song_library:
		create_list_item(s)
	
func switch_menu(target:Control):
	if cur_menu.name == target.name: return
	print("MENUS: Switching to: " + target.name)
	cur_menu.hide()
	target.show()
	cur_menu = target
	
func toggle_pause():
	switch_menu(menus.pause)
	if self.visible:
		# Do unpause
		self.hide()
		TimescaleUtil.toggle_pause()
	else:
		# Do pause
		self.show()
		TimescaleUtil.toggle_pause()

func create_list_item(song_data):
	var l = song_list_item.instantiate()
	l.find_child("SongName").text = song_data.name
	l.find_child("Artist").text = song_data.artist
	l.find_child("Duration").text = Util.sec_to_minutes(song_data.data.duration)
	l.find_child("Genre").text = song_data.genre
	l.find_child("Button").connect("button_down", _on_song_list_item_button_down.bind(song_data.name))
	song_list.add_child(l)

func display_song_details(song_data):
	if song_data:
		song_details_display.show()
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/SongName.text = song_data.name
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer2/Artist.text = song_data.artist
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer2/Genre.text = song_data.genre
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer/Duration.text = Util.sec_to_minutes(song_data.data.duration)
		#$SongSelect/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer/BPM.text = song_data.bpm  # Currently not saving BPM as data
		# We can display additional information here
	else:
		song_details_display.hide()
	
	
	
	
# Located in Pause menu
func _on_continue_button_down() -> void:
	toggle_pause()

# Located in SongSelect menu
func _on_song_list_item_button_down(song_name):
	for song in MusicLoader.song_library:
		if song.name == song_name:
			display_song_details(song)
			return
	print("ERROR: Could not find song '" + song_name + "' in song library")

# Located in SongSelect menu
func _on_demo_button_button_down() -> void:
	# TODO Play a small portion (5 seconds?) of the selected song
	pass # Replace with function body.


# Located in SongSelect menu
func _on_play_song_button_down() -> void:
	var current_selected = $SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/SongName.text
	for song in MusicLoader.song_library:
		if song.name == current_selected:
			MusicLoader.play_song(song)  # This is where we begin playing selected song
			return
	print("ERROR: Could not find song '" + current_selected + "' in song library")


func _on_back_button_button_down() -> void:
	switch_menu(menus.main)
