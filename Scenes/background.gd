extends MeshInstance3D

func _process(delta):
	transform.origin.z += 5 * delta  # Move toward player
	if transform.origin.z > 10:
		transform.origin.z = -50  # Reset
