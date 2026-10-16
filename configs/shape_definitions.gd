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

# Power-ups that can show up in a tray slot instead of a shape (their effects are in managers/powerups.gd)
#   visual:          scene (.tscn) or script (.gd) drawing it; it has fit_to(diameter), start_idle() and activate(target)
#   cells:           grid cells the piece occupies while dragged, offsets from origin (0,0)
#   spawn_chance:    chance of a tray slot rolling this power-up instead of a shape
#   tray_size_ratio: size of its body inside the tray circle, relative to the circle's texture
#   drag_size_cells: on-screen size of its body while dragged, in grid cells (0 = keep the tray size)
#   drag_alpha:      opacity while dragged
#   ghost:           color of its preview on the grid
const POWERUPS := {
	# blows up a round area around the cell it's dropped on (GameConfig.bomb_radius)
	"bomb": {
		"visual": "res://scenes/powerups/powerup_bomb.tscn",
		"cells": [Vector2i(0,0)],  # a single cell: the target, also keeps the slot "in use" for the tray
		"spawn_chance": 0.06,
		"tray_size_ratio": 0.42,
		"drag_size_cells": 0.9,  # big in the tray, shrinks to about a cell so the preview stays visible
		"drag_alpha": 0.85,
		"ghost": Color(1, 0.45, 0.1),
	},
	# clears the whole row and column of the cell it's dropped on
	"laser": {
		"visual": "res://scenes/powerups/powerup_laser.gd",
		"cells": [Vector2i(0,0)],
		"spawn_chance": 0.05,
		"tray_size_ratio": 0.42,
		"drag_size_cells": 0.9,
		"drag_alpha": 0.9,
		"ghost": Color(0.35, 0.95, 1.0),
	},
	# clears every block with the same color as the block it's dropped on
	"prism": {
		"visual": "res://scenes/powerups/powerup_prism.gd",
		"cells": [Vector2i(0,0)],
		"spawn_chance": 0.04,
		"tray_size_ratio": 0.42,
		"drag_size_cells": 0.9,
		"drag_alpha": 0.9,
		"ghost": Color(1, 1, 1),
	},
	# drop anywhere on the board: the multiplier goes up by GameConfig.booster_multiplier and the combo timer refills
	"booster": {
		"visual": "res://scenes/powerups/powerup_booster.gd",
		"cells": [Vector2i(0,0)],
		"spawn_chance": 0.04,
		"tray_size_ratio": 0.42,
		"drag_size_cells": 0.9,
		"drag_alpha": 0.9,
		"ghost": Color(1, 0.82, 0.25),
	},
}

# Opacity of a regular shape while dragged
const SHAPE_DRAG_ALPHA: float = 0.95

func get_random_shape_name() -> String:
	var keys = SHAPES.keys()
	return keys[randi() % keys.size()]

func get_shape(shape_name: String) -> Array:
	return SHAPES.get(shape_name, [Vector2i(0,0)])

# Rolls whether a tray slot gets a power-up (the chances added up) and which one (weighted by its chance).
# Returns "" for a regular shape.
func roll_powerup_name() -> String:
	var total := 0.0
	for key in POWERUPS:
		total += POWERUPS[key].spawn_chance
	var roll = randf()
	if roll >= total:
		return ""
	for key in POWERUPS:
		roll -= POWERUPS[key].spawn_chance
		if roll < 0.0:
			return key
	return ""

func get_powerup(powerup_name: String) -> Dictionary:
	return POWERUPS.get(powerup_name, {})

# A new node drawing the power-up (for a tray slot or the backpack)
func make_powerup_visual(powerup_name: String) -> Node2D:
	var path: String = get_powerup(powerup_name).get("visual", "")
	if path == "":
		return null
	var resource = load(path)
	return resource.instantiate() if resource is PackedScene else resource.new()
