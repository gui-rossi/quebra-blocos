extends Node2D

signal score_changed(new_score: int)
signal combo_changed(new_multiplier: int)
signal start_combo_timer()
signal slow_time_used(duration: float, factor: float)  # an hourglass was dropped (main.gd slows the combo timer)
signal fragments_launched(count: int)  # broken blocks' fragments about to fly to the score (sent before the score changes)
signal fragment_arrived()  # one of them reached the score number
signal powerup_finished()  # a power-up's effect is done and the cells it cleared are free

var score: int = 0
var score_target: Callable  # returns the score number's global position; broken blocks' fragments fly there

@export var MAX_COLUMNS: = 10
@export var MAX_ROWS: = 12
@export var cell_gap: float = 4.0
@export var grid_margin: float = 16.0

const BLOCK_SPACE_SCENE: PackedScene = preload("res://scenes/blocks/block_space.tscn")
const ExplosionEffect = preload("res://scenes/powerups/explosion_effect.gd")
const EXPLOSION_SOUND: AudioStream = preload("res://scenes/powerups/bomb_explosion.wav")
const BlockBurst = preload("res://scenes/effects/block_burst.gd")
const ScoreFragments = preload("res://scenes/effects/score_fragments.gd")
const FloatingText = preload("res://scenes/effects/floating_text.gd")
const Palette = preload("res://configs/palette.gd")
const NumberFormat = preload("res://configs/number_format.gd")

# Banner shown when several lines break at once, by number of lines
const LASER_COLOR := Color(0.55, 1.0, 1.0, 0.85)
const MULTI_LINE_BANNERS := {2: "BANNER_LINES_2", 3: "BANNER_LINES_3", 4: "BANNER_LINES_4"}  # translation keys

var cell_size: float
var grid_offset: Vector2

var reserved_top: float = 0.0
var reserved_bottom: float = 0.0

var grid_data: Array = []  # grid_data[row][col] = null or the placed tile node
var highlight_nodes: Array = []
var _highlight_key = null  # what the current highlight shows, so it's only rebuilt when that changes
var _shake_tween: Tween
var _explosion_player: AudioStreamPlayer

func _ready() -> void:
	_explosion_player = AudioStreamPlayer.new()
	_explosion_player.stream = EXPLOSION_SOUND
	_explosion_player.bus = Settings.SFX_BUS
	add_child(_explosion_player)

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
	queue_redraw()  # the board panel follows the grid's size

func spawn_grid() -> void:
	for row in range(MAX_ROWS):
		for col in range(MAX_COLUMNS):
			spawn_block_space(col, row)

func spawn_block_space(col: int, row: int) -> void:
	var spaceBlock = BLOCK_SPACE_SCENE.instantiate()
	$GridCells.add_child(spaceBlock)
	spaceBlock.block_size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
	spaceBlock.position = grid_offset + Vector2(col * cell_size, row * cell_size) + Vector2(cell_gap, cell_gap) / 2.0
	spaceBlock.empty = true

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

func is_in_grid(col: int, row: int) -> bool:
	return col >= 0 and col < MAX_COLUMNS and row >= 0 and row < MAX_ROWS

func is_cell_empty(col: int, row: int) -> bool:
	if not is_in_grid(col, row):
		return false
	return grid_data[row][col] == null

func cell_to_local_center(cell: Vector2i) -> Vector2:
	return grid_offset + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size

func can_place_shape(shape: Array, origin_col: int, origin_row: int) -> bool:
	for offset in shape:
		var c = origin_col + offset.x
		var r = origin_row + offset.y
		if not is_cell_empty(c, r):
			return false
	return true

# Can the shape go anywhere on the board right now? Used to detect game over
func can_fit_anywhere(shape: Array) -> bool:
	for r in range(MAX_ROWS):
		for c in range(MAX_COLUMNS):
			if can_place_shape(shape, c, r):
				return true
	return false

