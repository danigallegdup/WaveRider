extends Node3D

# These keys are used to avoid mis-spellings
const OBSTACLES_KEY = "obstacles"
const COINS_KEY = "coins"
const TEMPO_BEATS = "tempo_beats"

const COIN_POINTS = 10

const END_OF_SONG_OFFSET = 2

var current_tween: Tween = null

var fake_song_data = {
	"lead-in": 3, # How many seconds before the first note collision?
	"travel-duration": 2, # How many seconds between spawn time and collision?
	"song-duration": 25, # 25 seconds
	# Below are spawn times of objects
	OBSTACLES_KEY: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
	COINS_KEY: [0.5, 1.5, 2.0, 3.5]
}

var fake_scores = {
	"Satchmo": 5000,
	"Ziggy": 4800,
	"Kurt": 3700,
	"Noodle": 2200,
	"Purple Piper": 500
}

var song_data = fake_song_data

@export var current_song_data = null

const SPAWN_OFFSET = 40 # z position of new spawns (relative to player)
const LANES = [-1.0, 0.0, 1.0] # x position of lanes
const DEFAULT_BIKE_SPEED = 5.0

var game_time = 0.0
var health = 1000
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
	},
	TEMPO_BEATS: {
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

@onready var BlurShader = $Player/Camera3D/BlurShader
@onready var BlurActual = $Player/Camera3D/BlurShaderMain

@onready var leader_score := preload("res://Scenes/leader_score.tscn")

var game_running = false

const POOL_SIZE = 100  # of segments to keep in the world
const SEGMENT_LENGTH = 10.0  # distance between segments
@onready var terrain_scene = preload("res://Scenes/terrain.tscn")
@onready var ground_scene = preload("res://Scenes/ground.tscn")

func _ready():
	TimescaleUtil.audio_player = Music
	MusicLoader.main_link = self
	Menus.quit_song_func = Callable(self, "quit_song")
	if not Util.IS_WEB_EXPORT:
		BlurShader.hide()
		BlurShader = BlurActual
		BlurShader.show()
	Menus.BlurShader = BlurShader
	
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
		},
		TEMPO_BEATS: {
			"next_idx": 0,
			"current_timing": 0.0,
			"empty": false
		}
	}
	music_started = false
	
	# Translate song data
	current_song_data = new_song_data
	var song_stream = load(Util.locate_song(new_song_data))
	if new_song_data["type"] == "user":
		var file = FileAccess.open(Util.locate_song(new_song_data), FileAccess.READ)
		var mp3_data = file.get_buffer(file.get_length())
		file.close()
		song_stream = AudioStreamMP3.new()
		song_stream.data = mp3_data
	
	# print(song_stream)
	BlurShader.hide()
	if current_tween:
		current_tween.kill()  # Cancel fade out
		current_tween = null
	Music.volume_db = 0
	Music.stream = song_stream
	song_data = {
		"lead-in": 3, # How many seconds before the first note collision?
		"travel-duration": 2, # How many seconds between spawn time and collision?
		"song-duration": new_song_data.data.duration,
		OBSTACLES_KEY: new_song_data.data.obstacles,
		COINS_KEY: new_song_data.data.coins,
		TEMPO_BEATS: new_song_data.data.tempo_beats
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
	update_timings(TEMPO_BEATS)
	bicycle.go_to_default_sprite()
	BlurShader.hide()
	game_running = true

var current_coin_lane = randi() % 3
const lane_change_probabiility = 0.7

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
	
	# Coins
	if not timings[COINS_KEY]["empty"] and game_time - timings[COINS_KEY]["current_timing"] > 0:
		print("SPAWN " + COINS_KEY + " AT " + str(game_time))
		var obj = next_objs[COINS_KEY]
		obj.position = Vector3(LANES[current_coin_lane], 0.5, bicycle.position.z - SPAWN_OFFSET)
		if randf() < lane_change_probabiility:
			if current_coin_lane == 0 or current_coin_lane == 2:
				current_coin_lane = 1
			else:
				if randf() < 0.5:
					current_coin_lane = 0
				else:
					current_coin_lane = 2
		obj.set_meta("spawn_time", game_time)
		spawned_objects.add_child(obj)  # Add to SpawnedObjects node
		# Identify the next spawn and pre-load an instance
		call_deferred("update_timings", COINS_KEY)
		call_deferred("reload_obj", COINS_KEY)
	
	# Obstacles
	if not timings[OBSTACLES_KEY]["empty"] and game_time - timings[OBSTACLES_KEY]["current_timing"] - 0.2 > 0:
		print("SPAWN " + OBSTACLES_KEY + " AT " + str(game_time))
		var obj = next_objs[OBSTACLES_KEY]
		var options = [0, 1, 2]
		options.erase(current_coin_lane)
		var chosen_lane = options[randi() % options.size()]
		obj.position = Vector3(LANES[chosen_lane], 0.5, bicycle.position.z - SPAWN_OFFSET)
		obj.set_meta("spawn_time", game_time)
		spawned_objects.add_child(obj)  # Add to SpawnedObjects node
		# Identify the next spawn and pre-load an instance
		call_deferred("update_timings", OBSTACLES_KEY)
		call_deferred("reload_obj", OBSTACLES_KEY)
	
	# If the next timing has been passed, turn on pre-loaded spawn
	if not timings[TEMPO_BEATS]["empty"] and game_time - timings[TEMPO_BEATS]["current_timing"] > 0:
		bicycle.sprite_progress()
		# Identify the next spawn and pre-load an instance
		call_deferred("update_timings", TEMPO_BEATS)

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
		UI.set_score(score)
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
	BlurShader.show()
	game_running = false
	music_started = false
	bicycle.speed = DEFAULT_BIKE_SPEED
	UI.hide()
	Menus.show()

func fade_out_audio(audio_player: AudioStreamPlayer, duration: float = 1.0):
	if current_tween:
		current_tween.kill()  # Stop the existing tween if it's still going
	current_tween = create_tween()
	current_tween.tween_property(audio_player, "volume_db", -80.0, duration) # fade to silence in 2 seconds

func quit_song():
	print("Qutting the game...")
	Menus.toggle_pause()
	Music.stop()
	end_game()
	Menus.switch_menu(Menus.menus.song_select)

func game_over():
	print("Game Over! Score: ", score)
	fade_out_audio(Music, 1.5)
	end_game()
	Menus.score_label.text = "Final Score: " + str(score)
	Menus.switch_menu(Menus.menus.game_over)

func game_won():
	print("You won the game!", score)
	fade_out_audio(Music, 1.5)
	end_game()
	for child in Menus.leaderboard.get_children():
		child.queue_free()
	var player_printed = false
	for l_name in fake_scores:
		if not player_printed and score > fake_scores[l_name]:
			var leader_score = leader_score.instantiate()
			leader_score.get_node("Name").text = "Player"
			leader_score.get_node("Score").text = str(score)
			Menus.leaderboard.add_child(leader_score)
			player_printed = true
		var leader_score = leader_score.instantiate()
		leader_score.get_node("Name").text = l_name
		leader_score.get_node("Score").text = str(fake_scores[l_name])
		Menus.leaderboard.add_child(leader_score)
	if not player_printed:
		var leader_score = leader_score.instantiate()
		leader_score.get_node("Name").text = "Player"
		leader_score.get_node("Score").text = str(score)
		Menus.leaderboard.add_child(leader_score)
	Menus.switch_menu(Menus.menus.game_won)

func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]
