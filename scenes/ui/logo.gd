extends Control

# The game's logo on the main menu: "B", an L piece made of blocks for the "L", the backpack for the "O", then "CKPACK".
# Static (no animation). Letters, blocks and backpack all sit on the same baseline, and the whole word shrinks to fit
# the screen width if needed.

const Palette = preload("res://configs/palette.gd")
const BlockVisual = preload("res://scenes/blocks/block_visual.gd")
const BACKPACK: Texture2D = preload("res://assets/ui/backpack.png")

const TEXT_COLOR := Color(1, 0.9, 0.35)
const OUTLINE_COLOR := Color(0, 0, 0, 0.6)
const L_COLOR := Color(0.2, 0.78, 0.92)  # cyan, like the L piece on the app icon

# How the backpack sprite fills its 192x192 texture (tools/backpack_icons.py): the bag goes from 0.08 to 0.92
# across and from 0.11 to 0.89 down, so these place the bag itself rather than the whole texture
const BAG_LEFT := 0.08
const BAG_WIDTH := 0.84
const BAG_TOP := 0.11
const BAG_BOTTOM := 0.89

@export var font_size: int = 100
@export var max_width: float = 660.0  # the word shrinks to fit this
@export var outline: int = 16

var _blocks: Array[Control] = []
var _layout := {}  # computed in _update_layout, used by _draw

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var block = BlockVisual.new()
		block.color = L_COLOR
		add_child(block)
		_blocks.append(block)
	resized.connect(_update_layout)
	_update_layout()

func _update_layout() -> void:
	var font = get_theme_default_font()
	var fs = font_size
	var parts = _measure(font, fs)
	if parts.width > max_width:
		fs = int(fs * max_width / parts.width)
		parts = _measure(font, fs)

	custom_minimum_size = Vector2(parts.width, parts.height)
	var origin_x = (size.x - parts.width) / 2.0
	var baseline = parts.baseline + maxf(0.0, (size.y - parts.height) / 2.0)

	# the L: three blocks up the left side and one at the bottom right, standing on the baseline
	var b = parts.block
	var lx = origin_x + parts.l_x
	var cells = [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)]
	for i in 4:
		_blocks[i].position = Vector2(lx + cells[i].x * b, baseline - (3 - cells[i].y) * b)
		_blocks[i].size = Vector2(b, b)

	_layout = parts.merged({"font": font, "fs": fs, "origin_x": origin_x, "baseline": baseline}, true)
	queue_redraw()

# Widths and positions for a font size, relative to the left edge of the word
func _measure(font: Font, fs: int) -> Dictionary:
	var cap = fs * 0.72  # cap height of the default font
	var gap = fs * 0.06
	var b_width = font.get_string_size("B", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var block = cap / 3.0
	var bag_texture = cap * 1.2 / (BAG_BOTTOM - BAG_TOP)  # the bag a bit taller than the letters
	var rest_width = font.get_string_size("CKPACK", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

	var l_x = b_width + gap
	var bag_x = l_x + block * 2.0 + gap * 1.5
	var rest_x = bag_x + bag_texture * BAG_WIDTH + gap
	var ascent = font.get_ascent(fs)
	return {
		"width": rest_x + rest_width,
		"height": maxf(ascent, cap * 1.2 + fs * 0.1) + font.get_descent(fs),
		"baseline": maxf(ascent, cap * 1.2 + fs * 0.1),
		"block": block,
		"bag_texture": bag_texture,
		"l_x": l_x,
		"bag_x": bag_x,
		"rest_x": rest_x,
	}

func _draw() -> void:
	if _layout.is_empty():
		return
	var font: Font = _layout.font
	var fs: int = _layout.fs
	var x0: float = _layout.origin_x
	var baseline: float = _layout.baseline

	# dark outline behind the L blocks, matching the letters' outline
	var b: float = _layout.block
	var lx = x0 + _layout.l_x
	var radius = int(b * 0.3)
	var shape = StyleBoxFlat.new()
	shape.bg_color = OUTLINE_COLOR
	shape.set_corner_radius_all(radius)
	shape.anti_aliasing = true
	var grow = outline * 0.45
	draw_style_box(shape, Rect2(lx - grow, baseline - 3.0 * b - grow, b + grow * 2.0, 3.0 * b + grow * 2.0))
	draw_style_box(shape, Rect2(lx - grow, baseline - b - grow, 2.0 * b + grow * 2.0, b + grow * 2.0))

	_draw_text("B", Vector2(x0, baseline), font, fs)
	_draw_text("CKPACK", Vector2(x0 + _layout.rest_x, baseline), font, fs)

	# the backpack as the "O", its bottom on the baseline
	var t: float = _layout.bag_texture
	var bag_pos = Vector2(x0 + _layout.bag_x - t * BAG_LEFT, baseline - t * BAG_BOTTOM)
	draw_texture_rect(BACKPACK, Rect2(bag_pos, Vector2(t, t)), false)

func _draw_text(text: String, pos: Vector2, font: Font, fs: int) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE_COLOR)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TEXT_COLOR)