func place_shape(shape: Array, origin_col: int, origin_row: int, color: Color) -> void:
	var center := Vector2.ZERO
	for i in range(shape.size()):
		var c = origin_col + shape[i].x
		var r = origin_row + shape[i].y
		var tile = _spawn_tile(c, r, color)
		_animate_tile_placed(tile, i * 0.02)
		center += cell_to_local_center(Vector2i(c, r))
	center /= shape.size()

	_spawn_burst(center, Color(1, 1, 1, 0.6), 6, 0.35)
	Sfx.play("place", randf_range(0.95, 1.05))
	Settings.vibrate(8)

	check_and_clear_lines(Vector2i(origin_col, origin_row) + _shape_center_offset(shape))

# Puts saved tiles back on the board, without effects or clearing lines
func restore_cells(cells: Array) -> void:
	for cell in cells:
		var c = int(cell.col)
		var r = int(cell.row)
		if is_in_grid(c, r) and grid_data[r][c] == null:
			_spawn_tile(c, r, Color.html(cell.color))

# The board as plain data, for saving: [{col, row, color}]
func get_cells_data() -> Array:
	var cells := []
	for r in range(MAX_ROWS):
		for c in range(MAX_COLUMNS):
			var tile = grid_data[r][c]
			if tile != null:
				cells.append({"col": c, "row": r, "color": tile.block_color.to_html(true)})
	return cells

func set_score(value: int) -> void:
	score = value
	score_changed.emit(score)

func _spawn_tile(col: int, row: int, color: Color) -> Node2D:
	var tile = BLOCK_SPACE_SCENE.instantiate()
	$GridCells.add_child(tile)
	tile.block_size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
	tile.position = grid_offset + Vector2(col * cell_size, row * cell_size) + Vector2(cell_gap, cell_gap) / 2.0
	tile.block_color = color
	grid_data[row][col] = tile
	return tile

func _shape_center_offset(shape: Array) -> Vector2i:
	var max_cell = Vector2i.ZERO
	for cell in shape:
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	return max_cell / 2

# `focus` is the cell the clear spreads out from (where the piece landed)
func check_and_clear_lines(focus: Vector2i = Vector2i.ZERO) -> void:
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

	# the cells are free right away, the tiles break in a wave spreading out from where the piece landed
	var popup_position := Vector2.ZERO
	for cell in cells_to_clear.keys():
		var tile = grid_data[cell.y][cell.x]
		grid_data[cell.y][cell.x] = null
		popup_position += cell_to_local_center(cell)
		if tile:
			_animate_tile_destroyed(tile, Vector2(cell - focus).length() * 0.025)
	popup_position /= cells_to_clear.size()

	for r in rows_to_clear:
		_flash_line(Vector2(0, r), Vector2(MAX_COLUMNS, 1))
	for c in cols_to_clear:
		_flash_line(Vector2(c, 0), Vector2(1, MAX_ROWS))

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

	var lines = rows_to_clear.size() + cols_to_clear.size()
	_spawn_floating_text("+" + NumberFormat.compact(gained), popup_position, Color(1, 0.9, 0.35), 44)
	if lines >= 2:
		var banner = MULTI_LINE_BANNERS.get(mini(lines, 4))
		_spawn_floating_text(banner, cell_to_local_center(Vector2i(MAX_COLUMNS, MAX_ROWS) / 2), Color(0.55, 1, 0.9), 72)

	_shake(cell_size * 0.05 * lines)
	# the chime climbs with the multiplier so a long combo sounds like it
	Sfx.play("line_clear", minf(1.0 + 0.08 * (GameConfig.current_score_multiplier - 2), 2.0))
	Settings.vibrate(20)

# ---------------- Power-ups ----------------
# Each power-up (see ShapeDefinitions.POWERUPS) has an area it affects, a rule for where it can be dropped,
# and an effect. The drag controller only calls these three generic functions.

