extends Node

var cell_size: float = 64.0
var cell_gap: float = 1.0
var points_per_block: int = 10

var current_score_multiplier: int = 1
var max_score_multiplier: int = 10  # the multiplier never goes past this (line clears and the booster)
var fire_multiplier: int = 5  # the multiplier badge catches fire from here, burning hardest at max_score_multiplier

var bomb_radius: int = 2  # blast circle radius in cells, around the cell the bomb is dropped on (2 = 5x5 without the corners)
var bomb_fuse_time: float = 0.8  # seconds the spark takes to burn down the fuse before the blast
var booster_multiplier: int = 2  # how much the booster power-up adds to the score multiplier
var slow_time_factor: float = 0.5  # combo timer speed while the hourglass power-up is active (0.5 = half speed)
var slow_time_duration: float = 30.0  # real seconds the hourglass lasts

# Score that unlocks each backpack slot (slot 1 is always open). Reaching it once in any game unlocks it for good
var backpack_unlock_scores: Array[int] = [0, 35000, 100000, 250000, 500000]
