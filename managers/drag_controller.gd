extends Node2D

@export var grid_manager_path: NodePath
@export var bottom_tray_path: NodePath
@export var drag_layer_path: NodePath  # a CanvasLayer with a high Layer value, so dragged piece renders on top

var grid_manager: Node2D
var bottom_tray: Node2D
var drag_layer: CanvasLayer

var dragging_piece: Node2D = null
var drag_original_parent: Node = null
var drag_original_position: Vector2

func _ready() -> void:
	grid_manager = get_node(grid_manager_path)
	bottom_tray = get_node(bottom_tray_path)
	drag_layer = get_node(drag_layer_path)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and dragging_piece == null:
			_try_start_drag(event.position)
		elif not event.pressed and dragging_piece != null:
			_end_drag()

	elif event is InputEventScreenDrag:
		if dragging_piece:
			dragging_piece.global_position = event.position
			var cell = grid_manager.world_to_cell(dragging_piece.global_position)
			grid_manager.show_highlight(dragging_piece.shape_cells, cell.x, cell.y)

func _try_start_drag(pos: Vector2) -> void:
	var pieces = [bottom_tray.randomized_block_1, bottom_tray.randomized_block_2, bottom_tray.randomized_block_3]
	for piece in pieces:
		var circle_sprite: Sprite2D = piece.get_node("Sprite2D")
		var radius = (circle_sprite.texture.get_size().x / 2.0) * piece.scale.x
		if pos.distance_to(piece.global_position) <= radius:
			_start_drag(piece)
			return

func _start_drag(piece: Node2D) -> void:
	dragging_piece = piece
	drag_original_parent = piece.get_parent()
	drag_original_position = piece.position

	piece.reparent(drag_layer, true)  # keep_global_transform = true, no visual jump
	piece.modulate.a = 0.6

func _end_drag() -> void:
	var piece = dragging_piece
	var cell = grid_manager.world_to_cell(piece.global_position)
	var valid = grid_manager.can_place_shape(piece.shape_cells, cell.x, cell.y)

	if valid:
		grid_manager.place_shape(piece.shape_cells, cell.x, cell.y, piece.piece_color)
		piece.reparent(drag_original_parent, false)
		piece.position = drag_original_position
		piece.modulate.a = 1.0
		piece.randomize_shape()
		piece.build_piece(bottom_tray.shape_scale_factor)
	else:
		piece.reparent(drag_original_parent, false)
		piece.position = drag_original_position
		piece.modulate.a = 1.0

	grid_manager.clear_highlight()
	dragging_piece = null
