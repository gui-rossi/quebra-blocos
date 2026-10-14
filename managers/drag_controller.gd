extends Node2D

@export var grid_manager_path: NodePath
@export var bottom_tray_path: NodePath
@export var drag_layer_path: NodePath

var grid_manager: Node2D
var bottom_tray: Node2D
var drag_layer: CanvasLayer

var dragging_container: Node2D = null
var dragging_piece: Node2D = null  # the RandomizedBlock this container belongs to
var drag_shape_half: Vector2i = Vector2i.ZERO  # half-extents of the shape's bounding box
var _drag_scale_tween: Tween

# On-screen size of a dragged bomb's body, in grid cells
const BOMB_DRAG_SIZE_CELLS: float = 0.9

func _ready() -> void:
	grid_manager = get_node(grid_manager_path)
	bottom_tray = get_node(bottom_tray_path)
	drag_layer = get_node(drag_layer_path)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and dragging_container == null:
			_try_start_drag(event.position)
		elif not event.pressed and dragging_container != null:
			_end_drag()

	elif event is InputEventScreenDrag:
		if dragging_container:
			dragging_container.global_position = event.position
			var origin_cell = _get_origin_cell()
			if dragging_piece.is_bomb:
				grid_manager.show_bomb_highlight(origin_cell.x, origin_cell.y)
			else:
				grid_manager.show_highlight(dragging_piece.shape_cells, origin_cell.x, origin_cell.y)

func _get_shape_bounds(shape: Array) -> Vector2i:
	var min_x = shape[0].x
	var max_x = shape[0].x
	var min_y = shape[0].y
	var max_y = shape[0].y
	for cell in shape:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	return Vector2i(max_x - min_x + 1, max_y - min_y + 1)

func _get_origin_cell() -> Vector2i:
	var raw_cell = grid_manager.world_to_cell(dragging_container.global_position)
	return raw_cell - drag_shape_half

func _try_start_drag(pos: Vector2) -> void:
	var pieces = [bottom_tray.randomized_block_1, bottom_tray.randomized_block_2, bottom_tray.randomized_block_3]
	for piece in pieces:
		if piece.shape_cells.is_empty():
			continue  # already used, nothing to drag

		var circle_sprite: Sprite2D = piece.get_node("Sprite2D")
		var radius = (circle_sprite.texture.get_size().x / 2.0) * piece.scale.x
		if pos.distance_to(piece.global_position) <= radius:
			_start_drag(piece)
			return

func _start_drag(piece: Node2D) -> void:
	dragging_piece = piece
	dragging_container = piece.get_node("ShapeContainer")

	var bounds = _get_shape_bounds(piece.shape_cells)
	drag_shape_half = Vector2i(bounds.x / 2, bounds.y / 2)

	dragging_container.reparent(drag_layer, true)

	if piece.is_bomb:
		dragging_container.modulate.a = 0.85
		# the bomb is big in the tray, shrink it to about a cell so the blast area stays visible
		var target_scale = dragging_container.scale * (GameConfig.cell_size * BOMB_DRAG_SIZE_CELLS) / (piece.bomb.diameter * dragging_container.scale.x)
		_drag_scale_tween = dragging_container.create_tween()
		_drag_scale_tween.tween_property(dragging_container, "scale", target_scale, 0.1).set_ease(Tween.EASE_OUT)
	else:
		dragging_container.modulate.a = 0.6

func _end_drag() -> void:
	var container = dragging_container
	var piece = dragging_piece
	var origin_cell = _get_origin_cell()

	if _drag_scale_tween:
		_drag_scale_tween.kill()
		_drag_scale_tween = null

	var valid: bool
	if piece.is_bomb:
		valid = grid_manager.can_place_bomb(origin_cell.x, origin_cell.y)
	else:
		valid = grid_manager.can_place_shape(piece.shape_cells, origin_cell.x, origin_cell.y)

	if valid:
		if piece.is_bomb:
			# the grid takes the bomb (out of the container) before the container is emptied below
			grid_manager.detonate_bomb(piece.take_bomb(), origin_cell.x, origin_cell.y)
		else:
			grid_manager.place_shape(piece.shape_cells, origin_cell.x, origin_cell.y, piece.piece_color)
		# consume this piece - clear its shape, mark it used, don't respawn yet
		for tile in container.get_children():
			tile.queue_free()
		_return_container(container, piece)
		piece.shape_cells = []
		bottom_tray.check_and_respawn_if_needed()
	else:
		# invalid drop - snap the shape back to its circle
		_return_container(container, piece)

	grid_manager.clear_highlight()
	dragging_container = null
	dragging_piece = null

func _return_container(container: Node2D, piece: Node2D) -> void:
	container.reparent(piece, false)
	container.position = Vector2.ZERO
	container.scale = Vector2.ONE
	container.modulate.a = 1.0
