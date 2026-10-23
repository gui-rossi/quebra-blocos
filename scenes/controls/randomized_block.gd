extends Node2D

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
const Palette = preload("res://configs/palette.gd")

const MERGE_GLOW := Color(1.0, 0.82, 0.3)  # ring while a power-up of the same type is dragged (same as the backpack's)

@onready var circle_sprite: Sprite2D = $Sprite2D
@onready var shape_container: Node2D = $ShapeContainer

var shape_cells: Array = []:
	set(value):
		shape_cells = value
		queue_redraw()  # the slot looks different once its piece is used
var piece_color: Color = Color.DARK_GREEN
var shape_name: String = ""  # key in ShapeDefinitions.SHAPES, "" for a power-up
var powerup_name: String = ""  # key in ShapeDefinitions.POWERUPS, "" for a regular shape
var powerup_visual: Node2D = null  # the power-up's drawing, while this slot holds one

# How the piece looks while dragged
var drag_size_cells: float = 0.0  # > 0 resizes its body to this many grid cells wide, 0 keeps the tray size
var drag_alpha: float = ShapeDefinitions.SHAPE_DRAG_ALPHA
var body_size: float = 0.0  # width of its body, in the shape container's local units
# Scale the shape container goes back to after a drag. The container undoes this slot's scale-up, so the
# piece is drawn at its real on-screen size instead of drawn tiny and stretched (which made it blurry)
var container_rest_scale: Vector2 = Vector2.ONE
var container_rest_position: Vector2 = Vector2.ZERO  # where the container sits when it's back in the slot

# Merging: the same power-up dragged onto this one makes its mega version
var merge_ready: bool = false:  # a power-up it can merge with is being dragged: the ring pulses
	set(value):
		merge_ready = value
		set_process(value)
		queue_redraw()
var merge_hovered: bool = false:  # ...and it's right over this slot: the ring lights up
	set(value):
		if merge_hovered != value:
			merge_hovered = value
			queue_redraw()
var _pulse: float = 0.0

func _ready() -> void:
	# the circle texture is only kept for sizing and touch detection, _draw paints the slot
	circle_sprite.visible = false
	set_process(false)

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

# Soft round slot under the piece, fainter once its piece has been used
func _draw() -> void:
	# drawn in screen pixels (undoing the slot's scale-up) so the ring's edge stays sharp
	var k = _screen_scale()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / k)
	var radius = circle_sprite.texture.get_size().x / 2.0 * 0.9 * k
	var center = circle_sprite.position * k
	var strength = 1.0 if not shape_cells.is_empty() else 0.5
	draw_circle(center, radius, Color(Palette.SLOT_FILL, Palette.SLOT_FILL.a * strength))
	draw_arc(center, radius, 0.0, TAU, 96, Color(Palette.SLOT_RING, Palette.SLOT_RING.a * strength), 3.0, true)
	if merge_hovered:
		draw_arc(center, radius, 0.0, TAU, 96, MERGE_GLOW, 6.0, true)
	elif merge_ready:
		draw_arc(center, radius, 0.0, TAU, 96, Color(MERGE_GLOW, 0.45 + 0.4 * (0.5 + 0.5 * sin(_pulse * 7.0))), 4.0, true)

# Dims the piece when it can't fit anywhere on the board
func set_playable(playable: bool) -> void:
	var tint = Color.WHITE if playable else Palette.PIECE_UNPLAYABLE
	shape_container.modulate = Color(tint, shape_container.modulate.a)

# `allow_powerup` is false once another slot of the same batch already got a power-up
func randomize_shape(allow_powerup: bool = true) -> void:
	var rolled_powerup = ShapeDefinitions.roll_powerup_name() if allow_powerup else ""
	if rolled_powerup != "":
		_apply_powerup(rolled_powerup)
		return

	_apply_shape("square_3x3")
	return

	_apply_shape(ShapeDefinitions.get_random_shape_name())

