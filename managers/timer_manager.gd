extends Node

signal combo_expired
signal update_combo_timer
@export var combo_reset_time: float = 5.0
@onready var combo_timer: Timer = $ComboTimer

func _ready() -> void:
	# Set combo timer
	combo_timer.wait_time = combo_reset_time
	combo_timer.one_shot = true
	set_process(false)
	
func start_combo_timer() -> void:
	combo_timer.start()
	set_process(true)

func _on_combo_timer_timeout() -> void:
	combo_expired.emit()
	set_process(false)

func _process(delta: float) -> void:
	update_combo_timer.emit(combo_timer.time_left)
