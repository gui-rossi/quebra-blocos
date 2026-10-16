extends Control

# Score multiplier badge: "x3" inside a ring that empties as the combo time runs out.
# Gets hotter (yellow to red) as the multiplier grows.

const RING_RATIO := 0.08  # ring width, relative to the badge's size (same as the settings button)

# Font size relative to the badge's size, by how many characters "xN" has, so bigger numbers still fit in the circle
const FONT_RATIOS := {2: 0.34, 3: 0.28, 4: 0.22}
const FONT_RATIO_MIN := 0.18

var _fraction: float = 1.0  # combo time left, 0..1
var _multiplier: int = 1
var _label: Label
var _pop_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0

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
	queue_redraw()

	if rising:
		_pop()

func set_time_fraction(value: float) -> void:
	_fraction = clampf(value, 0.0, 1.0)
	queue_redraw()

# Fades out and goes back to x1
func hide_badge() -> void:
	_multiplier = 1
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

func _draw() -> void:
	var center = size / 2.0
	var s = minf(size.x, size.y)
	var ring = s * RING_RATIO
	var radius = s / 2.0 - ring
	draw_circle(center, radius + ring / 2.0, Color(0, 0, 0, 0.35))
	draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.12), ring, true)
	if _fraction > 0.0:
		# starts at the top and empties clockwise
		draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * _fraction, 64, _heat_color(), ring, true)
