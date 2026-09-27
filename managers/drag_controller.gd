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
	dragging_container.modulate.a = 0.6

func _end_drag() -> void:
	var container = dragging_container
	var piece = dragging_piece
	var origin_cell = _get_origin_cell()
	var valid = grid_manager.can_place_shape(piece.shape_cells, origin_cell.x, origin_cell.y)

	if valid:
		grid_manager.place_shape(piece.shape_cells, origin_cell.x, origin_cell.y, piece.piece_color)
		# consume this piece - clear its shape, mark it used, don't respawn yet
		for tile in container.get_children():
			tile.queue_free()
		container.reparent(piece, false)
		container.position = Vector2.ZERO
		container.scale = Vector2.ONE
		container.modulate.a = 1.0
		piece.shape_cells = []
		bottom_tray.check_and_respawn_if_needed()
	else:
		# invalid drop - snap the shape back to its circle
		container.reparent(piece, false)
		container.position = Vector2.ZERO
		container.scale = Vector2.ONE
		container.modulate.a = 1.0

	grid_manager.clear_highlight()
	dragging_container = null
	dragging_piece = null
