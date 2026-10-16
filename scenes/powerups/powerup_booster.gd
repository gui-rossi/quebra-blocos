extends "res://scenes/powerups/powerup_visual.gd"

# Booster: a golden star with "+2", it raises the score multiplier and refills the combo timer

const GOLD := Color(1.0, 0.8, 0.22)
const GOLD_DARK := Color(0.78, 0.45, 0.05)

func _draw_icon(r: float) -> void:
	var star = _star_points(r * 1.0, r * 0.48, 5)
	var inner = _star_points(r * 0.72, r * 0.34, 5)

	draw_circle(Vector2.ZERO, r * 1.05, Color(GOLD, 0.06 + 0.08 * glow))
	_polygon(star, GOLD_DARK, r * 0.18)
	# lighter inner star shifted to the upper left gives it some volume
	for i in range(inner.size()):
		inner[i] += Vector2(-r * 0.04, -r * 0.05)
	draw_colored_polygon(inner, GOLD.lerp(Color.WHITE, 0.2 + 0.2 * glow))

	# "+N" in the middle
	var font = ThemeDB.fallback_font
	var font_size = int(r * 0.62)
	var text = "+%d" % GameConfig.booster_multiplier
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin = Vector2(-text_size.x / 2.0, font.get_ascent(font_size) / 2.0 - r * 0.02)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(2, int(r * 0.14)), INK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
