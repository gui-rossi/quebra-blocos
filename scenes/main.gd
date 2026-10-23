# Main.gd
extends Node

const PauseMenu = preload("res://scenes/ui/pause_menu.gd")
const GameOverPanel = preload("res://scenes/ui/game_over_panel.gd")
const Backpack = preload("res://scenes/ui/backpack.gd")
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@export var top_tray_ratio: float = 0.10
@export var bottom_tray_ratio: float = 0.20
@export var backpack_ratio: float = 0.075  # the backpack bar between the board and the tray

@onready var top_tray: Node2D = $CanvasLayer/TopTray
@onready var bottom_tray: Node2D = $CanvasLayer/BottomTray
@onready var grid_manager: Node2D = $CanvasLayer/GridManager
@onready var timer_manager: Node = $CanvasLayer/TimerManager
@onready var drag_controller: Node2D = $DragController

var backpack: Control
var pause_menu: CanvasLayer
var game_over_panel: CanvasLayer
var _is_over: bool = false

func _ready() -> void:
	get_tree().paused = false
	GameConfig.current_score_multiplier = 1  # it's an autoload, it would carry over from the last run

	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.main_menu_requested.connect(_go_to_menu)

	game_over_panel = GameOverPanel.new()
	add_child(game_over_panel)
	game_over_panel.play_again_requested.connect(_play_again)
	game_over_panel.main_menu_requested.connect(_go_to_menu)

	backpack = Backpack.new()
	$CanvasLayer.add_child(backpack)
	drag_controller.backpack = backpack
	grid_manager.score_changed.connect(backpack.update_unlocks)
	grid_manager.score_target = top_tray.get_score_global_center
	grid_manager.fragments_launched.connect(top_tray.on_fragments_launched)
	grid_manager.fragment_arrived.connect(top_tray.on_fragment_arrived)

	top_tray.settings_pressed.connect(_open_pause)
	top_tray.set_best(Settings.best_score)
	drag_controller.piece_dropped.connect(_on_piece_dropped)
	timer_manager.combo_expired.connect(_on_combo_expired)
	timer_manager.slow_time_changed.connect(top_tray.set_slow_time)
	grid_manager.slow_time_used.connect(_on_slow_time_used)

	layout()

	# the slots get their final scale first: pieces are built to match it
	bottom_tray.scale_randomized_blocks()

	var saved = SaveGame.load_run() if SaveGame.pending_resume else {}
	SaveGame.pending_resume = false
	if saved.is_empty():
		bottom_tray.set_randomized_blocks()
	else:
		_restore(saved)
	_update_playable()

	_check_game_over.call_deferred()  # a restored run may already be stuck

func layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var top_height = viewport_size.y * top_tray_ratio
	var bottom_height = viewport_size.y * bottom_tray_ratio
	var backpack_height = viewport_size.y * backpack_ratio

	top_tray.get_node("CanvasLayer/Control").size = Vector2(viewport_size.x, top_height)
	top_tray.get_node("CanvasLayer/Control").position = Vector2.ZERO

	bottom_tray.get_node("CanvasLayer/Control").size = Vector2(viewport_size.x, bottom_height)
	bottom_tray.get_node("CanvasLayer/Control").position = Vector2(0, viewport_size.y - bottom_height)

	backpack.position = Vector2(0, viewport_size.y - bottom_height - backpack_height)
	backpack.size = Vector2(viewport_size.x, backpack_height)

	grid_manager.set_reserved_space(top_height, bottom_height + backpack_height)

	var board = grid_manager.get_board_rect()
	top_tray.align_sides(board.position.x, board.end.x)

# Saves the run when the app goes to the background or the window closes
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_run()

# ---------------- Run flow ----------------

func _on_piece_dropped(was_powerup: bool) -> void:
	if was_powerup:
		await grid_manager.powerup_finished  # its cells only free up once its animation is done
	_save_run()
	_update_playable()
	_check_game_over()

# Hourglass power-up: the combo timer runs slower (or stops, the mega one) for a while
func _on_slow_time_used(duration: float, factor: float) -> void:
	timer_manager.slow_down(duration, factor)

func _on_combo_expired() -> void:
	GameConfig.current_score_multiplier = 1

func _open_pause() -> void:
	if _is_over:
		return
	drag_controller.cancel_drag()
	_save_run()
	pause_menu.open()

func _go_to_menu() -> void:
	_save_run()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)

func _play_again() -> void:
	SaveGame.pending_resume = false
	get_tree().paused = false
	get_tree().reload_current_scene()

# ---------------- Game over ----------------

# Game over when none of the shapes left in the tray fit anywhere and there's no power-up left, in the tray or the
# backpack. A power-up never leaves the game stuck: even one with nowhere to go (a prism on an empty board) can be
# dropped in the trash can, which uses up its tray slot.
func _is_game_over() -> bool:
	if backpack.has_items():
		return false
	for piece in bottom_tray.get_pieces():
		if piece.shape_cells.is_empty():
			continue
		if piece.powerup_name != "" or grid_manager.can_fit_anywhere(piece.shape_cells):
			return false
	return true

# Whether the piece can go on the board right now (shapes need a free spot, the prism needs a block)
func _can_play(piece: Node2D) -> bool:
	if piece.powerup_name != "":
		return grid_manager.can_place_powerup_anywhere(piece.powerup_name)
	return grid_manager.can_fit_anywhere(piece.shape_cells)

# Dims the tray pieces that don't fit anywhere right now
func _update_playable() -> void:
	for piece in bottom_tray.get_pieces():
		piece.set_playable(piece.shape_cells.is_empty() or _can_play(piece))

func _check_game_over() -> void:
	if _is_over or not _is_game_over():
		return
	_is_over = true
	SaveGame.clear_run()

	var score: int = grid_manager.score
	var is_new_best = score > Settings.best_score
	if is_new_best:
		Settings.best_score = score
		Settings.save_settings()

	# let the last clear finish playing before the panel covers the board
	await get_tree().create_timer(0.6).timeout
	get_tree().paused = true
	Sfx.play("game_over")
	Settings.vibrate(60)
	game_over_panel.show_result(score, Settings.best_score, is_new_best)

# ---------------- Save / restore ----------------

func _save_run() -> void:
	if _is_over:
		return
	SaveGame.save_run({
		"cells": grid_manager.get_cells_data(),
		"tray": bottom_tray.get_slots_save(),
		"backpack": backpack.to_save(),
		"score": grid_manager.score,
		"multiplier": GameConfig.current_score_multiplier,
		"combo_time_left": timer_manager.get_time_left(),
		"slow_time_left": timer_manager.get_slow_time_left(),
		"slow_time_factor": timer_manager.get_slow_factor(),
	})

func _restore(saved: Dictionary) -> void:
	grid_manager.restore_cells(saved.get("cells", []))
	bottom_tray.restore_slots(saved.get("tray", []))
	backpack.restore(saved.get("backpack", []))
	grid_manager.set_score(int(saved.get("score", 0)))

	var multiplier = mini(int(saved.get("multiplier", 1)), GameConfig.max_score_multiplier)
	var time_left = float(saved.get("combo_time_left", 0.0))
	if multiplier > 1 and time_left > 0.0:
		GameConfig.current_score_multiplier = multiplier
		top_tray.set_combo(multiplier)
		timer_manager.start_combo_timer(time_left)

	var slow_left = float(saved.get("slow_time_left", 0.0))
	if slow_left > 0.0:
		timer_manager.slow_down(slow_left, float(saved.get("slow_time_factor", GameConfig.slow_time_factor)))
