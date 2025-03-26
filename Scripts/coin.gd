extends Area3D

const OBJ_TYPE = "coin"

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# Increase score (handled in Main later)
		get_tree().root.get_node("Main").collision(self)
		queue_free()  # Remove coin
