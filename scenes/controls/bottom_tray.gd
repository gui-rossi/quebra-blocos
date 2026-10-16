extends Node2D

@export var circle_scale_factor: float = 1.0  # bump this up/down to resize circle + shape together
@export var shape_scale_factor: float = .2   # shrinks/grows the shape relative to its own circle

@onready var randomized_block_1: Node2D = $CanvasLayer/Control/Randomized1
@onready var randomized_block_2: Node2D = $CanvasLayer/Control/Randomized2
@onready var randomized_block_3: Node2D = $CanvasLayer/Control/Randomized3

var padding = 0.95  # leave some breathing room inside each slot

func get_pieces() -> Array:
	return [randomized_block_1, randomized_block_2, randomized_block_3]

func set_randomized_blocks() -> void:
	_position_blocks()
	_roll_batch()

# Rolls a new batch of 3 pieces: at most 1 power-up among them. The slots roll in a random order,
# so the power-up isn't more likely to land in the first slot.
func _roll_batch() -> void:
	var order = get_pieces().duplicate()
	order.shuffle()
	var powerup_allowed := true
	for block in order:
		block.randomize_shape(powerup_allowed)
		if block.powerup_name != "":
			powerup_allowed = false
	for block in get_pieces():
		block.build_piece(shape_scale_factor)

# Rebuilds the three slots from get_slots_save() data
func restore_slots(slots: Array) -> void:
	_position_blocks()
	var blocks = get_pieces()
	for i in range(blocks.size()):
		var slot: Dictionary = slots[i] if i < slots.size() else {"used": true}
		blocks[i].set_from_save(slot)
		if not blocks[i].shape_cells.is_empty():
			blocks[i].build_piece(shape_scale_factor)
	check_and_respawn_if_needed()  # in case every slot was saved as used

func get_slots_save() -> Array:
	return get_pieces().map(func(block): return block.to_save())

func _position_blocks() -> void:
	var control: Control = $CanvasLayer/Control
	var blocks = get_pieces()
	var slot_width = control.size.x / blocks.size()

	for i in range(blocks.size()):
		var slot_center_x = slot_width * i + slot_width / 2.0
		blocks[i].position = Vector2(slot_center_x, control.size.y / 2.0)

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

	_roll_batch()
