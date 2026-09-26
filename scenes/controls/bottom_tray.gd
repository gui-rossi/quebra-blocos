extends Node2D

@onready var randomized_block_1: Node2D = $CanvasLayer/Control/Randomized1
@onready var randomized_block_2: Node2D = $CanvasLayer/Control/Randomized2
@onready var randomized_block_3: Node2D = $CanvasLayer/Control/Randomized3

var padding = 0.95  # leave some breathing room inside each slot
@export var circle_scale_factor: float = 1
@export var shape_scale_factor: float = .5  # NEW - shrinks the shape relative to its circle

func set_randomized_blocks() -> void:
	var control: Control = $CanvasLayer/Control
	var width = control.size.x
	var height = control.size.y

	var blocks = [randomized_block_1, randomized_block_2, randomized_block_3]
	var slot_width = width / blocks.size()

	for i in range(blocks.size()):
		var slot_center_x = slot_width * i + slot_width / 2.0
		blocks[i].position = Vector2(slot_center_x, height / 2.0)
		blocks[i].randomize_shape()   # NEW
		blocks[i].build_piece(shape_scale_factor)       # NEW - now runs after GameConfig.cell_size is correct

func scale_randomized_blocks() -> void:
	var control: Control = $CanvasLayer/Control
	var slot_width = control.size.x / 3.0
	var slot_height = control.size.y

	var target_diameter = min(slot_width, slot_height) * padding
	var blocks = [randomized_block_1, randomized_block_2, randomized_block_3]

	for block in blocks:
		var circle_sprite: Sprite2D = block.get_node("Sprite2D")
		var native_diameter = circle_sprite.texture.get_size().x
		var scale_factor = target_diameter / native_diameter
		circle_sprite.scale = Vector2(scale_factor, scale_factor)  # scale the sprite, not block
