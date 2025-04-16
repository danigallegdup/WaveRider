extends Node3D

# how far behind the player before recycling
@export var recycle_distance := 20.0
# length of this segment along Z
@export var segment_length := 10.0

# a reference to the player (or camera) node
@onready var player: CharacterBody3D = $"../Player"

func _process(delta):
	# if this segment is far enough behind the player...
	if position.z > player.position.z + recycle_distance:
		# move it forward by segment_length * total_segments
		# total_segments is stored in a group variable on the player
		var count = player.get("segment_count")
		translate(Vector3(0, 0, -(segment_length * count)))