# Cells a power-up dropped on (col, row) would affect, for the preview
func get_powerup_area(key: String, col: int, row: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not is_in_grid(col, row):
		return cells
	var mega = ShapeDefinitions.is_mega(key)
	match ShapeDefinitions.get_effect(key):
		"bomb":
			cells = get_bomb_area(col, row, GameConfig.mega_bomb_radius if mega else GameConfig.bomb_radius)
		"laser":
			# its rows across and its columns down (one of each, or mega_laser_width centered on the cell)
			var half = GameConfig.mega_laser_width / 2 if mega else 0
			for r in range(MAX_ROWS):
				for c in range(MAX_COLUMNS):
					if absi(r - row) <= half or absi(c - col) <= half:
						cells.append(Vector2i(c, r))
		"prism":
			var target = grid_data[row][col]
			if target:
				var colors = [target.block_color]
				if mega:
					var second = _most_common_color_besides(target.block_color)
					if second != null:
						colors.append(second)
				for r in range(MAX_ROWS):
					for c in range(MAX_COLUMNS):
						var tile = grid_data[r][c]
						if tile and colors.any(func(color): return _same_color(tile.block_color, color)):
							cells.append(Vector2i(c, r))
		"booster", "hourglass":
			cells.append(Vector2i(col, row))
	return cells

# The color with the most blocks on the board, not counting `excluded` (null if there's no other color)
func _most_common_color_besides(excluded: Color):
	var colors: Array = []
	var counts: Array[int] = []
	for r in range(MAX_ROWS):
		for c in range(MAX_COLUMNS):
			var tile = grid_data[r][c]
			if tile == null or _same_color(tile.block_color, excluded):
				continue
			var index = colors.find_custom(func(color): return _same_color(color, tile.block_color))
			if index == -1:
				colors.append(tile.block_color)
				counts.append(1)
			else:
				counts[index] += 1
	if colors.is_empty():
		return null
	return colors[counts.find(counts.max())]

# Whether the power-up has somewhere to go on the board right now (the prism needs at least one block)
func can_place_powerup_anywhere(key: String) -> bool:
	if ShapeDefinitions.get_effect(key) != "prism":
		return true
	for r in range(MAX_ROWS):
		for c in range(MAX_COLUMNS):
			if grid_data[r][c] != null:
				return true
	return false

# Points that don't come from clearing blocks (e.g. a power-up dropped in the trash can)
func add_score(points: int) -> void:
	if points <= 0:
		return
	score += points
	score_changed.emit(score)

func can_place_powerup(key: String, col: int, row: int) -> bool:
	if not is_in_grid(col, row):
		return false
	if ShapeDefinitions.get_effect(key) == "prism":
		return grid_data[row][col] != null  # it needs a block to take the color from
	return true  # the others go over anything

# Plays the power-up's animation on the target cell, then applies its effect
func activate_powerup(key: String, visual: Node2D, col: int, row: int) -> void:
	var cell = Vector2i(col, row)
	var area = get_powerup_area(key, col, row)  # decided at drop time
	var mega = ShapeDefinitions.is_mega(key)
	var bonus = GameConfig.mega_score_bonus if mega else 1  # blocks broken by a mega one score this many times more
	visual.reparent(self, true)
	await visual.activate(to_global(cell_to_local_center(cell)))
	match ShapeDefinitions.get_effect(key):
		"bomb":
			explode_at(col, row, GameConfig.mega_bomb_radius if mega else GameConfig.bomb_radius, bonus)
		"laser":
			_fire_laser(cell, area, GameConfig.mega_laser_width if mega else 1, bonus)
		"prism":
			_clear_color(cell, area, bonus)
		"booster":
			_boost(cell, GameConfig.mega_booster_multiplier if mega else GameConfig.booster_multiplier)
		"hourglass":
			if mega:
				slow_time_used.emit(GameConfig.mega_slow_time_duration, GameConfig.mega_slow_time_factor)
				_spawn_floating_text(tr("POWERUP_TIME_STOPPED"), cell_to_local_center(cell), Color(0.6, 0.85, 1.0), 52)
			else:
				slow_time_used.emit(GameConfig.slow_time_duration, GameConfig.slow_time_factor)
				_spawn_floating_text(tr("POWERUP_SLOW_TIME"), cell_to_local_center(cell), Color(0.6, 0.85, 1.0), 44)
			Sfx.play("combo_up", 0.55 if mega else 0.7)
			Settings.vibrate(50 if mega else 30)
	if bonus > 1:
		# floats up a little above the effect's own text
		_spawn_floating_text(tr("POWERUP_MEGA_BONUS") % bonus, cell_to_local_center(cell) - Vector2(0, cell_size * 0.9), Color(1.0, 0.82, 0.3), 48)
	powerup_finished.emit()

# Cells inside the blast circle: every cell whose center is within radius + 0.5 of the bomb's cell,
# so radius 1 = 3x3, radius 2 = 5x5 without the corners, radius 4 = 9x9 with rounded corners
func get_bomb_area(center_col: int, center_row: int, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius + radius:
				continue
			var c = center_col + dx
			var r = center_row + dy
			if is_in_grid(c, r):
				cells.append(Vector2i(c, r))
	return cells

func explode_at(center_col: int, center_row: int, radius: int, score_bonus: int = 1) -> void:
	var center = Vector2i(center_col, center_row)
	_destroy_cells(get_bomb_area(center_col, center_row, radius), center, 0.05, score_bonus)

	_spawn_explosion(center, radius)
	_shake(cell_size * 0.04 * (radius + 1))  # bigger blasts shake harder
	Settings.vibrate(40 + 10 * (radius - GameConfig.bomb_radius))
	_explosion_player.pitch_scale = randf_range(0.9, 1.1)  # so repeated blasts don't sound identical
	_explosion_player.play()

# Laser: beams along the row and the column (`width` of each, centered on the target), the blocks break outwards
func _fire_laser(cell: Vector2i, area: Array, width: int = 1, score_bonus: int = 1) -> void:
	var half = width / 2
	_flash_line(Vector2(0, cell.y - half), Vector2(MAX_COLUMNS, width), LASER_COLOR)
	_flash_line(Vector2(cell.x - half, 0), Vector2(width, MAX_ROWS), LASER_COLOR)
	_destroy_cells(area, cell, 0.03, score_bonus)
	_shake(cell_size * 0.06 * width)
	Sfx.play("laser")
	Settings.vibrate(30)

# Prism: every block of the target's color breaks, rippling out from the target
func _clear_color(cell: Vector2i, area: Array, score_bonus: int = 1) -> void:
	_destroy_cells(area, cell, 0.035, score_bonus)
	_spawn_floating_text("+%d" % area.size(), cell_to_local_center(cell), Color.WHITE, 40)
	Sfx.play("line_clear", 1.5)
	Settings.vibrate(30)

# Booster: the multiplier goes up by `amount` and the combo timer refills
func _boost(cell: Vector2i, amount: int) -> void:
	GameConfig.current_score_multiplier = mini(GameConfig.current_score_multiplier + amount, GameConfig.max_score_multiplier)
	combo_changed.emit(GameConfig.current_score_multiplier)
	start_combo_timer.emit()
	_spawn_floating_text(tr("POWERUP_BOOSTER") % amount, cell_to_local_center(cell), Color(1, 0.85, 0.3), 44)
	Sfx.play("combo_up", 1.3)
	Settings.vibrate(30)

# Breaks the blocks in `cells` (empty ones are skipped) with a wave from `center`, and scores them
# (`score_bonus` times more for a mega power-up)
func _destroy_cells(cells: Array, center: Vector2i, delay_per_cell: float, score_bonus: int = 1) -> int:
	var destroyed := 0
	for cell in cells:
		var tile = grid_data[cell.y][cell.x]
		if tile == null:
			continue
		# the cell is free right away, the tile only sticks around for its animation
		grid_data[cell.y][cell.x] = null
		destroyed += 1
		_animate_tile_destroyed(tile, Vector2(cell - center).length() * delay_per_cell)
	if destroyed > 0:
		score += destroyed * GameConfig.points_per_block * GameConfig.current_score_multiplier * score_bonus
		score_changed.emit(score)
	return destroyed

func _same_color(a: Color, b: Color) -> bool:
	return a.to_html(false) == b.to_html(false)  # colors come back from saves as text, compare them the same way

func _animate_tile_destroyed(tile: Node2D, delay: float) -> void:
	# scale the tile from its center, not its top-left corner
	var control: Control = tile.get_node("Control")
	control.pivot_offset = control.size / 2.0

	var color: Color = tile.block_color
	var tile_center = tile.position + control.size / 2.0

	# the fragments are counted now, before the score changes, so the HUD knows to wait for them
	var fragments := 0
	if score_target.is_valid():
		fragments = ScoreFragments.fragment_count()
		fragments_launched.emit(fragments)

	var tween = tile.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(_spawn_break.bind(tile_center, color, fragments))
	tween.tween_property(tile, "modulate", Color(1.6, 1.6, 1.6), 0.06)  # flashes bright before breaking
	tween.parallel().tween_property(control, "scale", Vector2(1.2, 1.2), 0.06)
	tween.tween_property(control, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(tile, "modulate:a", 0.0, 0.2)
	tween.tween_callback(tile.queue_free)

func _spawn_explosion(center: Vector2i, radius: int) -> void:
	var effect = ExplosionEffect.new()
	effect.position = cell_to_local_center(center)
	effect.max_radius = (radius + 0.5) * cell_size
	add_child(effect)
	effect.play()

# A placed tile lands: drops in slightly big and bright, squashes a little, then settles
func _animate_tile_placed(tile: Node2D, delay: float) -> void:
	var control: Control = tile.get_node("Control")
	control.pivot_offset = control.size / 2.0
	control.scale = Vector2(1.18, 1.18)
	tile.modulate = Color(1.35, 1.35, 1.35)

	var tween = tile.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(control, "scale", Vector2(0.94, 0.94), 0.07).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(tile, "modulate", Color.WHITE, 0.18)
	tween.tween_property(control, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A broken block's fragments: they fall for a moment, then fly into the score number (score_target, set by main.gd).
# Falls back to a plain burst if there's nowhere to fly to.
func _spawn_break(local_position: Vector2, color: Color, count: int) -> void:
	if count <= 0:
		_spawn_burst(local_position, color, 14, 1.0)
		return
	var fragments = ScoreFragments.new()
	fragments.position = local_position
	fragments.color = color
	fragments.size = cell_size
	fragments.amount = count
	fragments.target = score_target.call()
	fragments.arrived = fragment_arrived.emit
	add_child(fragments)
	fragments.play()

func _spawn_burst(local_position: Vector2, color: Color, amount: int, speed: float) -> void:
	var burst = BlockBurst.new()
	burst.position = local_position
	burst.color = color
	burst.size = cell_size
	burst.amount = amount
	burst.speed = speed
	add_child(burst)
	burst.play()

func _spawn_floating_text(text: String, local_position: Vector2, color: Color, font_size: int) -> void:
	var popup = FloatingText.new()
	popup.position = local_position
	popup.text = text
	popup.color = color
	popup.font_size = font_size
	add_child(popup)
	popup.play()

# Quick flash over a cleared row or column, `cell` and `cells` in grid cells
func _flash_line(cell: Vector2, cells: Vector2, color: Color = Color(1, 1, 1, 0.7)) -> void:
	var flash = ColorRect.new()
	flash.color = color
	flash.position = grid_offset + cell * cell_size
	flash.size = cells * cell_size
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween = flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _shake(strength: float) -> void:
	if not Settings.effects_high:
		return
	if _shake_tween:
		_shake_tween.kill()
	position = Vector2.ZERO

	_shake_tween = create_tween()
	for i in range(6):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * (1.0 - i / 6.0)
		_shake_tween.tween_property(self, "position", offset, 0.03)
	_shake_tween.tween_property(self, "position", Vector2.ZERO, 0.03)

# ---------------- Highlight ----------------

# Ghost of the piece where it would land, and the lines it would complete lit up in its color.
# Shows nothing when it doesn't fit there.
func show_highlight(shape: Array, origin_col: int, origin_row: int, color: Color = Color.WHITE) -> void:
	var key = [origin_col, origin_row, "shape"]
	if key == _highlight_key:
		return
	clear_highlight()
	_highlight_key = key

	if not can_place_shape(shape, origin_col, origin_row):
		return

	var placed := {}
	for offset in shape:
		var cell = Vector2i(origin_col + offset.x, origin_row + offset.y)
		placed[cell] = true
		_add_ghost(cell, color, 0.45)

	# blocks already on the board in lines this piece would complete
	for cell in _cells_completed_by(placed):
		if not placed.has(cell):
			_add_ghost(cell, color, 0.85)

# Preview of a power-up dropped on (col, row): the blocks it would break stand out, empty cells in its area are faint.
# Shows nothing where it can't be dropped.
func show_powerup_highlight(key: String, col: int, row: int) -> void:
	var highlight_key = [col, row, key]
	if highlight_key == _highlight_key:
		return
	clear_highlight()
	_highlight_key = highlight_key

	if not can_place_powerup(key, col, row):
		return
	var color: Color = ShapeDefinitions.get_powerup(key).get("ghost", Color.WHITE)
	for cell in get_powerup_area(key, col, row):
		var filled = grid_data[cell.y][cell.x] != null
		_add_ghost(cell, color, 0.75 if filled else 0.25)

func clear_highlight() -> void:
	for h in highlight_nodes:
		h.queue_free()
	highlight_nodes.clear()
	_highlight_key = null

# Cells of every row and column that would be full once `placed` (a set of cells) is filled
func _cells_completed_by(placed: Dictionary) -> Array:
	var rows := {}
	var cols := {}
	for cell in placed:
		rows[cell.y] = true
		cols[cell.x] = true

	var cells := []
	for r in rows:
		var line = range(MAX_COLUMNS).map(func(c): return Vector2i(c, r))
		if line.all(func(cell): return grid_data[cell.y][cell.x] != null or placed.has(cell)):
			cells.append_array(line)
	for c in cols:
		var line = range(MAX_ROWS).map(func(r): return Vector2i(c, r))
		if line.all(func(cell): return grid_data[cell.y][cell.x] != null or placed.has(cell)):
			cells.append_array(line)
	return cells

func _add_ghost(cell: Vector2i, color: Color, alpha: float) -> void:
	var ghost = BLOCK_SPACE_SCENE.instantiate()
	add_child(ghost)
	ghost.block_size = Vector2(cell_size - cell_gap, cell_size - cell_gap)
	ghost.position = grid_offset + Vector2(cell) * cell_size + Vector2(cell_gap, cell_gap) / 2.0
	ghost.block_color = color
	ghost.modulate.a = alpha
	highlight_nodes.append(ghost)

# ---------------- Board ----------------

# The board panel's rectangle (grid plus its padding), in this node's coordinates
func get_board_rect() -> Rect2:
	return Rect2(grid_offset, Vector2(MAX_COLUMNS, MAX_ROWS) * cell_size).grow(cell_size * 0.22)

# Rounded panel behind the grid, with a soft drop shadow (drawn under all the cells)
func _draw() -> void:
	if cell_size <= 0.0:
		return
	var board = get_board_rect()
	var radius = int(cell_size * 0.35)

	var shadow = StyleBoxFlat.new()
	shadow.bg_color = Palette.BOARD_SHADOW
	shadow.set_corner_radius_all(radius)
	draw_style_box(shadow, Rect2(board.position + Vector2(0, cell_size * 0.12), board.size))

	var panel = StyleBoxFlat.new()
	panel.bg_color = Palette.BOARD
	panel.set_corner_radius_all(radius)
	panel.set_border_width_all(3)
	panel.border_color = Palette.BOARD_BORDER
	panel.anti_aliasing = true
	draw_style_box(panel, board)

func cleared_row_or_column() -> void:
	GameConfig.current_score_multiplier = mini(GameConfig.current_score_multiplier + 1, GameConfig.max_score_multiplier)
	combo_changed.emit(GameConfig.current_score_multiplier)
	start_combo_timer.emit()
