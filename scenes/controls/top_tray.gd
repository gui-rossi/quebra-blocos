extends Node2D

# HUD at the top: settings gear (left), score and best score (center), multiplier badge with combo timer ring (right).
# The widgets are built here and anchored to the tray's Control, which main.gd sizes.

signal settings_pressed

const GearButton = preload("res://scenes/ui/gear_button.gd")
const ComboBadge = preload("res://scenes/ui/combo_badge.gd")

const COMBO_SOUND_COOLDOWN_MS := 150  # two lines cleared at once bump the multiplier twice, play the sound once

@onready var control: Control = $CanvasLayer/Control

var _score_label: Label
var _best_label: Label
var _badge: Control
var _displayed_score: float = 0.0
var _score_tween: Tween
var _punch_tween: Tween
var _last_combo_sound_ms: int = 0

func _ready() -> void:
	var gear = GearButton.new()
	control.add_child(gear)
	gear.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	gear.pressed.connect(func(): settings_pressed.emit())

	var score_box = VBoxContainer.new()
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_box.add_theme_constant_override("separation", -8)
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label = _make_label("0", 60, Color.WHITE, 10)
	_best_label = _make_label("BEST 0", 22, Color(1, 1, 1, 0.65), 4)
	score_box.add_child(_score_label)
	score_box.add_child(_best_label)
	control.add_child(score_box)
	score_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	score_box.grow_horizontal = Control.GROW_DIRECTION_BOTH  # stays centered as the number gets wider
	score_box.grow_vertical = Control.GROW_DIRECTION_BOTH

	_badge = ComboBadge.new()
	control.add_child(_badge)
	_badge.custom_minimum_size = Vector2(104, 104)
	_badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	_badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN

func set_score(new_score: int) -> void:
	var gained = new_score > int(_displayed_score)

	# count up to the new score instead of jumping
	if _score_tween:
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_method(_show_score, _displayed_score, float(new_score), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if gained:
		_punch_score()

func set_best(best: int) -> void:
	_best_label.text = "BEST %d" % best

func set_combo(new_combo: int) -> void:
	_badge.set_multiplier(new_combo)

	# from the second line of a streak on, a rising "combo" sound on top of the line chime
	var now = Time.get_ticks_msec()
	if new_combo >= 3 and now - _last_combo_sound_ms > COMBO_SOUND_COOLDOWN_MS:
		_last_combo_sound_ms = now
		Sfx.play("combo_up", minf(1.0 + 0.05 * (new_combo - 3), 1.6))

func reset_combo() -> void:
	_badge.hide_badge()

func update_combo_timer(remaining: float, total: float = 5.0) -> void:
	_badge.set_time_fraction(remaining / total)

func _show_score(value: float) -> void:
	_displayed_score = value
	_score_label.text = "%d" % int(value)

func _punch_score() -> void:
	_score_label.pivot_offset = _score_label.size / 2.0
	if _punch_tween:
		_punch_tween.kill()
	_punch_tween = create_tween()
	_punch_tween.tween_property(_score_label, "scale", Vector2(1.25, 1.25), 0.08).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(_score_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _make_label(text: String, font_size: int, color: Color, outline: int) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", outline)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
