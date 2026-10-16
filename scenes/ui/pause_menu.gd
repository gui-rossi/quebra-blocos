extends CanvasLayer

# Pause screen opened from the gear in the top tray: pauses the game until Resume

signal main_menu_requested

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const OptionsPanel = preload("res://scenes/ui/options_panel.gd")

var _menu_box: PanelContainer
var _options: PanelContainer
var _sound_button: Button

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps working while the tree is paused
	visible = false

	_menu_box = UiStyle.panel()
	var column = UiStyle.vbox(22)
	_menu_box.add_child(column)
	column.add_child(UiStyle.label("PAUSE_TITLE", 60, UiStyle.TEXT, 8))

	var resume = UiStyle.button("PAUSE_RESUME")
	resume.pressed.connect(close)
	column.add_child(resume)

	_sound_button = UiStyle.button("", UiStyle.PRIMARY.darkened(0.25))
	_sound_button.pressed.connect(_toggle_sound)
	column.add_child(_sound_button)

	var options = UiStyle.button("PAUSE_OPTIONS", UiStyle.PRIMARY.darkened(0.25))
	options.pressed.connect(_show_options)
	column.add_child(options)

	var menu = UiStyle.button("PAUSE_MAIN_MENU", Color(0.55, 0.2, 0.25))
	menu.pressed.connect(func(): main_menu_requested.emit())
	column.add_child(menu)

	_options = OptionsPanel.new()
	_options.visible = false
	_options.closed.connect(_show_menu)

	add_child(UiStyle.overlay(_stack(_menu_box, _options)))

	_update_sound_button()

func open() -> void:
	get_tree().paused = true
	_show_menu()
	visible = true
	UiStyle.pop_in(_menu_box)

func close() -> void:
	visible = false
	get_tree().paused = false

func _show_menu() -> void:
	_options.visible = false
	_menu_box.visible = true
	_update_sound_button()

func _show_options() -> void:
	_menu_box.visible = false
	_options.visible = true
	UiStyle.pop_in(_options)

func _toggle_sound() -> void:
	Settings.set_sound_on(not Settings.is_sound_on())
	_update_sound_button()

func _update_sound_button() -> void:
	_sound_button.text = "PAUSE_SOUND_ON" if Settings.is_sound_on() else "PAUSE_SOUND_OFF"

# Both panels in one centered slot, only one is visible at a time
func _stack(a: Control, b: Control) -> Control:
	var holder = VBoxContainer.new()
	holder.add_child(a)
	holder.add_child(b)
	return holder
