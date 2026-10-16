@tool
extends Control

# Draws one block: a beveled, glossy tile in `color`, or a recessed empty cell when `empty`

const Palette = preload("res://configs/palette.gd")

@export var color: Color = Color(0.27, 0.5, 0.96):
	set(value):
		color = value
		queue_redraw()

@export var empty: bool = false:
	set(value):
		empty = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var s = minf(size.x, size.y)
	if s <= 0.0:
		return
	var radius = maxf(2.0, s * 0.16)

	if empty:
		_rounded(rect, Palette.CELL_EMPTY, radius)
		# darker upper edge, so the cell looks sunk into the board
		_rounded(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.55)), Color(0, 0, 0, 0.14), radius)
		_rounded(rect.grow(-s * 0.08), Palette.CELL_EMPTY, radius * 0.8)
		return

	var bevel = maxf(1.0, s * 0.12)
	# dark lower/right edge, then the light upper/left edge on top of it
	_rounded(rect, color.darkened(0.42), radius)
	_rounded(Rect2(rect.position, rect.size - Vector2(bevel, bevel) * 0.8), color.lightened(0.32), radius)
	# the face
	var face = rect.grow(-bevel)
	_rounded(face, color, radius * 0.65)
	# gloss across the top half of the face and a small shine in the corner
	_rounded(Rect2(face.position, Vector2(face.size.x, face.size.y * 0.45)), Color(1, 1, 1, 0.16), radius * 0.65)
	draw_circle(face.position + face.size * 0.24, s * 0.065, Color(1, 1, 1, 0.5))

func _rounded(rect: Rect2, fill: Color, radius: float) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	draw_style_box(style, rect)
