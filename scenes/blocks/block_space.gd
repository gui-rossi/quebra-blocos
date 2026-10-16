@tool
extends Node2D

@export var block_size: Vector2:
	get:
		return $Control.size if is_node_ready() else Vector2.ZERO
	set(value):
		if is_node_ready():
			$Control.size = value

# Color of the block (use this instead of modulate, modulate stays free for effects like flashes and fades)
var block_color: Color = Color(0.27, 0.5, 0.96):
	set(value):
		block_color = value
		if is_node_ready():
			$Control/Visual.color = value

# True for an empty grid cell instead of a block
var empty: bool = false:
	set(value):
		empty = value
		if is_node_ready():
			$Control/Visual.empty = value

func _ready() -> void:
	$Control/Visual.color = block_color
	$Control/Visual.empty = empty
