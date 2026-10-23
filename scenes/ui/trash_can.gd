extends Control

# Trash can at the end of the backpack bar. Drop any power-up on it (from the tray or the backpack) to get rid of it
# and get its ShapeDefinitions "trash_score" in points. It glows while a power-up is dragged, and its lid opens
# when the power-up is right over it.

const Palette = preload("res://configs/palette.gd")

const GLOW := Color(1.0, 0.82, 0.3)  # same as the backpack slots

# Same art style as the backpack (tools/powerup_sprites.py). Both textures share one space: the lid's hinge is at
# LID_HINGE in its own texture and goes on LID_SPOT of the bin's texture.
const BODY: Texture2D = preload("res://assets/powerups/trash_body.png")
const LID: Texture2D = preload("res://assets/powerups/trash_lid.png")
const LID_HINGE := Vector2(0.86, 0.5)
const LID_SPOT := Vector2(0.86, 0.3)
const ART_RATIO := 1.0  # texture size relative to the tile

# true while a power-up is being dragged
var accepting: bool = false:
	set(value):
		accepting = value
		set_process(value or _lid < 1.0)
		queue_redraw()

# true while that power-up is right over the trash can
var hovered: bool = false:
	set(value):
		if hovered != value:
			hovered = value
			set_process(true)
			queue_redraw()

var _pulse: float = 0.0
var _lid: float = 1.0  # 1 closed, 0 fully open (eased towards the hovered state)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	resized.connect(queue_redraw)

# A short gulp when something lands in it
func swallow() -> void:
	pivot_offset = size / 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 0.88), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_pulse += delta
	var target = 0.0 if hovered else 1.0
	_lid = move_toward(_lid, target, delta * 8.0)
	if not accepting and not hovered and _lid >= 1.0:
		set_process(false)
	queue_redraw()

func _draw() -> void:
	var s = minf(size.x, size.y)

	# the same rounded tile as a slot, so it reads as part of the bar
	var tile = StyleBoxFlat.new()
	tile.set_corner_radius_all(int(s * 0.22))
	tile.anti_aliasing = true
	tile.bg_color = Palette.CELL_EMPTY.lightened(0.12) if hovered else Palette.CELL_EMPTY
	if hovered:
		tile.set_border_width_all(4)
		tile.border_color = GLOW
	elif accepting:
		tile.set_border_width_all(3)
		tile.border_color = Color(GLOW, 0.45 + 0.4 * (0.5 + 0.5 * sin(_pulse * 7.0)))
	else:
		tile.set_border_width_all(2)
		tile.border_color = Color(1, 1, 1, 0.14)
	draw_style_box(tile, Rect2(Vector2.ZERO, size))

	# the bin, faded a little while nothing is being dragged
	var side = s * ART_RATIO
	var origin = (size - Vector2(side, side)) / 2.0
	var tint = Color(1, 1, 1, 1.0 if accepting or hovered else 0.75)
	draw_texture_rect(BODY, Rect2(origin, Vector2(side, side)), false, tint)

	# lid, hinged on its right end: it swings up when a power-up hovers over the bin
	var angle = lerpf(0.55, 0.0, _lid)  # positive turns clockwise on screen: the free left end goes up
	draw_set_transform(origin + LID_SPOT * side, angle, Vector2.ONE)
	draw_texture_rect(LID, Rect2(-LID_HINGE * side, Vector2(side, side)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
