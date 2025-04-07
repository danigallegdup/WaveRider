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

@onready var song_list = $SongSelect/HBoxContainer/ScrollContainer/SongList
@onready var song_list_item = preload("res://Scenes/SongListItem.tscn")

func _ready():
	switch_menu(menus.main)
	#switch_menu(menus.song_select)
	self.hide()
	# Set up SongSelect menu
	MusicLoader.load_custom_songs()
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

# Located in Pause menu
func _on_continue_button_down() -> void:
	toggle_pause()

# Located in SongSelect menu
func _on_song_list_item_button_down(song_name):
	print(song_name)
