extends Node3D

var fake_song_data = {
	"obstacles": [1.0, 2.5, 3.0, 4.2],
	"coins": [0.5, 1.5, 2.0, 3.5]
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

func _process(delta):
	game_time += delta
	spawn_from_song_data()

func spawn_from_song_data():
	for time in fake_song_data["obstacles"]:
		if abs(game_time - time) < 0.1 and not is_spawned(time):
			spawn_obstacle(time)
	for time in fake_song_data["coins"]:
		if abs(game_time - time) < 0.1 and not is_spawned(time):
			spawn_coin(time)

func spawn_obstacle(time):
	var obs = load("res://Scenes/obstacle.tscn").instantiate()
	obs.position = Vector3(lanes[randi() % 3], 0.5, -20 - time * 10)
	obs.set_meta("spawn_time", time)
	add_child(obs)

func spawn_coin(time):
	var coin = load("res://Scenes/coin.tscn").instantiate()
	coin.position = Vector3(lanes[randi() % 3], 0.5, -20 - time * 10)
	coin.set_meta("spawn_time", time)
	add_child(coin)

func is_spawned(time):
	for child in get_children():
		if child is Area3D and abs(child.get_meta("spawn_time", -1) - time) < 0.1:
			return true
	return false

func hit_coin(points):
	score += points
	score_label.text = "Score: " + str(score)

func hit_obstacle():
	health -= 1
	health_label.text = "Health: " + str(health)
	
	Engine.time_scale = 0.5  # Slow motion
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	if health <= 0:
		game_over()

func game_over():
	print("Game Over! Score: ", score)
	get_tree().quit()  # Placeholder

func set_color_palette(palette):
	$WorldEnvironment.environment.background_color = palette["sky_color"]
