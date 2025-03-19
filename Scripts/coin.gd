extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# Increase score (handled in Main later)
		get_tree().root.get_node("Main").hit_coin(10)
		queue_free()  # Remove coin
