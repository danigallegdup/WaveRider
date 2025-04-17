extends Node2D

const VU_COUNT = 16
const FREQ_MAX = 11050.0

const WIDTH = 800
const HEIGHT = 250
const HEIGHT_SCALE = 8.0
const MIN_DB = 60
const ANIMATION_SPEED = 0.1

var spectrum
var min_values = []
var max_values = []

@onready var main: Node3D = $"../../.."
@onready var audio_stream_player: AudioStreamPlayer = $"../../../AudioStreamPlayer"

func _draw():
	var w = WIDTH / VU_COUNT
	for i in range(VU_COUNT):
		var min_height = min_values[i]
		var max_height = max_values[i]
		var height = lerp(min_height, max_height, ANIMATION_SPEED)
		
		var colour = Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 0)
		if main.current_song_data != null:
			var colour_palette = main.current_song_data["data"]["colours"]
			colour = colour_palette[i % len(colour_palette)]
		
		colour.v = 0.6
		draw_rect(
				Rect2(w * i, HEIGHT - height, w - 2, height),
				#Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 0.6)
				colour
		)
		colour.v = 1.0
		draw_line(
				Vector2(w * i, HEIGHT - height),
				Vector2(w * i + w - 2, HEIGHT - height),
				#Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 1.0),
				colour,
				2.0,
				true
		)
		

func _process(_delta):
	if not audio_stream_player.playing:
		# Smoothly decay values to zero when paused
		for i in range(VU_COUNT):
			min_values[i] = lerp(min_values[i], 0.0, ANIMATION_SPEED)
			max_values[i] = lerp(max_values[i], 0.0, ANIMATION_SPEED)
		queue_redraw()
		return
	
	var data = []
	var prev_hz = 0

	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT * HEIGHT_SCALE
		data.append(height)
		prev_hz = hz

	for i in range(VU_COUNT):
		if data[i] > max_values[i]:
			max_values[i] = data[i]
		else:
			max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)

		if data[i] <= 0.0:
			min_values[i] = lerp(min_values[i], 0.0, ANIMATION_SPEED)

	# Sound plays back continuously, so the graph needs to be updated every frame.
	queue_redraw()


func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	min_values.resize(VU_COUNT)
	max_values.resize(VU_COUNT)
	min_values.fill(0.0)
	max_values.fill(0.0)
