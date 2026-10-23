extends Node2D

# HUD at the top: settings gear (left), score and best score (center), multiplier badge with combo timer ring (right).
# The widgets are built here and anchored to the tray's Control, which main.gd sizes.

signal settings_pressed

const GearButton = preload("res://scenes/ui/gear_button.gd")
const ComboBadge = preload("res://scenes/ui/combo_badge.gd")
const CrownIcon = preload("res://scenes/ui/crown_icon.gd")
const NumberFormat = preload("res://configs/number_format.gd")

const HUD_ITEM_RATIO := 0.78  # gear and badge size, relative to the tray's height
const HUD_ITEM_MAX := 100.0
const BEST_FONT_SIZE := 22
const SIDE_MARGIN := 20.0  # used until main.gd lines the sides up with the board

const COMBO_SOUND_COOLDOWN_MS := 150  # two lines cleared at once bump the multiplier twice, play the sound once

@onready var control: Control = $CanvasLayer/Control

var _gear: Button
var _score_label: Label
var _best_label: Label
var _badge: Control
var _displayed_score: float = 0.0
var _score_tween: Tween
var _punch_tween: Tween
var _last_combo_sound_ms: int = 0
var _best_value: int = 0
var _target_score: int = 0  # the real score; the number shown can lag behind while fragments are flying in
var _fragments_in_flight: int = 0
var _last_arrival_punch_ms: int = 0
var _flight_id: int = 0  # bumped on every launch and arrival, for the catch-up below
var _side_left: float = -1.0  # x where the gear starts, -1 = use SIDE_MARGIN
var _side_right: float = -1.0  # x where the badge ends, -1 = use SIDE_MARGIN

func _ready() -> void:
	_gear = GearButton.new()
	control.add_child(_gear)
	_gear.pressed.connect(func(): settings_pressed.emit())

	var score_box = VBoxContainer.new()
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_box.add_theme_constant_override("separation", -8)
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label = _make_label("0", 60, Color.WHITE, 10)
	_best_label = _make_label("", BEST_FONT_SIZE, Color(1, 1, 1, 0.65), 4)
	score_box.add_child(_score_label)

	# a small crown to the left of the best score, so the record reads at a glance in any language
	var best_row = HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.add_theme_constant_override("separation", 6)
	best_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crown = CrownIcon.new()
	crown.custom_minimum_size = Vector2(BEST_FONT_SIZE * 1.25, BEST_FONT_SIZE * 1.0)
	crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	best_row.add_child(crown)
	best_row.add_child(_best_label)
	score_box.add_child(best_row)
	control.add_child(score_box)
	score_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	score_box.grow_horizontal = Control.GROW_DIRECTION_BOTH  # stays centered as the number gets wider
	score_box.grow_vertical = Control.GROW_DIRECTION_BOTH

	_badge = ComboBadge.new()
	control.add_child(_badge)

	control.resized.connect(_layout_sides)
	_layout_sides()

# Lines the gear's left edge and the badge's right edge up with the board below
func align_sides(left: float, right: float) -> void:
	_side_left = left
	_side_right = right
	_layout_sides()

# Gear on the left and badge on the right: same size, both centered vertically in the tray
func _layout_sides() -> void:
	var tray = control.size
	if tray.y <= 0.0:
		return
	var item = minf(tray.y * HUD_ITEM_RATIO, HUD_ITEM_MAX)
	var top = (tray.y - item) / 2.0
	var left = _side_left if _side_left >= 0.0 else SIDE_MARGIN
	var right = _side_right if _side_right >= 0.0 else tray.x - SIDE_MARGIN

	for item_control in [_gear, _badge]:
		item_control.custom_minimum_size = Vector2(item, item)
		item_control.size = Vector2(item, item)
	_gear.position = Vector2(left, top)
	_badge.position = Vector2(right - item, top)

func set_score(new_score: int) -> void:
	_target_score = new_score
	# broken blocks are on their way: the number goes up as they land (on_fragment_arrived) instead of right away
	if _fragments_in_flight > 0:
		return

	var gained = new_score > int(_displayed_score)

	# count up to the new score instead of jumping
	if _score_tween:
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_method(_show_score, _displayed_score, float(new_score), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if gained:
		_punch_score()

# Fragments from broken blocks are about to fly in (sent before the score changes)
func on_fragments_launched(count: int) -> void:
	_fragments_in_flight += count
	_catch_up_later()

# One fragment landed: show its share of the points still waiting, all of them with the last one
func on_fragment_arrived() -> void:
	_fragments_in_flight = maxi(0, _fragments_in_flight - 1)
	_catch_up_later()
	if _score_tween:
		_score_tween.kill()
	var waiting = _target_score - _displayed_score
	var share = waiting if _fragments_in_flight == 0 else waiting / float(_fragments_in_flight + 1)
	_show_score(_displayed_score + share)

	# a small punch, at most every few frames so a stream of fragments doesn't make it shake
	var now = Time.get_ticks_msec()
	if waiting > 0.0 and now - _last_arrival_punch_ms > 90:
		_last_arrival_punch_ms = now
		_punch_score()

# Safety net: if nothing lands for a while (a fragment that never arrived), stop waiting and show the real score
func _catch_up_later() -> void:
	_flight_id += 1
	var id = _flight_id
	await get_tree().create_timer(2.5, false).timeout
	if id == _flight_id and _fragments_in_flight > 0:
		_fragments_in_flight = 0
		set_score(_target_score)

# Where the score number is on screen (broken blocks' fragments fly here)
func get_score_global_center() -> Vector2:
	return _score_label.get_global_rect().get_center()

func set_best(best: int) -> void:
	_best_value = best
	_best_label.text = tr("HUD_BEST") % NumberFormat.compact(best)

func set_combo(new_combo: int) -> void:
	_badge.set_multiplier(new_combo)

	# from the second line of a streak on, a rising "combo" sound on top of the line chime
	var now = Time.get_ticks_msec()
	if new_combo >= 3 and now - _last_combo_sound_ms > COMBO_SOUND_COOLDOWN_MS:
		_last_combo_sound_ms = now
		Sfx.play("combo_up", minf(1.0 + 0.05 * (new_combo - 3), 1.6))

func reset_combo() -> void:
	_badge.hide_badge()

# While the hourglass is active the badge's ring turns icy blue
func set_slow_time(active: bool) -> void:
	_badge.set_slowed(active)

func update_combo_timer(remaining: float, total: float = 5.0) -> void:
	_badge.set_time_fraction(remaining / total)

func _show_score(value: float) -> void:
	_displayed_score = value
	_score_label.text = NumberFormat.compact(int(value))

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _best_label:
		set_best(_best_value)
