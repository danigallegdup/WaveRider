extends Node3D

# These keys are used to avoid mis-spellings
const OBSTACLES_KEY = "obstacles"
const COINS_KEY = "coins"

const COIN_POINTS = 10

var fake_song_data = {
	"lead-in": 3, # How many seconds before the first note collision?
	"travel-duration": 2, # How many seconds between spawn time and collision?
	"song-duration": 25, # 25 seconds
	# Below are spawn times of objects
	OBSTACLES_KEY: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
	COINS_KEY: [0.5, 1.5, 2.0, 3.5]
}
var song_data = fake_song_data

const SPAWN_OFFSET = 40 # z position of new spawns (relative to player)
const LANES = [-1.0, 0.0, 1.0] # x position of lanes

var game_time = 0.0
var health = 5
var score = 0
var music_started: bool = false

# Running data for entity spawns
var timings = {
	OBSTACLES_KEY: {
		"next_idx": 0,
		"current_timing": 0.0,
		"empty": false
	},
	COINS_KEY: {
		"next_idx": 0,
		"current_timing": 0.0,
		"empty": false
	}
}

# This saves the resource in memory on start to be instantiated repeatedly
@onready var objs_resources = {
	OBSTACLES_KEY: preload("res://Scenes/obstacle.tscn"),
	COINS_KEY: preload("res://Scenes/coin.tscn")
}
# This holds the next spawn instance to be used
@onready var next_objs = {
	OBSTACLES_KEY: objs_resources[OBSTACLES_KEY].instantiate(),
	COINS_KEY: objs_resources[COINS_KEY].instantiate()
}

@onready var bicycle = $Player
@onready var UI = $UI
@onready var terrain: Node3D = $Terrain
@onready var ground: Node3D = $Ground

@onready var Music = $AudioStreamPlayer
@onready var Menus = $Menus

func _ready():
	UI.initialize()
	UI.set_music_length(Music.stream.get_length())
	TimescaleUtil.audio_player = Music
	game_time = min(-song_data["lead-in"], -song_data["travel-duration"]) + 1
	bicycle.speed = SPAWN_OFFSET / song_data["travel-duration"]
	
	# Set up the terrain
	var world_length = bicycle.speed * song_data["song-duration"]
	terrain.scale.z = world_length
	terrain.position.z = -world_length / 2
	ground.scale.z = world_length
	ground.position.z = -world_length / 2
	
	print("INITIALIZED:\n\tPlayer speed: " + str(bicycle.speed) + "\n\tGame time: " + str(game_time))
	#Initialize object spawn timings
	update_timings(COINS_KEY)
	update_timings(OBSTACLES_KEY)

func _process(delta):
	game_time += delta
	UI.set_time(floor(game_time))
	UI.set_timescale(Util.round_to_place(Engine.time_scale, 2))
	UI.update_music_duration(game_time)
	
	if game_time > 0 and not Music.playing and not music_started:
		Music.playing = true
		music_started = true
	
	if Input.is_action_just_pressed("pause"):
		Menus.toggle_pause()
	
	# Check if new spawns to do
	for o in [OBSTACLES_KEY, COINS_KEY]:
		# Ignore key if no more spawns
		if timings[o]["empty"]: continue
		# If the next timing has been passed, turn on pre-loaded spawn
		if game_time - timings[o]["current_timing"] > 0:
			print("SPAWN " + o + " AT " + str(game_time))
			var obj = next_objs[o]
			#obj.position = Vector3(LANES[1], 0.5, bicycle.position.z - SPAWN_OFFSET)
			obj.position = Vector3(LANES[randi() % 3], 0.5, bicycle.position.z - SPAWN_OFFSET)
			obj.set_meta("spawn_time", game_time)
			add_child(obj)
			# Identify the next spawn and pre-load an instance
			call_deferred("update_timings", o)
			call_deferred("reload_obj", o)

# This is used to pre-emptively instantiate a new object.
func reload_obj(obj_type):
	next_objs[obj_type] = objs_resources[obj_type].instantiate()

# This is used to expose the timing of the next spawnable to the _process() function to limit it's
#	processing time
func update_timings(obj_type):
	# Get the index of the next timing element
	var idx = timings[obj_type]["next_idx"]
	# If out of data, indicate to stop tracking this index
	if idx >= len(song_data[obj_type]):
		timings[obj_type]["empty"] = true
		return
	# Retrieve the timing for the next object, subtract the running time
	timings[obj_type]["current_timing"] = song_data[obj_type][idx] - song_data["travel-duration"]
	# Prepare to retrieve the next element
	timings[obj_type]["next_idx"] += 1

func collision(obj):
	# Ignore objects without a collision branch
	if "OBJ_TYPE" not in obj: return
	print("HIT " + obj.OBJ_TYPE + ": Spawned at " + str(obj.get_meta("spawn_time")) + ", collided at " + str(game_time))
	# Switch down branch based on object type
	if obj.OBJ_TYPE == "coin":
		score += COIN_POINTS
		UI.add_score(score)
	elif obj.OBJ_TYPE == "obstacle":
		health -= 1
		UI.set_health(health)
		#TimescaleUtil.quick_slowdown()
		TimescaleUtil.slowdown()
		if health <= 0:
			game_over()
	else: print("ERROR: Unconfigured collision branch: " + obj.OBJ_TYPE)

func game_over():
	print("Game Over! Score: ", score)
	if true: return # TODO remove this for real game
	get_tree().quit()  # Placeholder

func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]
	

# This function will trigger when the audio track is finished playing; use this to transition to
# 	score screen.
func _on_audio_stream_player_finished() -> void:
	print("Song complete! Well done!")
	game_over()
