extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# Shatter effect (placeholder: hide for now)
		get_tree().root.get_node("Main").hit_obstacle(self)
		queue_free()  # Remove obstacle
