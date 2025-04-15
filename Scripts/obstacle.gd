extends Area3D

const OBJ_TYPE = "obstacle"

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		# Shatter effect (placeholder: hide for now)
		get_tree().root.get_node("Main").collision(self)
		$Destruction.destroy(25)
		print("Collision")
		# queue_free()  # Remove obstacle
