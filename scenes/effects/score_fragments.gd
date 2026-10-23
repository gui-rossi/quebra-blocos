extends Node2D

# A broken block's fragments: they burst out and fall for a moment, then converge and fly into the score number
# (`target`, global). One node per broken block, freed when the last fragment arrives. `arrived` is called once per
# fragment as it reaches the score, so the HUD can count the score up as they land.

const BURST_TIME := 0.3  # seconds of falling before they head for the score
const FLY_TIME := 0.5  # seconds each fragment takes to reach the score
const FLY_STAGGER := 0.12  # fragments leave a little apart so they stream in

var color: Color = Color.WHITE
var size: float = 32.0  # tile size, fragments scale with it
var amount: int = 8
var target: Vector2 = Vector2.ZERO  # global position of the score number
var arrived: Callable  # called once for each fragment that reaches the score

# How many fragments a broken block makes (fewer with effects set to low)
static func fragment_count() -> int:
	return 8 if Settings.effects_high else 3

var _time: float = 0.0
var _fragments: Array = []  # each: {pos, vel, spin, angle, size, leave, start, control}

func play() -> void:
	for i in amount:
		var dir = Vector2.from_angle(randf_range(-PI, 0.0))  # mostly up and to the sides first
		_fragments.append({
			"pos": global_position + Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35)) * size,
			"vel": dir * randf_range(2.0, 4.0) * size,
			"spin": randf_range(-10.0, 10.0),
			"angle": randf() * TAU,
			"size": randf_range(0.12, 0.22) * size,
			"leave": BURST_TIME + randf() * FLY_STAGGER,
			"start": Vector2.ZERO,
			"control": Vector2.ZERO,
			"done": false,
		})

func _process(delta: float) -> void:
	_time += delta
	var gravity = size * 16.0
	var alive := 0
	for f in _fragments:
		f.angle += f.spin * delta
		if _time < f.leave:
			# falling: a short burst pulled down by gravity
			f.vel.y += gravity * delta
			f.pos += f.vel * delta
			f.start = f.pos
			# the flight curves out sideways a little before swooping up into the score
			f.control = f.pos.lerp(target, 0.35) + Vector2(randf_range(-1.5, 1.5) * size, size * 1.5)
			alive += 1
			continue
		var t = clampf((_time - f.leave) / FLY_TIME, 0.0, 1.0)
		if t >= 1.0:
			if not f.done:
				f.done = true
				if arrived.is_valid():
					arrived.call()
			continue
		alive += 1
		var e = t * t  # speeds up as it goes, like being pulled in
		f.pos = f.start.lerp(f.control, e).lerp(f.control.lerp(target, e), e)
	queue_redraw()
	if alive == 0 and _time > BURST_TIME:
		queue_free()

func _draw() -> void:
	for f in _fragments:
		var t = clampf((_time - f.leave) / FLY_TIME, 0.0, 1.0) if _time >= f.leave else 0.0
		if t >= 1.0:
			continue
		var s = f.size * (1.0 - 0.6 * t)  # shrinks on the way to the score
		var col = color.lightened(0.25 + 0.5 * t)  # brightens as it's pulled in
		draw_set_transform(to_local(f.pos), f.angle, Vector2.ONE)
		draw_rect(Rect2(Vector2(-s, -s) / 2.0, Vector2(s, s)), col)
		draw_rect(Rect2(Vector2(-s, -s) / 2.0, Vector2(s, s * 0.4)), Color(1, 1, 1, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
