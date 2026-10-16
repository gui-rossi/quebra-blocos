extends Control

# First screen: continue the saved run, start a new one, or change options

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const OptionsPanel = preload("res://scenes/ui/options_panel.gd")
const GAME_SCENE := "res://scenes/main.tscn"
const BACKGROUND := Color(0.05, 0.12, 0.28)

var _menu: VBoxContainer
var _options: PanelContainer
var _title: Label

func _ready() -> void:
	get_tree().paused = false  # coming back from the pause menu
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var holder = VBoxContainer.new()  # menu and options take turns in the same spot
	center.add_child(holder)

	_menu = UiStyle.vbox(24)
	holder.add_child(_menu)

	_title = UiStyle.label("Quebra\nBlocos", 110, Color(1, 0.9, 0.35), 16)
	_menu.add_child(_title)
	_menu.add_child(UiStyle.label("Best: %d" % Settings.best_score, 34, UiStyle.TEXT_SOFT))
	_menu.add_child(_spacer(40))

	var resume = UiStyle.button("Continue")
	resume.disabled = not SaveGame.has_run()
	resume.pressed.connect(_continue_run)
	_menu.add_child(resume)

	var new_game = UiStyle.button("New game", UiStyle.PRIMARY.darkened(0.25) if SaveGame.has_run() else UiStyle.PRIMARY)
	new_game.pressed.connect(_new_run)
	_menu.add_child(new_game)

	var options = UiStyle.button("Options", UiStyle.PRIMARY.darkened(0.25))
	options.pressed.connect(_show_options)
	_menu.add_child(options)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(_show_menu)
	holder.add_child(_options)

	_animate_title()
	UiStyle.pop_in(_menu)

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

# Slow bob and tilt on the title so the screen doesn't feel static
func _animate_title() -> void:
	var tween = _title.create_tween().set_loops()
	tween.tween_method(func(t: float):
		_title.pivot_offset = _title.size / 2.0
		_title.rotation_degrees = sin(t * TAU) * 2.5
		_title.scale = Vector2.ONE * (1.0 + 0.03 * sin(t * TAU * 2.0))
	, 0.0, 1.0, 3.0)

func _spacer(height: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer
