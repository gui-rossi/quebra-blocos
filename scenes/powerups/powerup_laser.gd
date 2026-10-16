extends "res://scenes/powerups/powerup_visual.gd"

# Laser: a cyan energy orb with a glowing cross, the row and column it will clear

const CORE := Color(0.35, 0.95, 1.0)
const DEEP := Color(0.05, 0.42, 0.7)

func _draw_icon(r: float) -> void:
	var beam = r * (1.25 + 0.08 * glow)  # the cross reaches past the orb
	var width = r * 0.3

	# soft halo
	for i in range(3):
		draw_circle(Vector2.ZERO, r * (1.15 - i * 0.1), Color(CORE, 0.06 + 0.05 * glow))

	# orb: dark outline, deep blue, lighter towards the top-left, white shine
	draw_circle(Vector2.ZERO, r * 0.9, INK)
	draw_circle(Vector2.ZERO, r * 0.82, DEEP)
	draw_circle(Vector2(-r * 0.12, -r * 0.14), r * 0.62, DEEP.lerp(CORE, 0.45))
	draw_circle(Vector2(-r * 0.22, -r * 0.26), r * 0.36, DEEP.lerp(CORE, 0.75))

	# the cross: outlined beams, bright core line
	for horizontal in [true, false]:
		var size = Vector2(beam * 2.0, width) if horizontal else Vector2(width, beam * 2.0)
		var rect = Rect2(-size / 2.0, size)
		draw_rect(rect.grow(r * 0.06), INK)
		draw_rect(rect, CORE)
		var core_size = Vector2(beam * 2.0, width * 0.35) if horizontal else Vector2(width * 0.35, beam * 2.0)
		draw_rect(Rect2(-core_size / 2.0, core_size), Color(1, 1, 1, 0.85 + 0.15 * glow))

	draw_circle(Vector2.ZERO, width * 0.55, Color.WHITE)
	draw_circle(Vector2(-r * 0.38, -r * 0.4), r * 0.1, Color(1, 1, 1, 0.8))

# Flair: charges up (grows and glows) before the beams fire
func _flair() -> void:
	var tween = create_tween()
	tween.tween_property(self, "glow", 1.0, 0.1)
	tween.parallel().tween_property(self, "scale", scale * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.12)
	await tween.finished
