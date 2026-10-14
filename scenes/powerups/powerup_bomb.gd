extends Node2D

# Diameter of the bomb's round body in the texture, in pixels (fuse and shadow excluded)
const BODY_DIAMETER_PX: float = 98.0

@onready var sprite: Sprite2D = $Sprite2D

var diameter: float = BODY_DIAMETER_PX  # current body diameter, in local units
var _idle_tween: Tween

# Scales the sprite so the bomb's body is `body_diameter` wide
func fit_to(body_diameter: float) -> void:
	diameter = body_diameter
	var s = body_diameter / BODY_DIAMETER_PX
	sprite.scale = Vector2(s, s)

# Gentle wobble while waiting in the tray / being dragged
func start_idle() -> void:
	stop_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "rotation_degrees", 8.0, 0.3).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "rotation_degrees", -8.0, 0.6).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

func stop_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
	sprite.rotation = 0.0

# Snaps onto `target` (global), swells up glowing red, then frees itself
func detonate(target: Vector2) -> void:
	stop_idle()
	modulate = Color.WHITE

	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.4, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1.8, 0.5, 0.3), 0.18)
	await tween.finished

	queue_free()
