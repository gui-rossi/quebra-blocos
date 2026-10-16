extends Button

# Round "previous" / "next" button for the music player, with a drawn icon (no font glyphs needed)

enum Kind { PREVIOUS, NEXT }

var kind: Kind = Kind.NEXT

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(76, 76)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	button_down.connect(func():
		Sfx.play("click")
		Settings.vibrate(5)
	)

func _draw() -> void:
	var center = size / 2.0
	var s = minf(size.x, size.y)
	draw_circle(center, s / 2.0 - 2.0, Color(1, 1, 1, 0.16) if button_pressed else Color(1, 1, 1, 0.08))

	var color = Color(1, 1, 1, 0.65) if button_pressed else Color(1, 1, 1, 0.92)
	var h = s * 0.16  # half height of the icon
	var dir = 1.0 if kind == Kind.NEXT else -1.0

	# two triangles pointing the same way, then a bar at the tip: ▶▶| or |◀◀
	for i in range(2):
		var base_x = center.x + dir * (-h * 1.1 + i * h * 1.0)
		var tip_x = base_x + dir * h
		draw_colored_polygon(PackedVector2Array([
			Vector2(base_x, center.y - h), Vector2(tip_x, center.y), Vector2(base_x, center.y + h)
		]), color)
	var bar_x = center.x + dir * (h * 0.95)
	var bar_width = h * 0.22
	draw_rect(Rect2(bar_x if dir > 0 else bar_x - bar_width, center.y - h, bar_width, h * 2.0), color)
