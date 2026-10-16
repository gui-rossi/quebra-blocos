extends Node

# Combo timer: counts down after each cleared line, the multiplier resets when it runs out.
# Counted by hand (not with a Timer) so the hourglass power-up can slow it down.

signal combo_expired
signal update_combo_timer(time_left: float, total: float)
signal slow_time_changed(active: bool)  # the hourglass power-up started or wore off

@export var combo_reset_time: float = 5.0

var _time_left: float = 0.0
var _running: bool = false
var _slow_time_left: float = 0.0  # real seconds the slow-down still lasts
var _slow_factor: float = 1.0  # how fast the combo timer runs while slowed (0.5 = half speed)

func _ready() -> void:
	set_process(false)

# `time_left` > 0 continues a combo from a saved run, otherwise the full combo time starts over
func start_combo_timer(time_left: float = -1.0) -> void:
	_time_left = time_left if time_left > 0.0 else combo_reset_time
	_running = true
	set_process(true)

func get_time_left() -> float:
	return _time_left if _running else 0.0

# The combo timer runs at `factor` speed for the next `duration` real seconds (used again, it restarts)
func slow_down(duration: float, factor: float) -> void:
	var was_slow = _slow_time_left > 0.0
	_slow_time_left = duration
	_slow_factor = factor
	set_process(true)
	if not was_slow:
		slow_time_changed.emit(true)

func get_slow_time_left() -> float:
	return maxf(_slow_time_left, 0.0)

func _process(delta: float) -> void:
	var speed = 1.0
	if _slow_time_left > 0.0:
		speed = _slow_factor
		_slow_time_left -= delta
		if _slow_time_left <= 0.0:
			slow_time_changed.emit(false)

	if _running:
		_time_left -= delta * speed
		if _time_left <= 0.0:
			_time_left = 0.0
			_running = false
			combo_expired.emit()
		update_combo_timer.emit(_time_left, combo_reset_time)

	if not _running and _slow_time_left <= 0.0:
		set_process(false)
