extends Node

var cell_size: float = 64.0
var cell_gap: float = 1.0
var points_per_block: int = 10

var current_score_multiplier: int = 1

var bomb_spawn_chance: float = 0.1  # chance of each tray slot rolling a bomb instead of a shape
var bomb_radius: int = 1  # 1 = 3x3 area, 2 = 5x5 without the corners, ...
