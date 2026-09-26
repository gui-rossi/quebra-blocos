# Main.gd
extends Node

@export var top_tray_ratio: float = 0.10
@export var bottom_tray_ratio: float = 0.25

@onready var top_tray: Node2D = $CanvasLayer/TopTray
@onready var bottom_tray: Node2D = $CanvasLayer/BottomTray
@onready var grid_manager: Node2D = $CanvasLayer/GridManager

func _ready() -> void:
	layout()

func layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var top_height = viewport_size.y * top_tray_ratio
	var bottom_height = viewport_size.y * bottom_tray_ratio

	top_tray.get_node("CanvasLayer/Control").size = Vector2(viewport_size.x, top_height)
	top_tray.get_node("CanvasLayer/Control").position = Vector2.ZERO

	bottom_tray.get_node("CanvasLayer/Control").size = Vector2(viewport_size.x, bottom_height)
	bottom_tray.get_node("CanvasLayer/Control").position = Vector2(0, viewport_size.y - bottom_height)

	grid_manager.set_reserved_space(top_height, bottom_height)
	
	bottom_tray.get_node("CanvasLayer/Control").size = Vector2(viewport_size.x, bottom_height)
	bottom_tray.get_node("CanvasLayer/Control").position = Vector2(0, viewport_size.y - bottom_height)
	bottom_tray.set_randomized_blocks() 
	bottom_tray.scale_randomized_blocks()
