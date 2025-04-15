extends CenterContainer

'''
Menus

This script will be used to power menu transitions, game start, and pauses.
'''

const DEFAULT_VOLUME = 0.5

@onready var menus = {
		"main": $Main,
		"song_select": $SongSelect,
		"options": $Options,
		"pause": $Pause,
		"game_over": $GameOver,
	}
var cur_menu: Control

@onready var song_list = $SongSelect/VBoxContainer/HBoxContainer/ScrollContainer/SongList
@onready var song_list_item = preload("res://Scenes/SongListItem.tscn")
@onready var song_details_display = $SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay
@onready var volume_slider = $Options/VBoxContainer/Volume/VBoxContainer/HBoxContainer/VolumeSlider

@onready var _audio_bus = AudioServer.get_bus_index("Master")

func _ready():
	for menu in menus:
		menus[menu].hide()
	switch_menu(menus.main)
	_on_reset_volume_button_down()
	
	# Set up SongSelect menu
	MusicLoader.load_custom_songs()
	display_song_details(false)
	for s in MusicLoader.song_library:
		create_list_item(s)
	
func switch_menu(target:Control):
	if cur_menu:
		if cur_menu.name == target.name: return
	print("MENUS: Switching to: " + target.name)
	if cur_menu: cur_menu.hide()
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
	

func song_complete(score):
	switch_menu(menus.game_over)
	self.show()
	

'''
BUTTON SIGNALS

Be very concise when modifying the below functions; know exactly which buttons they are tied to
'''	

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

# Located in Main menu
func _on_play_button_down() -> void:
	switch_menu(menus.song_select)

# Located in Main menu
func _on_quit_button_down() -> void:
	get_tree().quit()

# Located in Options menu
func _on_reset_volume_button_down() -> void:
	volume_slider.value = DEFAULT_VOLUME
	_on_volume_slider_value_changed(DEFAULT_VOLUME)

# Located in Options menu	
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_audio_bus, linear_to_db(volume_slider.value))

# Located in Main menu
func _on_options_button_down() -> void:
	options_previous_menu = menus.main
	switch_menu(menus.options)

# Use to return to correct menu (pause or main)
@onready var options_previous_menu: MarginContainer = menus.main
# Located in Options menu
func _on_options_back_button_button_down() -> void:
	switch_menu(options_previous_menu)

# Located in Pause menu
func _on_pause_options_button_down() -> void:
	options_previous_menu = menus.pause
	switch_menu(menus.options)
