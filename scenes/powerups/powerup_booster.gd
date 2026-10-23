extends "res://scenes/powerups/powerup_visual.gd"

# Booster: a golden star with "+2", it raises the score multiplier and refills the combo timer

func _init() -> void:
	sprite = preload("res://assets/powerups/booster.png")
	halo_color = Color(1.0, 0.8, 0.22)

# "+N" in the middle of the star (the sprite's star sits a little below the texture's centre)
func _draw_icon(r: float) -> void:
	var font = ThemeDB.fallback_font
	var font_size = int(r * 0.62)
	var text = "+%d" % GameConfig.booster_multiplier
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var star_center = Vector2(0, diameter / SPRITE_CONTENT_RATIO * 0.03)
	var origin = star_center + Vector2(-text_size.x / 2.0, font.get_ascent(font_size) / 2.0 - r * 0.04)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, maxi(3, int(r * 0.16)), INK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
