extends Node2D

# One-shot burst of small square fragments in a tile's color. Frees itself when done.

const LIFETIME: float = 0.55

var color: Color = Color.WHITE
var size: float = 32.0  # tile size, the burst scales with it
var amount: int = 14
var speed: float = 1.0  # 1 = full burst, lower for a soft puff (e.g. placing a piece)

func play() -> void:
	var count = amount if Settings.effects_high else maxi(3, int(amount / 3.0))

	var ramp = Gradient.new()
	ramp.set_color(0, color.lightened(0.35))
	ramp.set_color(1, Color(color, 0.0))

	var particles = CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.amount = count
	particles.lifetime = LIFETIME
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(size, size) * 0.4
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, size * 14.0 * speed)
	particles.initial_velocity_min = size * 2.0 * speed
	particles.initial_velocity_max = size * 5.0 * speed
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.scale_amount_min = size * 0.08
	particles.scale_amount_max = size * 0.18
	particles.color_ramp = ramp
	add_child(particles)
	particles.emitting = true

	get_tree().create_timer(LIFETIME + 0.1, false).timeout.connect(queue_free)
