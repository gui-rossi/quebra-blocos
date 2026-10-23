extends Control

# Trash can at the end of the backpack bar. Drop any power-up on it (from the tray or the backpack) to get rid of it
# and get its ShapeDefinitions "trash_score" in points. It glows while a power-up is dragged, and its lid opens
# when the power-up is right over it.

const Palette = preload("res://configs/palette.gd")

const GLOW := Color(1.0, 0.82, 0.3)  # same as the backpack slots
const METAL := Color(0.62, 0.68, 0.82)
const METAL_DARK := Color(0.36, 0.41, 0.56)
const INK := Color(0.04, 0.05, 0.13, 0.85)

# true while a power-up is being dragged
var accepting: bool = false:
	set(value):
		accepting = value
		set_process(value or _lid < 1.0)
		queue_redraw()

# true while that power-up is right over the trash can
var hovered: bool = false:
	set(value):
		if hovered != value:
			hovered = value
			set_process(true)
			queue_redraw()

var _pulse: float = 0.0
var _lid: float = 1.0  # 1 closed, 0 fully open (eased towards the hovered state)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	resized.connect(queue_redraw)

# A short gulp when something lands in it
func swallow() -> void:
	pivot_offset = size / 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 0.88), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_pulse += delta
	var target = 0.0 if hovered else 1.0
	_lid = move_toward(_lid, target, delta * 8.0)
	if not accepting and not hovered and _lid >= 1.0:
		set_process(false)
	queue_redraw()

func _draw() -> void:
	var s = minf(size.x, size.y)

	# the same rounded tile as a slot, so it reads as part of the bar
	var tile = StyleBoxFlat.new()
	tile.set_corner_radius_all(int(s * 0.22))
	tile.anti_aliasing = true
	tile.bg_color = Palette.CELL_EMPTY.lightened(0.12) if hovered else Palette.CELL_EMPTY
	if hovered:
		tile.set_border_width_all(4)
		tile.border_color = GLOW
	elif accepting:
		tile.set_border_width_all(3)
		tile.border_color = Color(GLOW, 0.45 + 0.4 * (0.5 + 0.5 * sin(_pulse * 7.0)))
	else:
		tile.set_border_width_all(2)
		tile.border_color = Color(1, 1, 1, 0.14)
	draw_style_box(tile, Rect2(Vector2.ZERO, size))

	var c = size / 2.0
	var u = s * 0.1  # one unit of the drawing
	var alpha = 1.0 if accepting or hovered else 0.7

	# bin body: slightly narrower at the bottom, with three grooves
	var top_w = u * 3.4
	var bottom_w = u * 2.7
	var body_top = c.y - u * 1.2
	var body_bottom = c.y + u * 2.7
	var body = PackedVector2Array([
		Vector2(c.x - top_w / 2.0, body_top), Vector2(c.x + top_w / 2.0, body_top),
		Vector2(c.x + bottom_w / 2.0, body_bottom), Vector2(c.x - bottom_w / 2.0, body_bottom),
	])
	draw_colored_polygon(_grow(body, u * 0.28), Color(INK, INK.a * alpha))
	draw_colored_polygon(body, Color(METAL_DARK, alpha))
	var face = PackedVector2Array([body[0] + Vector2(u * 0.2, 0), body[1] - Vector2(u * 0.9, 0), body[2] - Vector2(u * 0.75, 0), body[3] + Vector2(u * 0.15, 0)])
	draw_colored_polygon(face, Color(METAL, alpha))
	for i in [-1, 0, 1]:
		var x = c.x + i * u * 0.85
		draw_line(Vector2(x, body_top + u * 0.6), Vector2(x * 0.98 + c.x * 0.02, body_bottom - u * 0.5), Color(METAL_DARK.darkened(0.2), alpha), maxf(1.5, u * 0.3), true)

	# lid, hinged on its right end: it swings up when a power-up hovers over the bin
	var hinge = Vector2(c.x + top_w / 2.0 + u * 0.2, body_top - u * 0.35)
	var angle = lerpf(-0.75, 0.0, _lid)
	var lid_w = top_w + u * 0.8
	var lid_h = u * 0.6
	var lid = PackedVector2Array([Vector2(-lid_w, -lid_h / 2.0), Vector2(0, -lid_h / 2.0), Vector2(0, lid_h / 2.0), Vector2(-lid_w, lid_h / 2.0)])
	var handle = PackedVector2Array([Vector2(-lid_w * 0.62, -lid_h / 2.0), Vector2(-lid_w * 0.38, -lid_h / 2.0), Vector2(-lid_w * 0.38, -lid_h / 2.0 - u * 0.55), Vector2(-lid_w * 0.62, -lid_h / 2.0 - u * 0.55)])
	draw_set_transform(hinge, angle, Vector2.ONE)
	draw_colored_polygon(_grow(handle, u * 0.22), Color(INK, INK.a * alpha))
	draw_colored_polygon(_grow(lid, u * 0.28), Color(INK, INK.a * alpha))
	draw_colored_polygon(handle, Color(METAL_DARK, alpha))
	draw_colored_polygon(lid, Color(METAL.lightened(0.15), alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# The polygon pushed out by `amount` from its centre (for outlines)
func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center = Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	var grown = PackedVector2Array()
	for p in points:
		var dir = p - center
		var scale_by = (dir.length() + amount) / maxf(dir.length(), 0.001)
		grown.append(center + dir * scale_by)
	return grown