# The slot as plain data, for saving
func to_save() -> Dictionary:
	return {
		"used": shape_cells.is_empty(),
		"shape": shape_name,
		"powerup": powerup_name,
		"color": piece_color.to_html(true),
	}

# Rebuilds the slot from to_save() data (call build_piece after, unless it's used)
func set_from_save(slot: Dictionary) -> void:
	if slot.get("used", true):
		shape_cells = []
		shape_name = ""
		powerup_name = ""
		return

	if slot.get("powerup", "") != "":
		_apply_powerup(slot.powerup)
	else:
		_apply_shape(slot.get("shape", ""))
		piece_color = Color.html(slot.get("color", piece_color.to_html(true)))

func _apply_powerup(key: String) -> void:
	var powerup = ShapeDefinitions.get_powerup(key)
	powerup_name = key
	shape_name = ""
	shape_cells = powerup.cells
	drag_size_cells = powerup.drag_size_cells
	drag_alpha = powerup.drag_alpha

func _apply_shape(key: String) -> void:
	shape_name = key
	powerup_name = ""
	shape_cells = ShapeDefinitions.get_shape(key)
	piece_color = Palette.PIECE_COLORS.pick_random()
	# shown at grid size while dragged, so it matches the cells it will land on
	var widest := 0
	for cell in shape_cells:
		widest = maxi(widest, cell.x + 1)
	drag_size_cells = widest
	drag_alpha = ShapeDefinitions.SHAPE_DRAG_ALPHA

func build_piece(shape_scale_factor: float = 1.0) -> void:
	for child in shape_container.get_children():
		child.queue_free()
	powerup_visual = null

	# k = how much this slot is scaled up on screen, the container's contents are built k times bigger
	var k = _screen_scale()
	container_rest_scale = Vector2.ONE / k
	shape_container.scale = container_rest_scale
	queue_redraw()  # the slot ring follows the same scale

	if powerup_name != "":
		_build_powerup(k)
		return

	var size = GameConfig.cell_size * shape_scale_factor * k
	var gap = GameConfig.cell_gap * shape_scale_factor * k

	var min_x = shape_cells[0].x
	var max_x = shape_cells[0].x
	var min_y = shape_cells[0].y
	var max_y = shape_cells[0].y
	for cell in shape_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	var shape_width = (max_x - min_x + 1) * size
	var shape_height = (max_y - min_y + 1) * size
	var circle_center = circle_sprite.position * k
	body_size = shape_width

	for cell in shape_cells:
		var tile = BLOCK_SPACE_SCENE.instantiate()
		shape_container.add_child(tile)
		tile.block_size = Vector2(size - gap, size - gap)
		tile.block_color = piece_color

		var local_x = (cell.x - min_x) * size - shape_width / 2.0
		var local_y = (cell.y - min_y) * size - shape_height / 2.0
		tile.position = circle_center + Vector2(local_x, local_y)

func _build_powerup(k: float) -> void:
	powerup_visual = ShapeDefinitions.make_powerup_visual(powerup_name)
	shape_container.add_child(powerup_visual)
	powerup_visual.position = circle_sprite.position * k
	powerup_visual.fit_to(circle_sprite.texture.get_size().x * ShapeDefinitions.get_powerup(powerup_name).tray_size_ratio * k)
	powerup_visual.start_idle()
	body_size = powerup_visual.diameter

# How much this slot is scaled up on screen (set by the bottom tray's scale_randomized_blocks)
func _screen_scale() -> float:
	return maxf(get_global_transform().get_scale().x, 0.001)

# Turns the power-up into `key` (its mega version, after a merge) with a little pop
func upgrade_powerup(key: String) -> void:
	_apply_powerup(key)
	build_piece()
	shape_container.scale = container_rest_scale * 0.6
	var tween = create_tween()
	tween.tween_property(shape_container, "scale", container_rest_scale * 1.15, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(shape_container, "scale", container_rest_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Hands the power-up's drawing over (to the grid, to play its effect) - this piece no longer holds a power-up
func take_powerup() -> Node2D:
	var taken = powerup_visual
	powerup_visual = null
	powerup_name = ""
	return taken
