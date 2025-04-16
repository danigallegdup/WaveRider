extends Node3D

# These keys are used to avoid mis-spellings
const OBSTACLES_KEY = "obstacles"
const COINS_KEY = "coins"

const COIN_POINTS = 10

const END_OF_SONG_OFFSET = 2

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
const DEFAULT_BIKE_SPEED = 5.0

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
@onready var audio_visualizer_viewport: Sprite3D = $AudioVisualizerViewport
@onready var spawned_objects: Node3D = $SpawnedObjects

@onready var Music = $AudioStreamPlayer
@onready var Menus = $Menus

var game_running = false

const POOL_SIZE = 100  # of segments to keep in the world
const SEGMENT_LENGTH = 10.0  # distance between segments
@onready var terrain_scene := preload("res://Scenes/Terrain.tscn")
@onready var ground_scene  := preload("res://Scenes/Ground.tscn")

func _ready():
	TimescaleUtil.audio_player = Music
	MusicLoader.main_link = self
	Menus.quit_song_func = Callable(self, "quit_song")
	
	# tell the player how many segments we have
	bicycle.segment_count = POOL_SIZE

	# spawn terrain pool
	for i in POOL_SIZE:
		var t = terrain_scene.instantiate()
		t.position = Vector3(0, 0, -(i * SEGMENT_LENGTH))
		# configure recycling parameters
		t.segment_length = SEGMENT_LENGTH
		t.recycle_distance = SEGMENT_LENGTH * 2  # or whatever looks good
		add_child(t)
		
	# spawn ground pool
	for i in POOL_SIZE:
		var g = ground_scene.instantiate()
		g.position = Vector3(0, 0, -(i * SEGMENT_LENGTH))
		g.segment_length = SEGMENT_LENGTH
		g.recycle_distance = SEGMENT_LENGTH * 2
		add_child(g)
	
func start_game(new_song_data):
	if game_running:
		return
	
	# Reset game state
	health = 5
	score = 0
	timings = {
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
	music_started = false
	
	# Translate song data
	var song_stream = load(Util.locate_song(new_song_data))
	Music.stream = song_stream
	song_data = {
		"lead-in": 3, # How many seconds before the first note collision?
		"travel-duration": 2, # How many seconds between spawn time and collision?
		"song-duration": new_song_data.data.duration,
		OBSTACLES_KEY: new_song_data.data.obstacles,
		COINS_KEY: new_song_data.data.coins
	}
	# TODO Give tempo beats to the player sprite animator
	
	# Start running the game
	Menus.hide()
	# Music is loaded into AudioStreamPlayer before this point
	UI.initialize()
	UI.set_music_length(Music.stream.get_length())
	game_time = min(-song_data["lead-in"], -song_data["travel-duration"]) + 1
	bicycle.speed = SPAWN_OFFSET / song_data["travel-duration"]
	print("INITIALIZED:\n\tPlayer speed: " + str(bicycle.speed) + "\n\tGame time: " + str(game_time))
	#Initialize object spawn timings
	update_timings(COINS_KEY)
	update_timings(OBSTACLES_KEY)
	game_running = true

func _process(delta):
	audio_visualizer_viewport.position.z = bicycle.position.z - 125
	
	# Below are all game-process requirements
	if not game_running:
		return
	game_time += delta
	UI.set_time(floor(game_time))
	UI.set_timescale(Util.round_to_place(Engine.time_scale, 2))
	UI.update_music_duration(game_time)
	
	# If unpausing game
	if game_time > 0 and not Music.playing and not music_started:
		Music.playing = true
		music_started = true
	
	# If end of song
	if game_time > song_data["song-duration"] + END_OF_SONG_OFFSET:
		game_won()
		return  # Do not execute the rest of the frame process
	
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
			obj.position = Vector3(LANES[randi() % 3], 0.5, bicycle.position.z - SPAWN_OFFSET)
			obj.set_meta("spawn_time", game_time)
			spawned_objects.add_child(obj)  # Add to SpawnedObjects node
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

func end_game():
	# Clear all spawned objects
	for child in spawned_objects.get_children():
		child.queue_free()
	game_running = false
	music_started = false
	bicycle.speed = DEFAULT_BIKE_SPEED
	UI.hide()
	Menus.show()

func quit_song():
	print("Qutting the game...")
	Menus.toggle_pause()
	Music.stop()
	end_game()
	Menus.switch_menu(Menus.menus.song_select)

func game_over():
	print("Game Over! Score: ", score)
	Music.stop()
	end_game()
	Menus.score_label.text = "Final Score: " + str(score)
	Menus.switch_menu(Menus.menus.game_over)

func game_won():
	print("You won the game!", score)
	Music.stop()
	end_game()
	Menus.switch_menu(Menus.menus.game_won)

func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]

# This function will trigger when the audio track is finished playing; use this to transition to
# 	score screen.
#func _on_audio_stream_player_finished() -> void:
	#print("Song complete! Well done!")
	#game_won()
