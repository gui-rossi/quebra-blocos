extends Node2D

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
const BOMB_SCENE: PackedScene = preload("res://scenes/powerups/powerup_bomb.tscn")
const Palette = preload("res://configs/palette.gd")

@onready var circle_sprite: Sprite2D = $Sprite2D
@onready var shape_container: Node2D = $ShapeContainer

var shape_cells: Array = []:
	set(value):
		shape_cells = value
		queue_redraw()  # the slot looks different once its piece is used
var piece_color: Color = Color.DARK_GREEN
var shape_name: String = ""  # key in ShapeDefinitions.SHAPES, "" for a power-up
var powerup_name: String = ""  # key in ShapeDefinitions.POWERUPS, "" for a regular shape
var is_bomb: bool = false
var bomb: Node2D = null

# How the piece looks while dragged
var drag_size_cells: float = 0.0  # > 0 resizes its body to this many grid cells wide, 0 keeps the tray size
var drag_alpha: float = ShapeDefinitions.SHAPE_DRAG_ALPHA
var body_size: float = 0.0  # width of its body, in the shape container's local units
# Scale the shape container goes back to after a drag. The container undoes this slot's scale-up, so the
# piece is drawn at its real on-screen size instead of drawn tiny and stretched (which made it blurry)
var container_rest_scale: Vector2 = Vector2.ONE
var container_rest_position: Vector2 = Vector2.ZERO  # where the container sits when it's back in the slot

func _ready() -> void:
	# the circle texture is only kept for sizing and touch detection, _draw paints the slot
	circle_sprite.visible = false

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

# Dims the piece when it can't fit anywhere on the board
func set_playable(playable: bool) -> void:
	var tint = Color.WHITE if playable else Palette.PIECE_UNPLAYABLE
	shape_container.modulate = Color(tint, shape_container.modulate.a)

func randomize_shape() -> void:
	var rolled_powerup = ShapeDefinitions.roll_powerup_name()
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
		is_bomb = false
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
	is_bomb = key == "bomb"
	shape_cells = powerup.cells
	drag_size_cells = powerup.drag_size_cells
	drag_alpha = powerup.drag_alpha

func _apply_shape(key: String) -> void:
	shape_name = key
	powerup_name = ""
	is_bomb = false
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
	bomb = null

	# k = how much this slot is scaled up on screen, the container's contents are built k times bigger
	var k = _screen_scale()
	container_rest_scale = Vector2.ONE / k
	shape_container.scale = container_rest_scale
	queue_redraw()  # the slot ring follows the same scale

	if is_bomb:
		_build_bomb(k)
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

func _build_bomb(k: float) -> void:
	bomb = BOMB_SCENE.instantiate()
	shape_container.add_child(bomb)
	bomb.position = circle_sprite.position * k
	bomb.fit_to(circle_sprite.texture.get_size().x * ShapeDefinitions.get_powerup("bomb").tray_size_ratio * k)
	bomb.start_idle()
	body_size = bomb.diameter

# How much this slot is scaled up on screen (set by the bottom tray's scale_randomized_blocks)
func _screen_scale() -> float:
	return maxf(get_global_transform().get_scale().x, 0.001)

# Hands the bomb over (e.g. to the grid, to explode) - this piece no longer owns it
func take_bomb() -> Node2D:
	var taken = bomb
	bomb = null
	is_bomb = false
	powerup_name = ""
	return taken
