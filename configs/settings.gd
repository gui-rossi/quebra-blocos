extends Node

# Player options and stats, kept between sessions in user://settings.cfg

signal changed

const PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"

# Languages the game ships, each named in its own language. "" means automatic (follow the phone)
const LANGUAGES := [
	["en", "English"],
	["pt_BR", "Português (Brasil)"],
	["es", "Español"],
]

var sfx_enabled: bool = true
var sfx_volume: float = 0.8  # 0..1
var music_enabled: bool = true
var music_volume: float = 0.6  # 0..1
var vibration: bool = true
var effects_high: bool = true  # false = fewer particles and no screen shake
var best_score: int = 0
var language: String = ""  # a code from LANGUAGES, or "" to follow the phone's language
var backpack_slots: int = 1  # unlocked backpack slots, see GameConfig.backpack_unlock_scores

func _ready() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)
	load_settings()
	apply()
	apply_language()

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

# Switches the game's language right away: Controls showing a translation key update themselves,
# and scripts that build text from values redraw on NOTIFICATION_TRANSLATION_CHANGED
func set_language(code: String) -> void:
	language = code
	apply_language()
	save_settings()

func apply_language() -> void:
	# Godot picks the closest translation (e.g. pt_PT -> pt_BR) and falls back to English for the rest
	TranslationServer.set_locale(language if language != "" else OS.get_locale())

# The language actually in use, from LANGUAGES (what "Automatic" resolved to)
func current_language_name() -> String:
	var locale = TranslationServer.get_locale()
	var best = LANGUAGES[0][1]
	var best_score = -1
	for entry in LANGUAGES:
		var score = TranslationServer.compare_locales(locale, entry[0])
		if score > best_score:
			best_score = score
			best = entry[1]
	return best

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
	language = cfg.get_value("game", "language", language)
	effects_high = cfg.get_value("game", "effects_high", effects_high)
	best_score = cfg.get_value("stats", "best_score", best_score)
	backpack_slots = cfg.get_value("stats", "backpack_slots", backpack_slots)

func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "effects_high", effects_high)
	cfg.set_value("stats", "best_score", best_score)
	cfg.set_value("stats", "backpack_slots", backpack_slots)
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
