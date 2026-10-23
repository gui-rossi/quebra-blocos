extends "res://scenes/powerups/powerup_visual.gd"

# Hourglass: slows the combo timer down for a while (rare). Wooden caps, glass bulbs, sand.

func _init() -> void:
	sprite = preload("res://assets/powerups/hourglass.png")
	halo_color = Color(0.55, 0.8, 1.0)

# Flair: flips over before the time slows down
func _flair() -> void:
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.6, 1.8, 2.0, 0), 0.15)
	await tween.finished
