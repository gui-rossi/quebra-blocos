extends Node

# Matches the pieces generated earlier — cell offsets from origin (0,0)
const SHAPES := {
	"single":       [Vector2i(0,0)],
	"domino_h":     [Vector2i(0,0), Vector2i(1,0)],
	"domino_v":     [Vector2i(0,0), Vector2i(0,1)],
	"line3_h":      [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	"line3_v":      [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	"line4_h":      [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	"line4_v":      [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	"square_2x2":   [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	"t_up":         [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	"t_down":       [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
	"s_shape":      [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	"z_shape":      [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	"l_vertical":   [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	"l_horizontal": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1)],
	"j_vertical":   [Vector2i(1,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
	"j_horizontal": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(2,1)],
	"square_3x3":   [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	"line5_h":      [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	"line5_v":      [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
	"corner_l":     [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(2,0)],
	"corner_j":     [Vector2i(2,0), Vector2i(2,1), Vector2i(2,2), Vector2i(1,0), Vector2i(0,0)],
}

# Power-ups that can show up in a tray slot instead of a shape
#   cells:           grid cells the piece occupies while dragged, offsets from origin (0,0)
#   spawn_chance:    chance of each tray slot rolling this power-up instead of a shape
#   tray_size_ratio: size of its body inside the tray circle, relative to the circle's texture
#   drag_size_cells: on-screen size of its body while dragged, in grid cells (0 = keep the tray size)
#   drag_alpha:      opacity while dragged
const POWERUPS := {
	"bomb": {
		"cells": [Vector2i(0,0)],  # a single cell: the blast center, also keeps the slot "in use" for the tray
		"spawn_chance": 0.1,
		"tray_size_ratio": 0.42,
		"drag_size_cells": 0.9,  # big in the tray, shrinks to about a cell so the blast area stays visible
		"drag_alpha": 0.85,
	},
}

# Opacity of a regular shape while dragged
const SHAPE_DRAG_ALPHA: float = 0.6

func get_random_shape_name() -> String:
	var keys = SHAPES.keys()
	return keys[randi() % keys.size()]

func get_shape(shape_name: String) -> Array:
	return SHAPES.get(shape_name, [Vector2i(0,0)])

# Rolls each power-up's spawn chance in turn, returns the first that hits or "" for a regular shape
func roll_powerup_name() -> String:
	for powerup_name in POWERUPS:
		if randf() < POWERUPS[powerup_name].spawn_chance:
			return powerup_name
	return ""

func get_powerup(powerup_name: String) -> Dictionary:
	return POWERUPS.get(powerup_name, {})
