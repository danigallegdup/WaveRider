extends VehicleBody3D

var speed = 5.0
var lanes = [-1.0, 0.0, 1.0]  # X positions of lanes
var current_lane = 1  # Start in center lane
var lean_angle = 0.0
var max_lean = 25.0
var lean_speed = 10.0

func _physics_process(delta):
	# Constant forward movement
	linear_velocity.z = -speed

	# Handle lane switching
	if Input.is_action_just_pressed("left") and current_lane > 0:
		current_lane -= 1
	if Input.is_action_just_pressed("right") and current_lane < 2:
		current_lane += 1

	# Smoothly move to target lane
	position.x = lerp(position.x, lanes[current_lane], 10 * delta)

	# Lean effect when moving
	var target_lean = 0.0
	if position.x > lanes[current_lane] + 0.1:
		target_lean = -max_lean  # Lean left
	elif position.x < lanes[current_lane] - 0.1:
		target_lean = max_lean  # Lean right
	lean_angle = lerp(lean_angle, target_lean, lean_speed * delta)
	rotation_degrees.x = lean_angle
