extends Node2D

@export var circle_scale_factor: float = 1.0  # bump this up/down to resize circle + shape together
@export var shape_scale_factor: float = .2   # shrinks/grows the shape relative to its own circle

@onready var randomized_block_1: Node2D = $CanvasLayer/Control/Randomized1
@onready var randomized_block_2: Node2D = $CanvasLayer/Control/Randomized2
@onready var randomized_block_3: Node2D = $CanvasLayer/Control/Randomized3

var padding = 0.95  # leave some breathing room inside each slot

func set_randomized_blocks() -> void:
	var control: Control = $CanvasLayer/Control
	var width = control.size.x
	var height = control.size.y

	var blocks = [randomized_block_1, randomized_block_2, randomized_block_3]
	var slot_width = width / blocks.size()

	for i in range(blocks.size()):
		var slot_center_x = slot_width * i + slot_width / 2.0
		blocks[i].position = Vector2(slot_center_x, height / 2.0)
		blocks[i].randomize_shape()
		blocks[i].build_piece(shape_scale_factor)

func scale_randomized_blocks() -> void:
	var control: Control = $CanvasLayer/Control
	var slot_width = control.size.x / 3.0
	var slot_height = control.size.y

	var target_diameter = min(slot_width, slot_height) * padding
	var blocks = [randomized_block_1, randomized_block_2, randomized_block_3]

	for block in blocks:
		var circle_sprite: Sprite2D = block.get_node("Sprite2D")
		circle_sprite.scale = Vector2.ONE

		var native_diameter = circle_sprite.texture.get_size().x
		var fit_scale = target_diameter / native_diameter
		block.scale = Vector2(fit_scale, fit_scale) * circle_scale_factor

func check_and_respawn_if_needed() -> void:
	var blocks = [randomized_block_1, randomized_block_2, randomized_block_3]
	for b in blocks:
		if not b.shape_cells.is_empty():
			return

	for b in blocks:
		b.randomize_shape()
		b.build_piece(shape_scale_factor)
