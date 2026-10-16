extends Button

# Round settings button with a drawn gear, so no icon file or font glyph is needed.
# Uses the same dark disc and faint ring as the combo badge, so the two sides of the top tray match.

const TEETH := 8
const RING_RATIO := 0.08  # ring width, relative to the button's size (same as the combo badge)

var icon_color: Color = Color(1, 1, 1, 0.9)

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)

func _draw() -> void:
	var center = size / 2.0
	var s = minf(size.x, size.y)
	var ring = s * RING_RATIO
	var disc_radius = s / 2.0 - ring
	draw_circle(center, disc_radius + ring / 2.0, Color(0, 0, 0, 0.35))
	draw_arc(center, disc_radius, 0.0, TAU, 64, Color(1, 1, 1, 0.12), ring, true)

	var r = s * 0.2
	var color = icon_color.darkened(0.3) if button_pressed else icon_color

	# teeth around the rim
	for i in range(TEETH):
		draw_set_transform(center, i * TAU / TEETH)
		draw_rect(Rect2(-r * 0.24, -r * 1.3, r * 0.48, r * 0.55), color)
	draw_set_transform(Vector2.ZERO, 0.0)

	# thick ring, leaving the hole in the middle
	draw_arc(center, r * 0.72, 0.0, TAU, 48, color, r * 0.58, true)
