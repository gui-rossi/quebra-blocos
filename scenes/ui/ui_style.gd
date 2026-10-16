extends RefCounted

# Shared look for the menus, so every screen builds its widgets the same way

const PRIMARY := Color(0.07, 0.54, 0.7)  # matches the pieces' blue
const PANEL_BG := Color(0.1, 0.12, 0.2, 0.96)
const DIM := Color(0, 0, 0, 0.55)
const TEXT := Color(1, 1, 1)
const TEXT_SOFT := Color(1, 1, 1, 0.7)

static func box(color: Color, radius: int = 22, margin: float = 18.0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin * 1.5
	style.content_margin_right = margin * 1.5
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func button(text: String, color: Color = PRIMARY, font_size: int = 36) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 92)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", box(color))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", box(Color(color.darkened(0.5), 0.6)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	# little press "squish" plus a click and a tick of vibration
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		b.scale = Vector2(0.95, 0.95)
		Sfx.play("click")
		Settings.vibrate(5)
	)
	b.button_up.connect(func(): b.scale = Vector2.ONE)
	return b

static func label(text: String, font_size: int, color: Color = TEXT, outline: int = 0) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("outline_size", outline)
	return l

static func panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(PANEL_BG, 32, 32.0))
	return p

static func vbox(separation: int = 20) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", separation)
	return v

# A full-screen layer: dimmed background with `content` centered on top. Blocks touches to the game below.
static func overlay(content: Control) -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim = ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.add_child(content)
	return root

# Pops a control in from small, for panels appearing
static func pop_in(control: Control) -> void:
	control.modulate.a = 0.0
	var tween = control.create_tween().set_parallel()
	# the pivot is set on every step: the control may not have its final size yet on the first frame
	tween.tween_method(func(s: float):
		control.pivot_offset = control.size / 2.0
		control.scale = Vector2(s, s)
	, 0.85, 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.12)
