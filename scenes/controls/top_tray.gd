extends Node2D

@onready var score_label: Label = $CanvasLayer/Control/ScoreLabel

func set_score(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
