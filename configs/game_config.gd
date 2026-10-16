extends Node

var cell_size: float = 64.0
var cell_gap: float = 1.0
var points_per_block: int = 10

var current_score_multiplier: int = 1

var bomb_radius: int = 2  # blast circle radius in cells, around the cell the bomb is dropped on (2 = 5x5 without the corners)
var bomb_fuse_time: float = 0.8  # seconds the spark takes to burn down the fuse before the blast
var booster_multiplier: int = 2  # how much the booster power-up adds to the score multiplier

# Score that unlocks each backpack slot (slot 1 is always open). Reaching it once in any game unlocks it for good
var backpack_unlock_scores: Array[int] = [0, 20000, 50000, 100000, 500000]
