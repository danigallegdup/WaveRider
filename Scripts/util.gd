extends Node

'''
AUTOLOAD: Util

This script is an autoload, meaning it can be accessed from any other script at will.

The methods in this script are miscellaneous helper functions that may be useful in more than one
place.
'''
const DEFAULT_FILE_NAME = "<default>"
const DEFAULT_FILE_CHECKSUM = "000000"

# Remember to change this when doing desktop export
const IS_WEB_EXPORT = false

# The default 'round(...)' function only rounds to the nearest decimal - this function allows you to
#	choose precision.
func round_to_place(to_round, decimal_place):
	return round(to_round * pow(10.0, decimal_place)) / pow(10.0, decimal_place)

func sec_to_minutes(seconds: float):
	return "%02d:%02d" % [int(floor(seconds/60)), int(seconds)%60]

# This will return the file location of the song whose data has been passed in
func locate_song(song_data):
	if song_data.data.file_name == DEFAULT_FILE_NAME:
		return song_data.data.default_resource_location
	return song_data.data.file_name
	
func get_res(res_path):
	if ".remap" in res_path:
		res_path = res_path.replace(".tscn", "")
		res_path = res_path.replace(".png", "")
	return res_path
	
	
	
