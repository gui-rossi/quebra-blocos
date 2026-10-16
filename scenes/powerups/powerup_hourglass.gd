extends "res://scenes/powerups/powerup_visual.gd"

# Hourglass: slows the combo timer down for a while (rare). Wooden caps, glass bulbs, sand running down.

const WOOD := Color(0.62, 0.38, 0.18)
const WOOD_DARK := Color(0.4, 0.22, 0.1)
const GLASS := Color(0.7, 0.9, 1.0, 0.35)
const SAND := Color(1.0, 0.82, 0.42)

func _draw_icon(r: float) -> void:
	var w = r * 0.62  # half width of the bulbs
	var h = r * 0.78  # half height of the glass
	var neck = r * 0.08

	draw_circle(Vector2.ZERO, r * 1.05, Color(0.55, 0.8, 1.0, 0.05 + 0.07 * glow))

	# glass: two bulbs meeting at the neck, outlined
	var glass = PackedVector2Array([
		Vector2(-w, -h), Vector2(w, -h), Vector2(neck, 0), Vector2(w, h), Vector2(-w, h), Vector2(-neck, 0),
	])
	_polygon(glass, GLASS, r * 0.14)

	# sand: what's left on top, a thin stream, and the pile at the bottom (it shifts with the glow)
	var top_level = lerpf(-h * 0.45, -h * 0.3, glow)
	var top_w = w * (-top_level / h) * 0.95
	draw_colored_polygon(PackedVector2Array([Vector2(-top_w, top_level), Vector2(top_w, top_level), Vector2(0, -neck)]), SAND)
	draw_line(Vector2(0, -neck), Vector2(0, h * 0.6), SAND, maxf(1.0, r * 0.05))
	var pile = lerpf(h * 0.45, h * 0.35, glow)
	draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.9, h * 0.98), Vector2(w * 0.9, h * 0.98), Vector2(0, pile)]), SAND.darkened(0.08))

	# shine on the glass
	draw_line(Vector2(-w * 0.62, -h * 0.85), Vector2(-w * 0.2, -h * 0.25), Color(1, 1, 1, 0.55), maxf(1.0, r * 0.07), true)

	# wooden caps top and bottom
	for y in [-h - r * 0.1, h + r * 0.1]:
		var cap = Rect2(Vector2(-w * 1.25, y - r * 0.11), Vector2(w * 2.5, r * 0.22))
		draw_rect(cap.grow(r * 0.06), INK)
		draw_rect(cap, WOOD)
		draw_rect(Rect2(cap.position, Vector2(cap.size.x, cap.size.y * 0.4)), WOOD.lightened(0.25))
		draw_rect(Rect2(cap.position + Vector2(0, cap.size.y * 0.75), Vector2(cap.size.x, cap.size.y * 0.25)), WOOD_DARK)

# Flair: flips over before the time slows down
func _flair() -> void:
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + PI, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.6, 1.8, 2.0, 0), 0.15)
	await tween.finished
