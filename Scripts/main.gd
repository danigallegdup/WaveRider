extends Node3D

# === CONSTANTS ===
const OBSTACLES_KEY = "obstacles"
const COINS_KEY = "coins"
const COIN_POINTS = 10
const SPAWN_OFFSET = 40  # Z position of new spawns (relative to player)
const LANES = [-1.0, 0.0, 1.0]  # X positions of lanes

# === SONG DATA (TEMP: Replace later with dynamic input) ===
var fake_song_data = {
	"lead-in": 3,
	"travel-duration": 2,
	"song-duration": 25,
	OBSTACLES_KEY: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
	COINS_KEY: [0.5, 1.5, 2.0, 3.5]
}
var song_data = fake_song_data

# === GAME STATE ===
var game_time = 0.0
var health = 5
var score = 0
var music_started = false

# === TIMING MANAGERS ===
var timings = {
	OBSTACLES_KEY: { "next_idx": 0, "current_timing": 0.0, "empty": false },
	COINS_KEY: { "next_idx": 0, "current_timing": 0.0, "empty": false }
}

# === NODES ===
@onready var bicycle = $Player
@onready var UI = $UI
@onready var Music = $AudioStreamPlayer
@onready var terrain: Node3D = $Terrain
@onready var ground: Node3D = $Ground

# === OBJECT RESOURCES ===
@onready var objs_resources = {
	OBSTACLES_KEY: preload("res://Scenes/obstacle.tscn"),
	COINS_KEY: preload("res://Scenes/coin.tscn")
}
@onready var next_objs = {
	OBSTACLES_KEY: objs_resources[OBSTACLES_KEY].instantiate(),
	COINS_KEY: objs_resources[COINS_KEY].instantiate()
}

# === INITIAL SETUP ===
func _ready():
	UI.initialize()
	UI.set_music_length(Music.stream.get_length())
	TimescaleUtil.audio_player = Music

	game_time = min(-song_data["lead-in"], -song_data["travel-duration"]) + 1
	bicycle.speed = SPAWN_OFFSET / song_data["travel-duration"]

	var world_length = bicycle.speed * song_data["song-duration"]
	terrain.scale.z = world_length
	terrain.position.z = -world_length / 2
	ground.scale.z = world_length
	ground.position.z = -world_length / 2

	print("INITIALIZED:\n\tPlayer speed: ", bicycle.speed, "\n\tGame time: ", game_time)

	update_timings(COINS_KEY)
	update_timings(OBSTACLES_KEY)

# === START GAME WITH A CUSTOM SONG ===
func start_game_with_song(stream: AudioStream, duration: float, data: Dictionary):
	Music.stream = stream
	UI.set_music_length(duration)
	TimescaleUtil.audio_player = Music

	song_data = data
	song_data["song-duration"] = duration

	game_time = min(-song_data["lead-in"], -song_data["travel-duration"]) + 1
	bicycle.speed = SPAWN_OFFSET / song_data["travel-duration"]

	var world_length = bicycle.speed * song_data["song-duration"]
	terrain.scale.z = world_length
	terrain.position.z = -world_length / 2
	ground.scale.z = world_length
	ground.position.z = -world_length / 2

	print("NEW SONG LOADED:\n\tDuration: ", duration, "\n\tPlayer Speed: ", bicycle.speed)

	# Reset spawn trackers
	timings[COINS_KEY] = { "next_idx": 0, "current_timing": 0.0, "empty": false }
	timings[OBSTACLES_KEY] = { "next_idx": 0, "current_timing": 0.0, "empty": false }

	update_timings(COINS_KEY)
	update_timings(OBSTACLES_KEY)

	UI.initialize()


# === MAIN GAME LOOP ===
func _process(delta):
	game_time += delta

	UI.set_time(floor(game_time))
	UI.set_timescale(Util.round_to_place(Engine.time_scale, 2))
	UI.update_music_duration(game_time)

	if game_time > 0 and not Music.playing and not music_started:
		Music.playing = true
		music_started = true

	for key in [OBSTACLES_KEY, COINS_KEY]:
		if timings[key]["empty"]:
			continue
		if game_time - timings[key]["current_timing"] > 0:
			print("SPAWN ", key, " AT ", game_time)
			var obj = next_objs[key]
			obj.position = Vector3(LANES[randi() % 3], 0.5, bicycle.position.z - SPAWN_OFFSET)
			obj.set_meta("spawn_time", game_time)
			add_child(obj)
			call_deferred("update_timings", key)
			call_deferred("reload_obj", key)

# === OBJECT MANAGEMENT ===
func reload_obj(obj_type):
	next_objs[obj_type] = objs_resources[obj_type].instantiate()

func update_timings(obj_type):
	var idx = timings[obj_type]["next_idx"]
	if idx >= song_data[obj_type].size():
		timings[obj_type]["empty"] = true
		return
	timings[obj_type]["current_timing"] = song_data[obj_type][idx] - song_data["travel-duration"]
	timings[obj_type]["next_idx"] += 1

# === COLLISIONS ===
func collision(obj):
	if "OBJ_TYPE" not in obj:
		return

	print("HIT ", obj.OBJ_TYPE, ": Spawned at ", obj.get_meta("spawn_time"), ", collided at ", game_time)

	match obj.OBJ_TYPE:
		"coin":
			score += COIN_POINTS
			UI.add_score(score)
		"obstacle":
			health -= 1
			UI.set_health(health)
			TimescaleUtil.slowdown()
			if health <= 0:
				game_over()
		_:
			print("ERROR: Unconfigured collision branch: ", obj.OBJ_TYPE)

# === GAME END ===
func game_over():
	print("Game Over! Score: ", score)
	if true: return  # TODO: Replace for full game
	get_tree().quit()

# === SKY PALETTE ===
func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]

# === WHEN MUSIC ENDS ===
func _on_audio_stream_player_finished():
	print("Song complete! Well done!")
	game_over()
