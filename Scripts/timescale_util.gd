extends Node

'''
AUTOLOAD: TimescaleUtil

This script is an autoload, meaning it can be accessed from any other script at will.

The methods in this script modify the game run speed.
'''

# Configuration settings
const SLOW_SCALE = 0.7
const SLOW_DURATION = 0.95
const LERP_UP_RATE = 0.65
const LERP_DOWN_RATE = -1.2

# Pause configuration
const PAUSE_RATE = -5
const UNPAUSE_RATE = 2
const CATCH_PLAYBACK_LIMIT = 0.05

# Safety values
const MAX_SCALE = 1.0
const MIN_SCALE = 0.5

# Audio player is initialized by the main script in the _ready() function
var audio_player: AudioStreamPlayer

# The following variables assist linear interpolation ("lerp") of the timescale
var cur_scale = 1.0
var lerping = false
var lerp_target
var lerp_rate

# These variables help pausing the playback
var is_paused = false
var last_audio_position = -1.0

func _process(delta):
	# Catch last audio position if AudioStreamPlayer is still playing but we are actively pausing
	if is_paused: # Separate check so other checks can be avoided most of the time
		if last_audio_position < 0 and audio_player.playing and cur_scale < CATCH_PLAYBACK_LIMIT:
			last_audio_position = audio_player.get_playback_position()
	if lerping:
		# Continue lerp
		cur_scale += lerp_rate*delta
		# Lerp break conditions
		if cur_scale > MAX_SCALE: 
			cur_scale = MAX_SCALE
			lerping = false
		if cur_scale < MIN_SCALE and not is_paused:  # Do not freeze the game completely
			cur_scale = MIN_SCALE
			lerping = false
		if (lerp_rate < 0 and cur_scale <= lerp_target) or (lerp_rate > 0 and cur_scale >= lerp_target):
			cur_scale = lerp_target
			lerping = false
		# Update the timescale
		_update_scale(cur_scale)

# This method instantly modifies the timescale (does not lerp)
func quick_slowdown(target_scale=SLOW_SCALE):
	_update_scale(target_scale)  # Slow motion
	await get_tree().create_timer(SLOW_DURATION).timeout
	_update_scale(1.0)

# This method enables timescale lerp down, pause, and lerp up
func slowdown(target_scale=SLOW_SCALE):
	if is_paused: return
	_begin_lerping(target_scale, LERP_DOWN_RATE)
	await get_tree().create_timer(SLOW_DURATION).timeout
	if is_paused: return
	_begin_lerping(1.0, LERP_UP_RATE)

# This private method directly modifies the game elements that require scaling
func _update_scale(target_scale):
	Engine.time_scale = target_scale
	if audio_player: audio_player.pitch_scale = target_scale

# This private method initializes the lerp, setting the target and rate, and beginning the lerp.
#	Note that incorrect configurations are handled in the lerp break logic of _process() (for
#	example, if rate is negative and target_scale > cur_scale)
func _begin_lerping(target_scale, rate):
	lerp_target = target_scale
	lerp_rate = rate
	lerping = true

# This will be used to pause and un-pause the game
func toggle_pause():
	if is_paused:
		is_paused = false
		cur_scale = MIN_SCALE
		_update_scale(cur_scale)
		# Weird AudioStreamPlayer behaviour warrants this workaround.
		#	1. If Engine.time_scale hits 0, AudioStreamPlayer.playing becomes false
		#	2. When AudioStreamPlayer.playing becomes false, it forgets where in the stream it
		#		previously was. Because of this, we need to capture the time as accurately as
		#		possible.
		#	3. We cannot capture the time very accurately. That is, the method to get where in the
		#		playback the audio is, is not a very trustable source. So, we roughly snatch it once
		#		the engine has slowed down significantly (I am unsure whether this improves
		#		accuracy).
		if not audio_player.playing:
			audio_player.play(last_audio_position)
			print("Resuming from: " + str(Util.round_to_place(last_audio_position, 2)))
			last_audio_position = -1.0
		_begin_lerping(1.0, UNPAUSE_RATE)
	else:
		is_paused = true
		_begin_lerping(0.0, PAUSE_RATE)
