extends "res://scenes/powerups/powerup_visual.gd"

# Laser: a cyan energy orb with a glowing cross, the row and column it will clear

func _init() -> void:
	sprite = preload("res://assets/powerups/laser.png")
	halo_color = Color(0.35, 0.95, 1.0)

# Flair: charges up (grows and glows) before the beams fire
func _flair() -> void:
	var tween = create_tween()
	tween.tween_property(self, "glow", 1.0, 0.1)
	tween.parallel().tween_property(self, "scale", scale * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.12)
	await tween.finished
