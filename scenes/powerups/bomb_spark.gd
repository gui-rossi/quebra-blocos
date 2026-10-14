extends Node2D

# Burning tip of the fuse: a flickering glow with spinning rays

const RAY_COUNT: int = 8
const SPIN_SPEED: float = 8.0  # radians per second

var radius: float = 12.0
var _flicker: float = 1.0

func _process(delta: float) -> void:
	_flicker = randf_range(0.8, 1.15)
	rotation += SPIN_SPEED * delta
	queue_redraw()

func _draw() -> void:
	var r = radius * _flicker
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.45, 0.05, 0.35))
	draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.7, 0.15, 0.8))
	draw_circle(Vector2.ZERO, r * 0.3, Color(1.0, 1.0, 0.8))
	for i in RAY_COUNT:
		var dir = Vector2.RIGHT.rotated(TAU * i / RAY_COUNT)
		var length = r * (1.1 if i % 2 == 0 else 0.75)
		draw_line(dir * r * 0.3, dir * length, Color(1.0, 0.85, 0.3), 2.0, true)
