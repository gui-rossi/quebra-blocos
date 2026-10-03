extends Node2D

@onready var score_label: Label = $CanvasLayer/Control/ScoreLabel
@onready var combo_label_value: Label = $CanvasLayer/Control/ComboContainerMargin/ComboContainer/ComboLabelValue
@onready var combo_container: VBoxContainer = $CanvasLayer/Control/ComboContainerMargin/ComboContainer

func set_score(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

func set_combo(new_combo: int) -> void:
	if new_combo > 1:
		combo_container.visible = true;
	else:
		combo_container.visible = true;
		
	combo_label_value.text = "%d" % new_combo
