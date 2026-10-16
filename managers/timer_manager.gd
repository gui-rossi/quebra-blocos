extends Node

signal combo_expired
signal update_combo_timer(time_left: float, total: float)
@export var combo_reset_time: float = 5.0
@onready var combo_timer: Timer = $ComboTimer

func _ready() -> void:
	# Set combo timer
	combo_timer.wait_time = combo_reset_time
	combo_timer.one_shot = true
	set_process(false)

# `time_left` > 0 continues a combo from a saved run, otherwise the full combo time starts over
func start_combo_timer(time_left: float = -1.0) -> void:
	combo_timer.start(time_left if time_left > 0.0 else combo_reset_time)
	set_process(true)

func get_time_left() -> float:
	return 0.0 if combo_timer.is_stopped() else combo_timer.time_left

func _on_combo_timer_timeout() -> void:
	combo_expired.emit()
	set_process(false)

func _process(delta: float) -> void:
	update_combo_timer.emit(combo_timer.time_left, combo_reset_time)
