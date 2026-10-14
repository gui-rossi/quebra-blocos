extends Node2D

# Diameter of the bomb's round body in the texture, in pixels (fuse and shadow excluded)
const BODY_DIAMETER_PX: float = 98.0

# Fuse path in the sprite's local space (texture pixels), from the bomb's cap up to the burning tip
const FUSE_PATH = [
	Vector2(8, -47), Vector2(11, -50), Vector2(15, -53), Vector2(19, -56), Vector2(21, -59),
	Vector2(19, -63), Vector2(14, -66), Vector2(6, -70), Vector2(-1, -74), Vector2(-5, -78),
	Vector2(-4, -82), Vector2(1, -85), Vector2(7, -88), Vector2(15, -91),
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var fuse: Line2D = $Sprite2D/Fuse
@onready var spark: Node2D = $Sprite2D/Spark

var diameter: float = BODY_DIAMETER_PX  # current body diameter, in local units
var _sprite_scale: Vector2 = Vector2.ONE
var _idle_tween: Tween
var _fuse_lengths: Array[float] = []  # distance along the fuse up to each point of FUSE_PATH

func _ready() -> void:
	_fuse_lengths = [0.0]
	for i in range(1, FUSE_PATH.size()):
		_fuse_lengths.append(_fuse_lengths[i - 1] + FUSE_PATH[i - 1].distance_to(FUSE_PATH[i]))
	_set_fuse_remaining(1.0)

# Scales the sprite so the bomb's body is `body_diameter` wide
func fit_to(body_diameter: float) -> void:
	diameter = body_diameter
	var s = body_diameter / BODY_DIAMETER_PX
	_sprite_scale = Vector2(s, s)
	sprite.scale = _sprite_scale

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

# Snaps onto `target` (global), burns the fuse down into the bomb, swells up glowing red, then frees itself
func detonate(target: Vector2) -> void:
	stop_idle()
	modulate = Color.WHITE

	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.08).set_ease(Tween.EASE_OUT)
	# the spark travels down the fuse while the bomb throbs faster and heats up
	tween.tween_method(_set_fuse_remaining, 1.0, 0.0, GameConfig.bomb_fuse_time)
	tween.parallel().tween_method(_throb, 0.0, 1.0, GameConfig.bomb_fuse_time)
	tween.tween_callback(spark.hide)
	tween.tween_property(self, "scale", scale * 1.4, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(1.8, 0.5, 0.3), 0.15)
	await tween.finished

	queue_free()

# Cuts the fuse to `fraction` of its length (measured from the cap) and puts the spark on its tip
func _set_fuse_remaining(fraction: float) -> void:
	var target = _fuse_lengths[-1] * fraction
	var points = PackedVector2Array([FUSE_PATH[0]])
	var tip = FUSE_PATH[0]

	for i in range(1, FUSE_PATH.size()):
		if _fuse_lengths[i] <= target:
			tip = FUSE_PATH[i]
		else:
			var t = (target - _fuse_lengths[i - 1]) / (_fuse_lengths[i] - _fuse_lengths[i - 1])
			tip = FUSE_PATH[i - 1].lerp(FUSE_PATH[i], t)
			points.append(tip)
			break
		points.append(tip)

	fuse.points = points
	spark.position = tip

# `progress` 0 -> 1 over the fuse time: pulses get faster and the body turns red
func _throb(progress: float) -> void:
	var pulse = sin(progress * progress * 40.0)
	sprite.scale = _sprite_scale * (1.0 + 0.06 * progress * pulse)
	sprite.self_modulate = Color.WHITE.lerp(Color(1.6, 0.6, 0.5), progress)
