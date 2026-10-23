extends Control

# Score multiplier badge: "x3" inside a ring that empties as the combo time runs out.
# Gets hotter (yellow to red) as the multiplier grows, and from GameConfig.fire_multiplier (x5) the number sits in a
# small fire inside the ring, burning brighter up to GameConfig.max_score_multiplier (x10). The fire stays inside the
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

# Fire colors, outside to inside
const FIRE_OUTER := Color(0.95, 0.25, 0.08, 0.85)
const FIRE_MID := Color(1.0, 0.55, 0.1, 0.9)
const FIRE_INNER := Color(1.0, 0.88, 0.35, 0.95)

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
	_label.add_theme_color_override("font_color", _heat_color())
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
	_label.add_theme_constant_override("outline_size", maxi(4, int(font_size / 5.0)))

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

# A small fire behind the number, inside the ring: a warm glow and a few flame tongues rising from under the digits.
# More and taller tongues as the intensity grows, but the tips always stay inside `inner` (the ring's inner edge).
func _draw_fire(center: Vector2, inner: float, intensity: float) -> void:
	var t = _fire_time
	draw_circle(center, inner * (0.6 + 0.25 * intensity), Color(1.0, 0.42, 0.08, 0.16 + 0.24 * intensity))

	var count = 3 + int(round(2.0 * intensity))
	var span = inner * (0.9 + 0.35 * intensity)  # how wide the row of flames is
	var base_y = center.y + inner * 0.42
	var height = inner * (0.55 + 0.5 * intensity)
	for layer in [[FIRE_OUTER, 1.0], [FIRE_MID, 0.72], [FIRE_INNER, 0.45]]:
		for i in count:
			var offset = -span / 2.0 + (i + 0.5) * span / count  # from the centre line
			var up = Vector2(-offset / span * 0.4, -1.0).normalized()  # outer tongues lean in a little
			var flicker = 0.85 + 0.15 * sin(t * 9.0 + i * 1.7) + 0.06 * sin(t * 23.0 + i * 3.1)
			var tall = 1.0 - 0.4 * absf(offset) / (span / 2.0)  # the middle burns tallest
			var h = height * tall * flicker * layer[1]
			var w = span / count * 1.5 * layer[1]
			_draw_flame(Vector2(center.x + offset, base_y), up, h, w, sin(t * 6.0 + i * 2.2) * w * 0.25, layer[0])

# One tongue of fire: wide at `base`, narrowing to a point `height` along `up`, the tip swaying sideways
func _draw_flame(base: Vector2, up: Vector2, height: float, width: float, sway: float, color: Color) -> void:
	var side = Vector2(-up.y, up.x)
	var left = PackedVector2Array()
	var right = PackedVector2Array()
	var steps = 8
	for k in steps + 1:
		var v = float(k) / steps
		var half = width * 0.5 * pow(1.0 - v, 0.8) * (1.0 + 0.25 * sin(v * PI))
		var mid = base + up * height * v + side * sway * v * v
		left.append(mid - side * half)
		right.append(mid + side * half)
	right.reverse()
	draw_colored_polygon(left + right, color)

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
