extends Node2D

# What makes a mega power-up look mega: a pulsing golden glow with sparkles circling behind it, and a small gold star
# badge in front. Two of these (`front` false and true) are added to any power-up visual by
# ShapeDefinitions.make_powerup_visual (the sprite ones and the bomb scene alike). They size themselves from the
# visual's `diameter` every frame, so they follow fit_to() and the drag resize.

const GOLD := Color(1.0, 0.8, 0.25)
const GOLD_LIGHT := Color(1.0, 0.95, 0.7)
const INK := Color(0.12, 0.06, 0.04)
const SPARKLES := 6
const SPIN_SPEED := 1.4  # radians per second

var front: bool = false  # false: the glow behind the power-up, true: the badge over it
var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var parent = get_parent()
	var r: float = parent.diameter / 2.0 if parent and "diameter" in parent else 32.0
	if front:
		_draw_badge(Vector2(r * 0.72, r * 0.62), r * 0.3)
		return

	var pulse = 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(Vector2.ZERO, r * (1.3 + 0.06 * pulse), Color(GOLD, 0.10 + 0.06 * pulse))
	draw_circle(Vector2.ZERO, r * 1.12, Color(GOLD, 0.16 + 0.08 * pulse))
	draw_arc(Vector2.ZERO, r * 1.2, 0.0, TAU, 48, Color(GOLD_LIGHT, 0.35 + 0.25 * pulse), maxf(1.5, r * 0.05), true)

	# sparkles circling around it, twinkling one after the other
	for i in SPARKLES:
		var angle = _time * SPIN_SPEED + i * TAU / SPARKLES
		var twinkle = 0.5 + 0.5 * sin(_time * 6.0 + i * 1.7)
		_draw_sparkle(Vector2.from_angle(angle) * r * 1.3, r * (0.1 + 0.08 * twinkle), Color(GOLD_LIGHT, 0.55 + 0.45 * twinkle))

# A four-pointed sparkle
func _draw_sparkle(center: Vector2, size: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in 8:
		var length = size if i % 2 == 0 else size * 0.3
		points.append(center + Vector2.from_angle(i * PI / 4.0 - PI / 2.0) * length)
	draw_colored_polygon(points, color)

# A gold star with a dark outline, like the sprites have
func _draw_badge(center: Vector2, radius: float) -> void:
	var star = PackedVector2Array()
	for i in 10:
		var length = radius if i % 2 == 0 else radius * 0.48
		star.append(center + Vector2.from_angle(i * PI / 5.0 - PI / 2.0) * length)
	var outline = star.duplicate()
	outline.append(star[0])
	draw_polyline(outline, INK, maxf(2.0, radius * 0.28), true)
	draw_colored_polygon(star, GOLD)
	# lighter top-left half for some volume
	var light = PackedVector2Array([center, star[6], star[7], star[8], star[9], star[0]])
	draw_colored_polygon(light, GOLD_LIGHT.lerp(GOLD, 0.4))
