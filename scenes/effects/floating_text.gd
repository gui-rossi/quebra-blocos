extends Node2D

# Text that pops in, floats up and fades out (score gains, combo banners). Frees itself when done.

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 40
var rise: float = 90.0  # how far it floats up, in pixels
var duration: float = 0.9

func play() -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("outline_size", maxi(6, int(font_size / 5.0)))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.reset_size()
	label.position = -label.size / 2.0  # centered on this node
	label.pivot_offset = label.size / 2.0

	scale = Vector2(0.4, 0.4)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(self, "position:y", position.y - rise, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(duration - 0.3)
	tween.tween_callback(queue_free)
