extends CharacterBody3D

@export var segment_count: int = 10
@onready var sprite_3d: Sprite3D = $Sprite3D

var speed = 5.0

var transition_speed = 8.0
var lanes = [-1.0, 0.0, 1.0]  # X positions of lanes
var current_lane = 1  # Start in center lane

var lean_speed = 10.0
var lean_angle = 0.0
var max_lean = 10.0

var current_sprite = 0
@onready var sprites = [
	preload("res://sprites/player/biker2_left.png"),
	preload("res://sprites/player/biker2_middle.png"),
	preload("res://sprites/player/biker2_right.png"),
	preload("res://sprites/player/biker2_middle.png"),
]
@onready var default_sprite = preload("res://sprites/player/player_animated.tres")

func sprite_progress():
	sprite_3d.texture = sprites[current_sprite % len(sprites)]
	current_sprite += 1
	
func go_to_default_sprite():
	sprite_3d.texture = default_sprite

func _physics_process(delta):
	# Move forward
	velocity.z = -speed  # Negative Z is forward
	move_and_slide()
	
	if Input.is_action_just_pressed("left") and current_lane > 0:
		current_lane -= 1
	if Input.is_action_just_pressed("right") and current_lane < 2:
		current_lane += 1
		
	position.x = lerp(position.x, lanes[current_lane], transition_speed * delta)
	
	# Lean effect when moving
	var target_lean = 0.0
	if position.x > lanes[current_lane] + 0.1:
		target_lean = max_lean  # Lean left
	elif position.x < lanes[current_lane] - 0.1:
		target_lean = -max_lean  # Lean right
	lean_angle = lerp(lean_angle, target_lean, lean_speed * delta)
	rotation_degrees.z = lean_angle
