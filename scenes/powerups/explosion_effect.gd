extends Node2D

# One-shot explosion: a flash, an expanding shockwave ring and sparks. Frees itself when done.

const DURATION: float = 0.45
const SPARKS_LIFETIME: float = 0.6

var max_radius: float = 100.0

var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

func play() -> void:
	_spawn_sparks()

	var tween = create_tween()
	tween.tween_property(self, "progress", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(SPARKS_LIFETIME - DURATION)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var fade = 1.0 - progress

	# fireball: grows a bit and fades out
	draw_circle(Vector2.ZERO, max_radius * (0.4 + 0.5 * progress), Color(1.0, 0.55, 0.1, 0.6 * fade))
	# hot core: shrinks away fast
	draw_circle(Vector2.ZERO, max_radius * 0.35 * fade, Color(1.0, 0.95, 0.7, fade))
	# shockwave ring: reaches the edge of the blast area
	draw_arc(Vector2.ZERO, max_radius * progress, 0.0, TAU, 48, Color(1.0, 0.8, 0.4, fade), max(2.0, 12.0 * fade), true)

func _spawn_sparks() -> void:
	var ramp = Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.6))
	ramp.set_color(1, Color(1.0, 0.25, 0.0, 0.0))

	var sparks = CPUParticles2D.new()
	sparks.one_shot = true
	sparks.emitting = false
	sparks.amount = 40
	sparks.lifetime = SPARKS_LIFETIME
	sparks.explosiveness = 1.0
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = max_radius * 1.5
	sparks.initial_velocity_max = max_radius * 3.0
	sparks.damping_min = max_radius * 2.0
	sparks.damping_max = max_radius * 3.0
	sparks.scale_amount_min = 3.0
	sparks.scale_amount_max = 7.0
	sparks.color_ramp = ramp
	add_child(sparks)
	sparks.emitting = true
