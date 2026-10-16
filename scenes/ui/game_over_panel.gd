extends CanvasLayer

# End of a run: final score, best score, play again or back to the menu

signal play_again_requested
signal main_menu_requested

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const NumberFormat = preload("res://configs/number_format.gd")

var _box: PanelContainer
var _score_label: Label
var _best_label: Label
var _new_best_label: Label
var _best_value: int = 0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_box = UiStyle.panel()
	var column = UiStyle.vbox(18)
	_box.add_child(column)

	column.add_child(UiStyle.label("GAME_OVER_TITLE", 52, UiStyle.TEXT, 8))
	column.add_child(UiStyle.label("GAME_OVER_SCORE", 30, UiStyle.TEXT_SOFT))
	_score_label = UiStyle.label("0", 96, Color(1, 0.9, 0.35), 10)
	column.add_child(_score_label)
	_new_best_label = UiStyle.label("GAME_OVER_NEW_BEST", 40, Color(0.55, 1, 0.9), 6)
	column.add_child(_new_best_label)
	_best_label = UiStyle.label("", 30, UiStyle.TEXT_SOFT)
	column.add_child(_best_label)

	var again = UiStyle.button("GAME_OVER_PLAY_AGAIN")
	again.pressed.connect(func(): play_again_requested.emit())
	column.add_child(again)

	var menu = UiStyle.button("GAME_OVER_MAIN_MENU", UiStyle.PRIMARY.darkened(0.25))
	menu.pressed.connect(func(): main_menu_requested.emit())
	column.add_child(menu)

	add_child(UiStyle.overlay(_box))

func show_result(score: int, best: int, is_new_best: bool) -> void:
	_best_value = best
	_best_label.text = tr("GAME_OVER_BEST") % NumberFormat.compact(best)
	_new_best_label.visible = is_new_best
	visible = true
	UiStyle.pop_in(_box)

	# the score counts up from zero
	var tween = create_tween()
	tween.tween_method(func(v: float): _score_label.text = NumberFormat.compact(int(v)), 0.0, float(score), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if is_new_best:
		# keep the "New best!" text pulsing
		_new_best_label.pivot_offset = _new_best_label.size / 2.0
		var pulse = _new_best_label.create_tween().set_loops()
		pulse.tween_property(_new_best_label, "scale", Vector2(1.12, 1.12), 0.4).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_new_best_label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _best_label:
		_best_label.text = tr("GAME_OVER_BEST") % NumberFormat.compact(_best_value)
