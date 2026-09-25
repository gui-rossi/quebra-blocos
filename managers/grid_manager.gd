extends Node2D

@export var MAX_COLUMNS: = 10
@export var MAX_ROWS: = 12
@export var cell_gap: float = 1.0
@export var grid_margin: float = 16.0

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
var cell_size: float
var grid_offset: Vector2

var reserved_top: float = 0.0
var reserved_bottom: float = 0.0

#func _ready() -> void:
	#calculate_cell_size()
	#spawn_grid()

func set_reserved_space(top: float, bottom: float) -> void:
	reserved_top = top
	reserved_bottom = bottom
	calculate_cell_size()
	spawn_grid()

func calculate_cell_size() -> void:
	var viewport_size = get_viewport_rect().size
	var available_width = viewport_size.x - grid_margin * 2
	var available_height = viewport_size.y - reserved_top - reserved_bottom - grid_margin * 2
	var size_by_width = available_width / MAX_COLUMNS
	var size_by_height = available_height / MAX_ROWS
	cell_size = floor(min(size_by_width, size_by_height))
	GameConfig.cell_size = cell_size
	GameConfig.cell_gap = cell_gap

	var grid_total_size = Vector2(cell_size * MAX_COLUMNS, cell_size * MAX_ROWS)
	var leftover = Vector2(available_width, available_height) - grid_total_size
	grid_offset = Vector2(grid_margin, reserved_top + grid_margin) + Vector2(leftover.x / 2.0, leftover.y / 2.0)

func spawn_grid() -> void:
	for row in range(MAX_ROWS):
		for col in range(MAX_COLUMNS):
			spawn_block_space(col, row)

func spawn_block_space(col: int, row: int) -> void:
	var spaceBlock = BLOCK_SPACE_SCENE.instantiate()
	$GridCells.add_child(spaceBlock)
	spaceBlock.block_size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
	spaceBlock.position = grid_offset + Vector2(col * cell_size, row * cell_size) + Vector2(cell_gap, cell_gap) / 2.0
