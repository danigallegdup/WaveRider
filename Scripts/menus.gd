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

func _ready():
	switch_menu(menus.main)
	
func switch_menu(target:Control):
	if cur_menu.name == target.name: return
	print("MENUS: Switching to: " + target.name)
	cur_menu.hide()
	target.show()
	cur_menu = target
