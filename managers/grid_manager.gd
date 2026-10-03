extends Node2D

signal score_changed(new_score: int)
signal combo_changed(new_multiplier: int)
signal start_combo_timer()

var score: int = 0

@export var MAX_COLUMNS: = 10
@export var MAX_ROWS: = 12
@export var cell_gap: float = 1.0
@export var grid_margin: float = 16.0

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
var cell_size: float
var grid_offset: Vector2

var reserved_top: float = 0.0
var reserved_bottom: float = 0.0

var grid_data: Array = []  # grid_data[row][col] = null or the placed tile node
var highlight_nodes: Array = []

func set_reserved_space(top: float, bottom: float) -> void:
	reserved_top = top
	reserved_bottom = bottom
	calculate_cell_size()
	spawn_grid()
	_init_grid_data()

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

# ---------------- Grid state / placement ----------------

func _init_grid_data() -> void:
	grid_data.clear()
	for r in range(MAX_ROWS):
		var row_data = []
		row_data.resize(MAX_COLUMNS)
		row_data.fill(null)
		grid_data.append(row_data)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local = world_pos - global_position - grid_offset
	return Vector2i(floor(local.x / cell_size), floor(local.y / cell_size))

func is_cell_empty(col: int, row: int) -> bool:
	if col < 0 or col >= MAX_COLUMNS or row < 0 or row >= MAX_ROWS:
		return false
	return grid_data[row][col] == null

func can_place_shape(shape: Array, origin_col: int, origin_row: int) -> bool:
	for offset in shape:
		var c = origin_col + offset.x
		var r = origin_row + offset.y
		if not is_cell_empty(c, r):
			return false
	return true

func place_shape(shape: Array, origin_col: int, origin_row: int, color: Color) -> void:
	for offset in shape:
		var c = origin_col + offset.x
		var r = origin_row + offset.y
		var tile = BLOCK_SPACE_SCENE.instantiate()
		$GridCells.add_child(tile)
		tile.block_size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
		tile.position = grid_offset + Vector2(c * cell_size, r * cell_size) + Vector2(cell_gap, cell_gap) / 2.0
		tile.modulate = color
		grid_data[r][c] = tile

	check_and_clear_lines()

func check_and_clear_lines() -> void:
	var rows_to_clear: Array = []
	var cols_to_clear: Array = []

	for r in range(MAX_ROWS):
		if grid_data[r].all(func(cell): return cell != null):
			rows_to_clear.append(r)

	for c in range(MAX_COLUMNS):
		var full := true
		for r in range(MAX_ROWS):
			if grid_data[r][c] == null:
				full = false
				break
		if full:
			cols_to_clear.append(c)

	if rows_to_clear.is_empty() and cols_to_clear.is_empty():
		return

	# collect unique cells for the actual clearing (a corner isn't cleared twice)
	var cells_to_clear := {}
	for r in rows_to_clear:
		for c in range(MAX_COLUMNS):
			cells_to_clear[Vector2i(c, r)] = true
	for c in cols_to_clear:
		for r in range(MAX_ROWS):
			cells_to_clear[Vector2i(c, r)] = true

	for cell in cells_to_clear.keys():
		_clear_cell(cell.x, cell.y)

	# score each line using the current global combo multiplier, then bump it
	# for the next line - persists across calls until your combo timer resets it
	var gained := 0
	for r in rows_to_clear:
		gained += MAX_COLUMNS * GameConfig.points_per_block * GameConfig.current_score_multiplier
		cleared_row_or_column()
	for c in cols_to_clear:
		gained += MAX_ROWS * GameConfig.points_per_block * GameConfig.current_score_multiplier
		cleared_row_or_column()

	score += gained
	score_changed.emit(score)

func _clear_cell(col: int, row: int) -> void:
	var tile = grid_data[row][col]
	if tile:
		tile.queue_free()
		grid_data[row][col] = null

# ---------------- Highlight ----------------

func show_highlight(shape: Array, origin_col: int, origin_row: int) -> void:
	clear_highlight()
	var valid = can_place_shape(shape, origin_col, origin_row)
	for offset in shape:
		var c = origin_col + offset.x
		var r = origin_row + offset.y
		if c < 0 or c >= MAX_COLUMNS or r < 0 or r >= MAX_ROWS:
			continue
		var outline = ColorRect.new()
		outline.color = Color(0, 1, 0, 0.35) if valid else Color(1, 0, 0, 0.35)
		outline.size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
		outline.position = grid_offset + Vector2(c * cell_size, r * cell_size) + Vector2(cell_gap, cell_gap) / 2.0
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(outline)
		highlight_nodes.append(outline)

func clear_highlight() -> void:
	for h in highlight_nodes:
		h.queue_free()
	highlight_nodes.clear()
	
func cleared_row_or_column() -> void:
	GameConfig.current_score_multiplier += 1
	combo_changed.emit(GameConfig.current_score_multiplier)
	start_combo_timer.emit()
