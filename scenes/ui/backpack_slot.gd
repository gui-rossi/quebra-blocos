extends Control

# One backpack slot: empty, holding a stored power-up, or locked until a score is reached.
# It has the same fields the drag controller reads from a tray piece (shape_cells, powerup_name, take_powerup(),
# ShapeContainer, ...), so a stored power-up is dragged onto the grid exactly like one from the tray.

const Palette = preload("res://configs/palette.gd")
const NumberFormat = preload("res://configs/number_format.gd")

const GLOW := Color(1.0, 0.82, 0.3)  # border when a power-up can be dropped here
const POWERUP_SIZE_RATIO := 0.55  # power-up body size relative to the slot

var is_backpack_slot := true
var unlock_score: int = 0:
	set(value):
		unlock_score = value
		if _lock_label:
			_lock_label.text = NumberFormat.compact(value)

var locked: bool = false:
	set(value):
		locked = value
		if _lock_label:
			_lock_label.visible = value
		queue_redraw()

# true while a power-up from the tray is being dragged and this slot can take it
var accepting: bool = false:
	set(value):
		accepting = value
		set_process(value)
		queue_redraw()

# true while that power-up is right over this slot
var hovered: bool = false:
	set(value):
		if hovered != value:
			hovered = value
			queue_redraw()

# --- same fields as a tray piece (see randomized_block.gd), read by the drag controller ---
var shape_cells: Array = []:
	set(value):
		shape_cells = value
		queue_redraw()
var powerup_name: String = ""
var piece_color: Color = Color.WHITE
var drag_size_cells: float = 0.0
var drag_alpha: float = 1.0
var body_size: float = 0.0
var container_rest_scale: Vector2 = Vector2.ONE
var container_rest_position: Vector2 = Vector2.ZERO
var powerup_visual: Node2D = null

var shape_container: Node2D
var _lock_label: Label
var _pulse: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

	shape_container = Node2D.new()
	shape_container.name = "ShapeContainer"  # the drag controller looks it up by this name
	add_child(shape_container)

	_lock_label = Label.new()
	_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_lock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_label.visible = locked
	add_child(_lock_label)

	resized.connect(_on_resized)

func is_empty() -> bool:
	return shape_cells.is_empty()

func is_free() -> bool:
	return not locked and is_empty()

# Puts a power-up in the slot (by its key in ShapeDefinitions.POWERUPS)
func store(key: String) -> void:
	var powerup = ShapeDefinitions.get_powerup(key)
	if powerup.is_empty():
		return
	powerup_name = key
	shape_cells = powerup.cells
	drag_size_cells = powerup.drag_size_cells
	drag_alpha = powerup.drag_alpha
	_build_visual()
	_pop(shape_container)

# Hands the power-up's drawing over (to the grid, to play its effect) - this slot is empty after
func take_powerup() -> Node2D:
	var taken = powerup_visual
	powerup_visual = null
	powerup_name = ""
	return taken

# Opens a locked slot with a little pop
func unlock() -> void:
	locked = false
	_pop(self)

func _build_visual() -> void:
	for child in shape_container.get_children():
		child.queue_free()
	powerup_visual = ShapeDefinitions.make_powerup_visual(powerup_name)
	if powerup_visual:
		shape_container.add_child(powerup_visual)
		powerup_visual.fit_to(minf(size.x, size.y) * POWERUP_SIZE_RATIO)
		powerup_visual.start_idle()
		body_size = powerup_visual.diameter

func _on_resized() -> void:
	container_rest_position = size / 2.0
	if shape_container.get_parent() == self:  # not while it's being dragged
		shape_container.position = container_rest_position
	if powerup_visual:
		powerup_visual.fit_to(minf(size.x, size.y) * POWERUP_SIZE_RATIO)
		body_size = powerup_visual.diameter

	var font_size = maxi(10, int(size.y * 0.22))
	_lock_label.add_theme_font_size_override("font_size", font_size)
	_lock_label.add_theme_constant_override("outline_size", maxi(3, int(font_size / 5.0)))
	_lock_label.text = NumberFormat.compact(unlock_score)
	_lock_label.size = Vector2(size.x, font_size * 1.4)
	_lock_label.position = Vector2(0, size.y * 0.66)
	queue_redraw()

func _pop(target: CanvasItem) -> void:
	if target is Control:
		target.pivot_offset = target.size / 2.0
	target.scale = Vector2(0.6, 0.6)
	var tween = create_tween()
	tween.tween_property(target, "scale", Vector2(1.12, 1.12), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var s = minf(size.x, size.y)
	var radius = int(s * 0.22)

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	if locked:
		style.bg_color = Color(0, 0, 0, 0.28)
		style.set_border_width_all(2)
		style.border_color = Color(1, 1, 1, 0.08)
	else:
		style.bg_color = Palette.CELL_EMPTY.lightened(0.12) if hovered else Palette.CELL_EMPTY
		if hovered:
			style.set_border_width_all(4)
			style.border_color = GLOW
		elif accepting:
			style.set_border_width_all(3)
			style.border_color = Color(GLOW, 0.45 + 0.4 * (0.5 + 0.5 * sin(_pulse * 7.0)))
		else:
			style.set_border_width_all(2)
			style.border_color = Color(1, 1, 1, 0.14)
	draw_style_box(style, rect)

	if locked:
		_draw_lock(Vector2(size.x / 2.0, size.y * 0.4), s * 0.2)

# Padlock: a shackle arc on top of a rounded body
func _draw_lock(center: Vector2, unit: float) -> void:
	var color = Color(1, 1, 1, 0.55)
	draw_arc(center + Vector2(0, -unit * 0.15), unit * 0.55, PI, TAU, 24, color, unit * 0.22, true)
	var body = StyleBoxFlat.new()
	body.bg_color = color
	body.set_corner_radius_all(int(unit * 0.25))
	body.anti_aliasing = true
	draw_style_box(body, Rect2(center + Vector2(-unit * 0.8, -unit * 0.15), Vector2(unit * 1.6, unit * 1.15)))
	draw_circle(center + Vector2(0, unit * 0.38), unit * 0.17, Color(0, 0, 0, 0.45))
