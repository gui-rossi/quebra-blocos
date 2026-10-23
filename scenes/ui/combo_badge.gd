extends Control

# Score multiplier badge: "x3" inside a ring that empties as the combo time runs out.
# Gets hotter (yellow to red) as the multiplier grows, and from GameConfig.fire_multiplier (x5) the number sits in a
# flame inside the ring (orange outside, yellow core), growing up to GameConfig.max_score_multiplier (x10). The
# number turns a cool white with a thick dark outline so it stands out from the fire, and the flame stays inside the
# ring so the combo timer is never covered.

const RING_RATIO := 0.08  # ring width, relative to the badge's size (same as the settings button)

# Font size relative to the badge's size, by how many characters "xN" has, so bigger numbers still fit in the circle
const FONT_RATIOS := {2: 0.34, 3: 0.28, 4: 0.22}
const FONT_RATIO_MIN := 0.18

var _fraction: float = 1.0  # combo time left, 0..1
var _multiplier: int = 1
var _label: Label
var _pop_tween: Tween
var _slowed: bool = false  # the hourglass is slowing the timer down
var _fire_time: float = 0.0  # drives the flames' flicker

# Flame colors, outside to inside, and the number's color while it's on fire (cool, to contrast with them)
const FIRE_OUTER := Color(1.0, 0.42, 0.0)
const FIRE_MID := Color(1.0, 0.56, 0.18)
const FIRE_INNER := Color(1.0, 0.79, 0.0)
const FIRE_TEXT := Color(0.9, 0.97, 1.0)
const FIRE_TEXT_OUTLINE := Color(0.08, 0.04, 0.12, 0.95)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	set_process(false)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	add_child(_label)

	resized.connect(_update_font)
	resized.connect(queue_redraw)

func set_multiplier(value: int) -> void:
	var rising = value > _multiplier
	_multiplier = value
	_label.text = "x%d" % value
	var on_fire = _fire_intensity() >= 0.0
	_label.add_theme_color_override("font_color", FIRE_TEXT if on_fire else _heat_color())
	_label.add_theme_color_override("font_outline_color", FIRE_TEXT_OUTLINE if on_fire else Color(0, 0, 0, 0.7))
	_update_font()
	_fraction = 1.0
	set_process(_fire_intensity() >= 0.0)
	queue_redraw()

	if rising:
		_pop()

func set_time_fraction(value: float) -> void:
	_fraction = clampf(value, 0.0, 1.0)
	queue_redraw()

func set_slowed(active: bool) -> void:
	_slowed = active
	queue_redraw()

# Fades out and goes back to x1
func hide_badge() -> void:
	_multiplier = 1
	set_process(false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)

func _update_font() -> void:
	var ratio = FONT_RATIOS.get(_label.text.length(), FONT_RATIO_MIN)
	var font_size = maxi(10, int(minf(size.x, size.y) * ratio))
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_constant_override("outline_size", maxi(4, int(font_size / (3.2 if _fire_intensity() >= 0.0 else 5.0))))

func _pop() -> void:
	pivot_offset = size / 2.0
	if _pop_tween:
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "modulate:a", 1.0, 0.08)
	_pop_tween.parallel().tween_property(self, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)

func _heat_color() -> Color:
	# x2 is yellow, x8 and up is red
	var heat = clampf((_multiplier - 2) / 6.0, 0.0, 1.0)
	return Color.from_hsv(lerpf(0.15, 0.0, heat), 0.85, 1.0)

func _process(delta: float) -> void:
	_fire_time += delta
	queue_redraw()

# -1 below the fire threshold, then 0 at x5 up to 1 at the max multiplier
func _fire_intensity() -> float:
	if _multiplier < GameConfig.fire_multiplier:
		return -1.0
	var span = maxf(1.0, float(GameConfig.max_score_multiplier - GameConfig.fire_multiplier))
	return clampf((_multiplier - GameConfig.fire_multiplier) / span, 0.0, 1.0)

