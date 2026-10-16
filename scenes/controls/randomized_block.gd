extends Node2D

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
const BOMB_SCENE: PackedScene = preload("res://scenes/powerups/powerup_bomb.tscn")

@onready var circle_sprite: Sprite2D = $Sprite2D
@onready var shape_container: Node2D = $ShapeContainer

var shape_cells: Array = []
var piece_color: Color = Color.DARK_GREEN
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
	powerup_name = ShapeDefinitions.roll_powerup_name()
	is_bomb = powerup_name == "bomb"

	if powerup_name != "":
		var powerup = ShapeDefinitions.get_powerup(powerup_name)
		shape_cells = powerup.cells
		drag_size_cells = powerup.drag_size_cells
		drag_alpha = powerup.drag_alpha
		return

	drag_size_cells = 0.0
	drag_alpha = ShapeDefinitions.SHAPE_DRAG_ALPHA

	shape_cells = ShapeDefinitions.get_shape("square_3x3")
	return
	
	var shape_name = ShapeDefinitions.get_random_shape_name()
	shape_cells = ShapeDefinitions.get_shape(shape_name)
	#piece_color = Color(randf(), randf(), randf())
	piece_color = Color.from_rgba8(17, 138, 178)

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
