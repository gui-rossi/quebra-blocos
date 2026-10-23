extends Node2D

# Base for the sprite power-ups (laser, prism, booster, hourglass). Same interface as the bomb scene:
#   fit_to(diameter)  sizes it, start_idle() / stop_idle() for the tray animation,
#   activate(target)  flies to `target` (global), plays its own flair and frees itself; the grid applies the effect after.
# Subclasses set `sprite` (made by tools/powerup_sprites.py, same art style as the backpack) and `halo_color`,
# and can draw extras on top in _draw_icon() or override _flair().

const INK := Color(0.12, 0.06, 0.04)

# The sprites' artwork fills about this much of their texture, so the texture is drawn bigger than the body
const SPRITE_CONTENT_RATIO := 0.8

var sprite: Texture2D = null
var halo_color: Color = Color(1, 1, 1)

var diameter: float = 64.0  # current body diameter, in local units
var glow: float = 0.0:  # 0..1, animated while idle
	set(value):
		glow = value
		queue_redraw()

var _idle_tween: Tween

func fit_to(body_diameter: float) -> void:
	diameter = body_diameter
	queue_redraw()

# Gentle breathing glow while waiting in the tray or the backpack
func start_idle() -> void:
	stop_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "glow", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(self, "glow", 0.0, 0.7).set_trans(Tween.TRANS_SINE)

func stop_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
	glow = 0.0

func activate(target: Vector2) -> void:
	stop_idle()
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, 0.08).set_ease(Tween.EASE_OUT)
	await tween.finished
	await _flair()
	queue_free()

# Default flair: swells up bright and fades
func _flair() -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", scale * 1.6, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.18)
	await tween.finished

func _draw() -> void:
	var r = diameter / 2.0
	# a soft halo that breathes with `glow` while idle
	draw_circle(Vector2.ZERO, r * (1.0 + 0.12 * glow), Color(halo_color, 0.06 + 0.12 * glow))
	if sprite:
		var side = diameter / SPRITE_CONTENT_RATIO
		draw_texture_rect(sprite, Rect2(Vector2(-side, -side) / 2.0, Vector2(side, side)), false)
	_draw_icon(r)

# Extras drawn over the sprite (e.g. the booster's "+2")
func _draw_icon(_radius: float) -> void:
	pass

# Helpers for subclasses

func _polygon(points: PackedVector2Array, color: Color, outline_width: float = 0.0) -> void:
	if outline_width > 0.0:
		var closed = points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, INK, outline_width, true)
	draw_colored_polygon(points, color)

func _star_points(radius: float, inner: float, count: int, rotation_offset: float = -PI / 2.0) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(count * 2):
		var r = radius if i % 2 == 0 else inner
		var a = rotation_offset + i * PI / count
		points.append(Vector2(cos(a), sin(a)) * r)
	return points
