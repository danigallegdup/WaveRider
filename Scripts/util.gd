extends Node

'''
AUTOLOAD: Util

This script is an autoload, meaning it can be accessed from any other script at will.

The methods in this script are miscellaneous helper functions that may be useful in more than one
place.
'''

# The default 'round(...)' function only rounds to the nearest decimal - this function allows you to
#	choose precision.
func round_to_place(to_round, decimal_place):
	return round(to_round * pow(10.0, decimal_place)) / pow(10.0, decimal_place)

func sec_to_minutes(seconds: float):
	return "%02d:%02d" % [int(floor(seconds/60)), int(seconds)%60]
