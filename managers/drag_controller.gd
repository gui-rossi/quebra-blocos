extends Node2D

signal piece_dropped(was_powerup: bool)  # a piece was placed on the grid (and the tray refilled if needed)

@export var grid_manager_path: NodePath
@export var bottom_tray_path: NodePath
@export var drag_layer_path: NodePath

var grid_manager: Node2D
var bottom_tray: Node2D
var drag_layer: CanvasLayer

var dragging_container: Node2D = null
var dragging_piece: CanvasItem = null  # the tray piece (RandomizedBlock) or backpack slot this container belongs to
var drag_shape_half: Vector2i = Vector2i.ZERO  # half-extents of the shape's bounding box
var _drag_scale_tween: Tween
var _touch_position: Vector2 = Vector2.ZERO

var backpack: Control = null  # set by main.gd; power-ups can be stored in it and dragged back out

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
			_touch_position = event.position

			# a power-up from the tray over a free backpack slot: highlight the slot instead of the grid
			if _can_store_dragged():
				var slot = backpack.free_slot_at(event.position)
				backpack.set_hover(slot)
				if slot:
					grid_manager.clear_highlight()
					return

			var origin_cell = _get_origin_cell()
			if dragging_piece.powerup_name != "":
				grid_manager.show_powerup_highlight(dragging_piece.powerup_name, origin_cell.x, origin_cell.y)
			else:
				grid_manager.show_highlight(dragging_piece.shape_cells, origin_cell.x, origin_cell.y, dragging_piece.piece_color)

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
			_start_drag(piece, pos)
			return

	if backpack:
		var slot = backpack.filled_slot_at(pos)
		if slot:
			_start_drag(slot, pos)

func _start_drag(piece: CanvasItem, touch_position: Vector2) -> void:
	dragging_piece = piece
	_touch_position = touch_position
	dragging_container = piece.get_node("ShapeContainer")

	var bounds = _get_shape_bounds(piece.shape_cells)
	drag_shape_half = Vector2i(bounds.x / 2, bounds.y / 2)

	dragging_container.reparent(drag_layer, true)
	dragging_container.modulate.a = piece.drag_alpha

	# the piece is held by its center, right under the finger
	dragging_container.global_position = touch_position
	Settings.vibrate(5)

	if piece.drag_size_cells > 0.0:
		# resize the body to drag_size_cells grid cells wide on screen
		var target_scale = dragging_container.scale * (GameConfig.cell_size * piece.drag_size_cells) / (piece.body_size * dragging_container.scale.x)
		_drag_scale_tween = dragging_container.create_tween()
		_drag_scale_tween.tween_property(dragging_container, "scale", target_scale, 0.1).set_ease(Tween.EASE_OUT)

	if _can_store_dragged():
		backpack.set_accepting(true)

func _end_drag() -> void:
	var container = dragging_container
	var piece = dragging_piece
	var origin_cell = _get_origin_cell()

	if _drag_scale_tween:
		_drag_scale_tween.kill()
		_drag_scale_tween = null

	if _can_store_dragged():
		var slot = backpack.free_slot_at(_touch_position)
		backpack.set_accepting(false)
		if slot:
			_store_in_backpack(container, piece, slot)
			return

	var powerup: String = piece.powerup_name
	var valid: bool
	if powerup != "":
		valid = grid_manager.can_place_powerup(powerup, origin_cell.x, origin_cell.y)
	else:
		valid = grid_manager.can_place_shape(piece.shape_cells, origin_cell.x, origin_cell.y)

	if valid:
		if powerup != "":
			# the grid takes the power-up (out of the container) before the container is emptied below
			grid_manager.activate_powerup(powerup, piece.take_powerup(), origin_cell.x, origin_cell.y)
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

	if valid:
		piece_dropped.emit(powerup != "")

# Puts a piece that's being dragged back in its tray slot (e.g. when the game gets paused)
func cancel_drag() -> void:
	if dragging_container == null:
		return
	if _drag_scale_tween:
		_drag_scale_tween.kill()
		_drag_scale_tween = null
	if backpack:
		backpack.set_accepting(false)
	_return_container(dragging_container, dragging_piece)
	grid_manager.clear_highlight()
	dragging_container = null
	dragging_piece = null

# A power-up dragged from the tray (not one already in the backpack) can be dropped in a backpack slot
func _can_store_dragged() -> bool:
	return backpack != null and dragging_piece != null \
		and dragging_piece.get("is_backpack_slot") != true and dragging_piece.powerup_name != ""

# Moves the dragged tray power-up into `slot`: the tray piece is used up, like placing it on the grid
func _store_in_backpack(container: Node2D, piece: CanvasItem, slot: Control) -> void:
	var key: String = piece.powerup_name
	piece.take_powerup()
	for child in container.get_children():
		child.queue_free()
	_return_container(container, piece)
	piece.shape_cells = []

	slot.store(key)
	grid_manager.clear_highlight()
	dragging_container = null
	dragging_piece = null

	Sfx.play("place", 1.2)
	Settings.vibrate(10)
	bottom_tray.check_and_respawn_if_needed()
	piece_dropped.emit(false)

func _return_container(container: Node2D, piece: CanvasItem) -> void:
	container.reparent(piece, false)
	container.position = piece.container_rest_position
	container.scale = piece.container_rest_scale
	container.modulate.a = 1.0