# One stylized flame behind the number, inside the ring: a round base, a tall tongue leaning a little to the right
# and two small flicks on the sides, in three layers (orange, light orange, a yellow core). It gets bigger as the
# intensity grows and flickers gently; the tip stays inside `inner` (the ring's inner edge).
func _draw_fire(center: Vector2, inner: float, intensity: float) -> void:
	var t = _fire_time
	draw_circle(center, inner * (0.7 + 0.2 * intensity), Color(1.0, 0.45, 0.05, 0.12 + 0.18 * intensity))

	var h = inner * (1.2 + 0.25 * intensity)  # flame height: at x10 with the flicker, the tip still clears the ring
	var bottom = center + Vector2(0, h * 0.5 + inner * 0.02)  # the flame grows up from its bottom
	var stretch = 1.0 + 0.05 * sin(t * 8.0) + 0.03 * sin(t * 19.0)
	var sway = 0.04 * sin(t * 5.0) + 0.02 * sin(t * 13.0)

	for layer in [[FIRE_OUTER, 1.0, true], [FIRE_MID, 0.74, true], [FIRE_INNER, 0.44, false]]:
		var k: float = layer[1]
		for piece in _flame_pieces(layer[2]):
			var points = PackedVector2Array()
			for p in piece:
				# unit flame: bottom at y = 0.5, tip at y = -0.5; the top sways more than the base
				var y = (p.y - 0.5) * k * stretch
				var x = p.x * k + sway * -y
				points.append(bottom + Vector2(x, y) * h)
			draw_colored_polygon(points, layer[0])

# The flame's parts in unit coordinates (1 tall, bottom at y = 0.5), drawn in the same color so they read as one shape
func _flame_pieces(with_flicks: bool) -> Array:
	var pieces = []
	pieces.append(_circle_points(Vector2(0, 0.2), 0.3, 20))  # round base
	# main tongue: up the left side to the tip, slightly right of centre, and back down the right side
	var tongue = _bezier(Vector2(-0.3, 0.2), Vector2(-0.3, -0.18), Vector2(0.05, -0.5), 10)
	tongue.append_array(_bezier(Vector2(0.05, -0.5), Vector2(0.33, -0.12), Vector2(0.3, 0.2), 10))
	pieces.append(tongue)
	if with_flicks:
		# a small flick on the upper right and one on the left
		pieces.append(PackedVector2Array([Vector2(0.13, -0.08), Vector2(0.21, -0.2), Vector2(0.25, -0.31), Vector2(0.3, -0.13), Vector2(0.3, 0.06)]))
		pieces.append(PackedVector2Array([Vector2(-0.29, 0.16), Vector2(-0.33, 0.0), Vector2(-0.3, -0.1), Vector2(-0.22, -0.01), Vector2(-0.18, 0.12)]))
	return pieces

func _circle_points(c: Vector2, r: float, steps: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in steps:
		var a = TAU * i / steps
		points.append(c + Vector2(cos(a), sin(a)) * r)
	return points

# Quadratic bezier from a to c with control b, as `steps` + 1 points
func _bezier(a: Vector2, b: Vector2, c: Vector2, steps: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in steps + 1:
		var u = float(i) / steps
		points.append(a.lerp(b, u).lerp(b.lerp(c, u), u))
	return points

func _draw() -> void:
	var center = size / 2.0
	var s = minf(size.x, size.y)
	var ring = s * RING_RATIO
	var radius = s / 2.0 - ring
	draw_circle(center, radius + ring / 2.0, Color(0, 0, 0, 0.35))
	# the fire goes on top of the disc but under the ring and the number (the label is a child, drawn after this)
	var fire = _fire_intensity()
	if fire >= 0.0:
		_draw_fire(center, radius - ring * 0.9, fire)
	draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.12), ring, true)
	if _fraction > 0.0:
		# starts at the top and empties clockwise
		var ring_color = Color(0.55, 0.82, 1.0) if _slowed else _heat_color()
		draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * _fraction, 64, ring_color, ring, true)
