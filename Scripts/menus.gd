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

@onready var song_list = $SongSelect/ScrollContainer/SongList
@onready var song_list_item = preload("res://Scenes/SongListItem.tscn")

func _ready():
	#switch_menu(menus.main)
	switch_menu(menus.song_select)
	#self.hide()
	# TODO Load MusicLoader.song_library into song_list
	create_list_item({"song_name": "Wowee"})
	connect_song_list_buttons()
	
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
	l.find_child("SongName").text = song_data.song_name
	song_list.add_child(l)

func connect_song_list_buttons():
	for b in song_list.get_children():
		#f.bind(b.find_child("SongName").text)
		b.find_child("Button").connect("button_down", _on_song_list_item_button_down.bind(b.find_child("SongName").text))

func _on_continue_button_down() -> void:
	toggle_pause()

func _on_song_list_item_button_down(song_name):
	print(song_name)
