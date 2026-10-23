extends Control

# First screen: continue the saved run, start a new one, or change options

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const NumberFormat = preload("res://configs/number_format.gd")
const OptionsPanel = preload("res://scenes/ui/options_panel.gd")
const Background = preload("res://scenes/ui/background.gd")
const Logo = preload("res://scenes/ui/logo.gd")
const GAME_SCENE := "res://scenes/main.tscn"

var _menu: VBoxContainer
var _options: PanelContainer
var _title: Control
var _best: Label

func _ready() -> void:
	get_tree().paused = false  # coming back from the pause menu
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_child(Background.new())

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var holder = VBoxContainer.new()  # menu and options take turns in the same spot
	center.add_child(holder)

	_menu = UiStyle.vbox(24)
	holder.add_child(_menu)

	# "B", an L piece, the backpack as the "O", then "CKPACK" (scenes/ui/logo.gd)
	_title = Logo.new()
	_menu.add_child(_title)
	_best = UiStyle.label("", 34, UiStyle.TEXT_SOFT)
	_menu.add_child(_best)
	_update_texts()
	_menu.add_child(_spacer(40))

	var resume = UiStyle.button("MENU_CONTINUE")
	resume.disabled = not SaveGame.has_run()
	resume.pressed.connect(_continue_run)
	_menu.add_child(resume)

	var new_game = UiStyle.button("MENU_NEW_GAME", UiStyle.PRIMARY.darkened(0.25) if SaveGame.has_run() else UiStyle.PRIMARY)
	new_game.pressed.connect(_new_run)
	_menu.add_child(new_game)

	var options = UiStyle.button("MENU_OPTIONS", UiStyle.PRIMARY.darkened(0.25))
	options.pressed.connect(_show_options)
	_menu.add_child(options)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(_show_menu)
	holder.add_child(_options)

	UiStyle.pop_in(_menu)

# Text built from values (labels holding just a key translate themselves)
func _update_texts() -> void:
	_best.text = tr("MENU_BEST") % NumberFormat.compact(Settings.best_score)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _best:
		_update_texts()

func _continue_run() -> void:
	SaveGame.pending_resume = true
	get_tree().change_scene_to_file(GAME_SCENE)

func _new_run() -> void:
	SaveGame.clear_run()
	SaveGame.pending_resume = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _show_options() -> void:
	_menu.visible = false
	_options.visible = true
	UiStyle.pop_in(_options)

func _show_menu() -> void:
	_options.visible = false
	_menu.visible = true
	UiStyle.pop_in(_menu)

func _spacer(height: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
