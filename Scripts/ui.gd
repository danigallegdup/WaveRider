extends Node2D

const SCORE_PREFIX = "Score: "
const HEALTH_PREFIX = "Health: "
const TIME_PREFIX = "Time: "

var score = 0

@onready var health_label = $MarginContainer/HBoxContainer/HealthLabel
@onready var time_label = $MarginContainer/HBoxContainer/TimeLabel
@onready var score_label = $MarginContainer/HBoxContainer/ScoreLabel

func initialize():
	set_score(0)
	set_time(0.0)
	set_health(5)

func set_health(new_health):
	health_label.text = HEALTH_PREFIX + str(new_health)
	
func set_time(new_time):
	time_label.text = TIME_PREFIX + str(new_time)

func set_score(new_score=score):
	score_label.text = SCORE_PREFIX + str(score)
func add_score(new_score):
	score += new_score
	set_score()
