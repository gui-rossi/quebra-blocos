extends PanelContainer

# Options screen, used by the main menu and the pause menu. Changes apply and are saved to the device right away.

signal closed

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const MusicWidget = preload("res://scenes/ui/music_widget.gd")

# Shown only while their sound is on: the volume and player are useless with it off
var _sfx_volume: Control
var _music_section: Control
var _language_button: Button
var _sfx_toggle: CheckButton
var _music_toggle: CheckButton

func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL_BG, 32, 32.0))

	var column = UiStyle.vbox(18)
	add_child(column)
	column.add_child(UiStyle.label("OPTIONS_TITLE", 52, UiStyle.TEXT, 8))

	_sfx_toggle = _toggle("OPTIONS_SOUND_EFFECTS", Settings.sfx_enabled, func(on): Settings.sfx_enabled = on)
	column.add_child(_sfx_toggle)
	_sfx_volume = _slider(Settings.sfx_volume, func(v): Settings.sfx_volume = v)
	column.add_child(_sfx_volume)

	_music_toggle = _toggle("OPTIONS_MUSIC", Settings.music_enabled, func(on): Settings.music_enabled = on)
	column.add_child(_music_toggle)
	_music_section = UiStyle.vbox(18)
	_music_section.add_child(_slider(Settings.music_volume, func(v): Settings.music_volume = v))
	_music_section.add_child(MusicWidget.new())
	column.add_child(_music_section)
	column.add_child(_toggle("OPTIONS_VIBRATION", Settings.vibration, func(on): Settings.vibration = on))
	column.add_child(_toggle("OPTIONS_EFFECTS", Settings.effects_high, func(on): Settings.effects_high = on))

	# tapping cycles Automatic -> English -> Português -> Español -> Automatic
	_language_button = UiStyle.button("", UiStyle.PRIMARY.darkened(0.25), 28)
	_language_button.custom_minimum_size = Vector2(420, 104)
	_language_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED  # its text is already translated
	_language_button.pressed.connect(_next_language)
	column.add_child(_language_button)
	_update_language_button()

	var back = UiStyle.button("OPTIONS_BACK")
	back.pressed.connect(_on_back)
	column.add_child(back)

	# also follows the pause menu's quick sound toggle
	Settings.changed.connect(_sync_with_settings)
	_sync_with_settings()

func _next_language() -> void:
	var codes = [""] + Settings.LANGUAGES.map(func(entry): return entry[0])
	var index = codes.find(Settings.language)
	Settings.set_language(codes[(index + 1) % codes.size()])

# "Language: Automatic" with the language it picked on a second line, or the chosen language's own name
func _update_language_button() -> void:
	if Settings.language == "":
		_language_button.text = "%s\n(%s)" % [tr("OPTIONS_LANGUAGE") % tr("OPTIONS_LANGUAGE_AUTO"), Settings.current_language_name()]
	else:
		_language_button.text = tr("OPTIONS_LANGUAGE") % Settings.current_language_name()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _language_button:
		_update_language_button()

# Keeps the switches and sections in line with Settings, e.g. after the pause menu's "Sound: Off"
func _sync_with_settings() -> void:
	_sfx_toggle.set_pressed_no_signal(Settings.sfx_enabled)
	_music_toggle.set_pressed_no_signal(Settings.music_enabled)
	_sfx_volume.visible = Settings.sfx_enabled
	_music_section.visible = Settings.music_enabled

func _on_back() -> void:
	Settings.save_settings()
	closed.emit()

func _toggle(text: String, value: bool, on_change: Callable) -> CheckButton:
	var toggle = CheckButton.new()
	toggle.text = text
	toggle.button_pressed = value
	toggle.custom_minimum_size = Vector2(420, 64)
	toggle.add_theme_font_size_override("font_size", 32)
	toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	toggle.toggled.connect(func(on: bool):
		on_change.call(on)
		Settings.apply()
		Settings.save_settings()
		Sfx.play("click")
	)
	return toggle

func _slider(value: float, on_change: Callable) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(420, 48)
	slider.value_changed.connect(func(v: float):
		on_change.call(v)
		Settings.apply()
	)
	# save and play a click when letting go, so the new effects volume can be heard
	slider.drag_ended.connect(func(_changed: bool):
		Settings.save_settings()
		Sfx.play("click")
	)
	return slider
