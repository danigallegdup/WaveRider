extends Node3D

const POLLING_TIMING = true

const COIN_POINTS = 10

const SPAWN_OFFSET = 10 # Doesn't work as intended
const TIME_POSITION_TRANSLATION = 10/3
var fake_song_data = {
	"lead-in": 3,
	"travel-duration": 3,
	"obstacles": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
	"coins": []#[0.5, 1.5, 2.0, 3.5]
}
var lanes = [-1.0, 0.0, 1.0]
var game_time = 0.0
var health = 5
var score = 0

# Add at top
@onready var score_label = $UI/ScoreLabel
@onready var health_label = $UI/HealthLabel
@onready var bicycle = $Player

func _ready():
	$UI/ScoreLabel.text = "Score: 0"
	game_time = min(-fake_song_data["lead-in"], -fake_song_data["travel-duration"]) + 1
	bicycle.speed = TIME_POSITION_TRANSLATION*SPAWN_OFFSET/fake_song_data["travel-duration"]

func _process(delta):
	game_time += delta
	spawn_from_song_data()
	$UI/TimingLabel.text = "Time: " + str(floor(game_time))
	$UI/TimescaleLabel.text = "Timescale: " + str(Engine.time_scale)

func spawn_from_song_data():
	for time in fake_song_data["obstacles"]:
		var t = time - fake_song_data["travel-duration"]
		if abs(game_time - t) < 0.1 and not is_spawned(time):
			spawn_obstacle(time)
	for time in fake_song_data["coins"]:
		if abs(game_time - time) < 0.1 and not is_spawned(time):
			spawn_coin(time)

func spawn_obstacle(time):
	var obs = load("res://Scenes/obstacle.tscn").instantiate()
	#obs.position = Vector3(lanes[randi() % 3], 0.5, -20 - time * SPAWN_OFFSET)
	obs.position = Vector3(lanes[1], 0.5, -20 - time * SPAWN_OFFSET)
	obs.set_meta("spawn_time", game_time)
	add_child(obs)

func spawn_coin(time):
	var coin = load("res://Scenes/coin.tscn").instantiate()
	coin.position = Vector3(lanes[randi() % 3], 0.5, -20 - time * SPAWN_OFFSET)
	coin.set_meta("spawn_time", time)
	add_child(coin)

func is_spawned(time):
	for child in get_children():
		if child is Area3D and abs(child.get_meta("spawn_time", -1) - time) < 0.1:
			return true
	return false

func collision(obj):
	# Ignore objects without a collision branch
	if "OBJ_TYPE" not in obj: return
	# Switch down branch based on object type
	if obj.OBJ_TYPE == "coin":
		score += COIN_POINTS
		score_label.text = "Score: " + str(score)
	elif obj.OBJ_TYPE == "obstacle":
		# Enable for lining up spawn and hit times
		if POLLING_TIMING:
			print("HIT: Spawned at " + str(obj.get_meta("spawn_time")) + ", collided at " + str(game_time))
			return
		health -= 1
		health_label.text = "Health: " + str(health)
	
		Engine.time_scale = 0.5  # Slow motion
		await get_tree().create_timer(0.5).timeout
		Engine.time_scale = 1.0
		if health <= 0:
			game_over()
	else: print("Unconfigured collision branch: " + obj.OBJ_TYPE)

func game_over():
	print("Game Over! Score: ", score)
	get_tree().quit()  # Placeholder

func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]
