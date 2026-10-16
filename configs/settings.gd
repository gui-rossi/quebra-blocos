extends Node

# Player options and stats, kept between sessions in user://settings.cfg

signal changed

const PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"

var sfx_enabled: bool = true
var sfx_volume: float = 0.8  # 0..1
var music_enabled: bool = true
var music_volume: float = 0.6  # 0..1
var vibration: bool = true
var effects_high: bool = true  # false = fewer particles and no screen shake
var best_score: int = 0

func _ready() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)
	load_settings()
	apply()

# True while any sound (effects or music) is on, used by the quick toggle in the pause menu
func is_sound_on() -> bool:
	return sfx_enabled or music_enabled

func set_sound_on(on: bool) -> void:
	sfx_enabled = on
	music_enabled = on
	apply()
	save_settings()

# Pushes the audio options to the buses
func apply() -> void:
	_apply_bus(SFX_BUS, sfx_enabled, sfx_volume)
	_apply_bus(MUSIC_BUS, music_enabled, music_volume)
	changed.emit()

func vibrate(duration_ms: int) -> void:
	if vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)

func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return  # first run, keep the defaults
	sfx_enabled = cfg.get_value("audio", "sfx_enabled", sfx_enabled)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	music_enabled = cfg.get_value("audio", "music_enabled", music_enabled)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	vibration = cfg.get_value("game", "vibration", vibration)
	effects_high = cfg.get_value("game", "effects_high", effects_high)
	best_score = cfg.get_value("stats", "best_score", best_score)

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("game", "effects_high", effects_high)
	cfg.set_value("stats", "best_score", best_score)
	cfg.save(PATH)

# Buses are created here so the project doesn't need a bus layout file
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _apply_bus(bus_name: String, enabled: bool, volume: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, not enabled)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
