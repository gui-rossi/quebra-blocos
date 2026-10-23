extends "res://scenes/powerups/powerup_visual.gd"

# Prism: a six-faceted gem with a facet in each block color, it clears every block of the color it lands on

func _init() -> void:
	sprite = preload("res://assets/powerups/prism.png")
	halo_color = Color(1, 1, 1)

# Flair: a quick spin while it flashes
func _flair() -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "rotation", rotation + TAU, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", scale * 1.4, 0.3)
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.3).set_delay(0.1)
	await tween.finished
