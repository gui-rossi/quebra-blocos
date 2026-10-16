extends Button

# Flat button that draws a gear icon, so no icon file or font glyph is needed

const TEETH := 8

var icon_color: Color = Color(1, 1, 1, 0.9)

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(80, 80)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var center = size / 2.0
	var r = minf(size.x, size.y) * 0.28
	var color = icon_color.darkened(0.3) if button_pressed else icon_color

	# teeth around the rim
	for i in range(TEETH):
		draw_set_transform(center, i * TAU / TEETH)
		draw_rect(Rect2(-r * 0.24, -r * 1.3, r * 0.48, r * 0.55), color)
	draw_set_transform(Vector2.ZERO, 0.0)

	# thick ring, leaving the hole in the middle
	draw_arc(center, r * 0.72, 0.0, TAU, 32, color, r * 0.58, true)
