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

func get_random_shape_name() -> String:
	var keys = SHAPES.keys()
	return keys[randi() % keys.size()]

func get_shape(shape_name: String) -> Array:
	return SHAPES.get(shape_name, [Vector2i(0,0)])
