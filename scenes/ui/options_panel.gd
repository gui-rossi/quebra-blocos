extends PanelContainer

# Options screen, used by the main menu and the pause menu. Changes apply and are saved to the device right away.

signal closed

const UiStyle = preload("res://scenes/ui/ui_style.gd")

func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.PANEL_BG, 32, 32.0))

	var column = UiStyle.vbox(18)
	add_child(column)
	column.add_child(UiStyle.label("Options", 52, UiStyle.TEXT, 8))

	column.add_child(_toggle("Sound effects", Settings.sfx_enabled, func(on): Settings.sfx_enabled = on))
	column.add_child(_slider(Settings.sfx_volume, func(v): Settings.sfx_volume = v))
	column.add_child(_toggle("Music", Settings.music_enabled, func(on): Settings.music_enabled = on))
	column.add_child(_slider(Settings.music_volume, func(v): Settings.music_volume = v))
	column.add_child(_toggle("Vibration", Settings.vibration, func(on): Settings.vibration = on))
	column.add_child(_toggle("Fancy effects", Settings.effects_high, func(on): Settings.effects_high = on))

	var back = UiStyle.button("Back")
	back.pressed.connect(_on_back)
	column.add_child(back)

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
