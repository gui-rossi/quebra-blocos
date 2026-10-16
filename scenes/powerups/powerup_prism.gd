extends "res://scenes/powerups/powerup_visual.gd"

# Prism: a hexagonal gem with a facet in each block color, it clears every block of the color it lands on

const Palette = preload("res://configs/palette.gd")

func _draw_icon(r: float) -> void:
	var hex = PackedVector2Array()
	for i in range(6):
		var a = -PI / 2.0 + i * TAU / 6.0
		hex.append(Vector2(cos(a), sin(a)) * r * 0.92)

	# halo and outline
	draw_circle(Vector2.ZERO, r * 1.1, Color(1, 1, 1, 0.05 + 0.06 * glow))
	_polygon(hex, INK, r * 0.2)

	# one facet per color: a triangle from the centre to each side
	var colors = [0, 1, 2, 3, 5, 6]  # red, orange, yellow, green, blue, purple from the palette
	for i in range(6):
		var facet = PackedVector2Array([Vector2.ZERO, hex[i], hex[(i + 1) % 6]])
		var col: Color = Palette.PIECE_COLORS[colors[i]]
		# facets facing the upper left catch more light
		var facing = Vector2.from_angle(-PI / 2.0 + (i + 0.5) * TAU / 6.0).dot(Vector2(-0.6, -0.8))
		draw_colored_polygon(facet, col.lightened(0.25 * maxf(facing, 0.0)).darkened(0.25 * maxf(-facing, 0.0)))

	# bright table in the middle, facet lines and a sparkle
	var table = PackedVector2Array()
	for i in range(6):
		table.append(hex[i] * 0.42)
	draw_colored_polygon(table, Color(1, 1, 1, 0.55 + 0.25 * glow))
	for i in range(6):
		draw_line(table[i], hex[i], Color(1, 1, 1, 0.35), maxf(1.0, r * 0.04), true)
	var sparkle = _star_points(r * (0.3 + 0.06 * glow), r * 0.06, 4, 0.0)
	for i in range(sparkle.size()):
		sparkle[i] += Vector2(-r * 0.4, -r * 0.42)
	draw_colored_polygon(sparkle, Color.WHITE)

# Flair: a quick spin while it flashes
func _flair() -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "rotation", rotation + TAU, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", scale * 1.4, 0.3)
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.3).set_delay(0.1)
	await tween.finished
