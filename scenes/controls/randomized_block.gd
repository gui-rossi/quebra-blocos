extends Node2D

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
const BOMB_SCENE: PackedScene = preload("res://scenes/powerups/powerup_bomb.tscn")

@onready var circle_sprite: Sprite2D = $Sprite2D
@onready var shape_container: Node2D = $ShapeContainer

var shape_cells: Array = []
var piece_color: Color = Color.DARK_GREEN
var shape_name: String = ""  # key in ShapeDefinitions.SHAPES, "" for a power-up
var powerup_name: String = ""  # key in ShapeDefinitions.POWERUPS, "" for a regular shape
var is_bomb: bool = false
var bomb: Node2D = null

# How the piece looks while dragged
var drag_size_cells: float = 0.0  # > 0 resizes its body to this many grid cells wide, 0 keeps the tray size
var drag_alpha: float = ShapeDefinitions.SHAPE_DRAG_ALPHA
var body_size: float = 0.0  # width of its body, in the shape container's local units

func _ready() -> void:
	pass  # don't build here - GameConfig.cell_size isn't set yet at this point

func randomize_shape() -> void:
	var rolled_powerup = ShapeDefinitions.roll_powerup_name()
	if rolled_powerup != "":
		_apply_powerup(rolled_powerup)
		return

	_apply_shape("square_3x3")
	return

	_apply_shape(ShapeDefinitions.get_random_shape_name())
	#piece_color = Color(randf(), randf(), randf())
	piece_color = Color.from_rgba8(17, 138, 178)

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
	drag_size_cells = 0.0
	drag_alpha = ShapeDefinitions.SHAPE_DRAG_ALPHA

func build_piece(shape_scale_factor: float = 1.0) -> void:
	for child in shape_container.get_children():
		child.queue_free()
	bomb = null

	if is_bomb:
		_build_bomb()
		return

	var size = GameConfig.cell_size * shape_scale_factor
	var gap = GameConfig.cell_gap * shape_scale_factor

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
	var circle_center = circle_sprite.position
	body_size = shape_width

	for cell in shape_cells:
		var tile = BLOCK_SPACE_SCENE.instantiate()
		shape_container.add_child(tile)
		tile.block_size = Vector2(size - gap, size - gap)
		tile.modulate = piece_color

		var local_x = (cell.x - min_x) * size - shape_width / 2.0
		var local_y = (cell.y - min_y) * size - shape_height / 2.0
		tile.position = circle_center + Vector2(local_x, local_y)

func _build_bomb() -> void:
	bomb = BOMB_SCENE.instantiate()
	shape_container.add_child(bomb)
	bomb.position = circle_sprite.position
	bomb.fit_to(circle_sprite.texture.get_size().x * ShapeDefinitions.get_powerup("bomb").tray_size_ratio)
	bomb.start_idle()
	body_size = bomb.diameter

# Hands the bomb over (e.g. to the grid, to explode) - this piece no longer owns it
func take_bomb() -> Node2D:
	var taken = bomb
	bomb = null
	is_bomb = false
	powerup_name = ""
	return taken
