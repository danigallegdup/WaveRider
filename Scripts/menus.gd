extends CenterContainer

'''
Menus

This script will be used to power menu transitions, game start, and pauses.
'''

const DEFAULT_VOLUME = 0.5
const DEMO_START_TIME = 10  # Seconds
const DEMO_DURATION = 5

@onready var menus = {
		"main": $Main,
		"song_select": $SongSelect,
		"options": $Options,
		"pause": $Pause,
		"game_won": $GameWon,
		"game_over": $GameOver
	}
var cur_menu: Control

@onready var score_label: Label = $GameOver/VBoxContainer/MarginContainer4/Label
@onready var leaderboard: VBoxContainer = $GameWon/VBoxContainer/MarginContainer/Leaderboard

@onready var song_list = $SongSelect/VBoxContainer/HBoxContainer/ScrollContainer/SongList
@onready var song_list_item = preload("res://Scenes/SongListItem.tscn")
@onready var song_details_display = $SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay
@onready var volume_slider = $Options/VBoxContainer/Volume/VBoxContainer/HBoxContainer/VolumeSlider

@onready var _audio_bus = AudioServer.get_bus_index("Master")

@onready var demo_audio_player = $DemoStreamPlayer
var demo_audio: AudioStream

var quit_song_func: Callable

var BlurShader:MeshInstance3D

func _ready():
	for menu in menus:
		menus[menu].hide()
	switch_menu(menus.main)
	_on_reset_volume_button_down()
	
	if Util.IS_WEB_EXPORT: $Main/VBoxContainer/MarginContainer/VBoxContainer2/VBoxContainer/Quit.hide()
	
	# Set up SongSelect menu
	display_song_details(false)
	for s in MusicLoader.song_library:
		create_list_item(s)
	
func switch_menu(target:Control):
	if cur_menu:
		if cur_menu.name == target.name: return
	print("MENUS: Switching to: " + target.name)
	demo_audio_player.stop()
	if cur_menu: cur_menu.hide()
	target.show()
	cur_menu = target
	
func toggle_pause():
	switch_menu(menus.pause)
	if self.visible:
		# Do unpause
		BlurShader.hide()
		self.hide()
		TimescaleUtil.toggle_pause()
	else:
		# Do pause
		BlurShader.show()
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
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/Genre.text = song_data.genre
		$SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer/Duration.text = Util.sec_to_minutes(song_data.data.duration)
		#$SongSelect/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/HBoxContainer/BPM.text = song_data.bpm  # Currently not saving BPM as data
		# We can display additional information here
	else:
		song_details_display.hide()
		
		
'''
BUTTON SIGNALS

Be very concise when modifying the below functions; know exactly which buttons they are tied to
'''	

# Located in Pause menu
func _on_continue_button_down() -> void:
	toggle_pause()

var current_tween: Tween = null
func fade_out_audio(audio_player: AudioStreamPlayer, duration: float = 1.0):
	if current_tween:
		current_tween.kill()  # Stop the existing tween if it's still going
	current_tween = create_tween()
	current_tween.tween_property(audio_player, "volume_db", -80.0, duration) # fade to silence in 2 seconds

# Located in SongSelect menu
func _on_song_list_item_button_down(song_name):
	await fade_out_audio(demo_audio_player, 1.5)
	for song in MusicLoader.song_library:
		if song.name == song_name:
			display_song_details(song)
			demo_audio = load(Util.locate_song(song))
			return
	print("ERROR: Could not find song '" + song_name + "' in song library")

# Located in SongSelect menu
var demo_play_id = 0
func _on_demo_button_button_down() -> void:
	demo_play_id += 1
	var current_id = demo_play_id
	if current_tween:
		current_tween.kill()  # Cancel fade out
		current_tween = null
	demo_audio_player.volume_db = 0
	demo_audio_player.stream = demo_audio
	demo_audio_player.play(DEMO_START_TIME)
	# TODO Expose this timer and kill it manually when needed;
	# Problem when play demo > switch song> play demo = second demo is cut short
	# and each successive play gets cut short as well
	await get_tree().create_timer(DEMO_DURATION).timeout
	if current_id == demo_play_id:
		await fade_out_audio(demo_audio_player, 1.5)


# Located in SongSelect menu
func _on_play_song_button_down() -> void:
	var current_selected = $SongSelect/VBoxContainer/HBoxContainer/SongDetails/SongDetailsDisplay/VBoxContainer/SongName.text
	for song in MusicLoader.song_library:
		if song.name == current_selected:
			demo_audio_player.stop()
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

# Located in Pause menu
func _on_pause_quit_button_down() -> void:
	quit_song_func.call()
