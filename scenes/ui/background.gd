extends Control

# Full-screen backdrop: vertical gradient with a few faint, slowly drifting glows

const Palette = preload("res://configs/palette.gd")

# x, y (0..1 of the screen), radius (fraction of screen width), drift speed
const GLOWS := [
	[0.15, 0.18, 0.35, 0.21],
	[0.85, 0.42, 0.45, 0.13],
	[0.3, 0.8, 0.4, 0.17],
]

var _time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Palette.BG_TOP, Palette.BG_TOP, Palette.BG_BOTTOM, Palette.BG_BOTTOM])
	)

	for glow in GLOWS:
		var drift = Vector2(sin(_time * glow[3]), cos(_time * glow[3] * 0.8)) * w * 0.04
		var center = Vector2(glow[0] * w, glow[1] * h) + drift
		var radius = glow[2] * w
		# a few stacked circles fake a soft radial falloff
		for i in range(4):
			draw_circle(center, radius * (1.0 - i * 0.22), Color(0.55, 0.65, 1.0, 0.018))
