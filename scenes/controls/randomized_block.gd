extends Node2D

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")

@onready var circle_sprite: Sprite2D = $Sprite2D

var shape_cells: Array = []
var piece_color: Color = Color.WHITE

func _ready() -> void:
	randomize_shape()
	build_piece()

func randomize_shape() -> void:
	var shape_name = ShapeDefinitions.get_random_shape_name()
	shape_cells = ShapeDefinitions.get_shape(shape_name)
	piece_color = Color(randf(), randf(), randf())

func build_piece() -> void:
	# clear any previously built tiles (keep the circle Sprite2D)
	for child in get_children():
		if child != circle_sprite:
			child.queue_free()

	var size = GameConfig.cell_size
	var gap = GameConfig.cell_gap

	# bounding box of the shape, so it can be centered on the circle
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

	for cell in shape_cells:
		var tile = BLOCK_SPACE_SCENE.instantiate()
		add_child(tile)
		tile.block_size = Vector2(size - gap, size - gap)
		tile.modulate = piece_color

		var local_x = (cell.x - min_x) * size - shape_width / 2.0
		var local_y = (cell.y - min_y) * size - shape_height / 2.0
		tile.position = circle_center + Vector2(local_x, local_y)
