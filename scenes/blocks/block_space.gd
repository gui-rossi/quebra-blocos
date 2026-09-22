@tool
extends Node2D

@export var block_size: Vector2:
	get:
		return $Control.size if is_node_ready() else Vector2.ZERO
	set(value):
		if is_node_ready():
			$Control.size = value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
