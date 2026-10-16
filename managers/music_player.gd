extends Node

# Background music: plays the public-domain classical playlist on the Music bus, shuffled, with crossfades.
# Volume and on/off come from Settings (the Music bus). Track sources and licenses: assets/music/CREDITS.md

signal track_changed(title: String)

const TRACKS := [
	{"path": "res://assets/music/satie_gymnopedie_1.ogg", "title": "Satie - Gymnopédie No. 1"},
	{"path": "res://assets/music/chopin_nocturne_op15_no1.ogg", "title": "Chopin - Nocturne Op. 15 No. 1"},
	{"path": "res://assets/music/beethoven_pathetique_adagio.ogg", "title": "Beethoven - Pathétique, Adagio"},
	{"path": "res://assets/music/mozart_k545_allegro.ogg", "title": "Mozart - Sonata K. 545, Allegro"},
	{"path": "res://assets/music/chopin_nocturne_op72_no1.ogg", "title": "Chopin - Nocturne Op. 72 No. 1"},
	{"path": "res://assets/music/chopin_waltz_op64_no3.ogg", "title": "Chopin - Waltz Op. 64 No. 3"},
	{"path": "res://assets/music/chopin_nocturne_op55_no1.ogg", "title": "Chopin - Nocturne Op. 55 No. 1"},
	{"path": "res://assets/music/debussy_clair_de_lune.ogg", "title": "Debussy - Clair de lune"},
	{"path": "res://assets/music/rossini_william_tell_overture.ogg", "title": "Rossini - William Tell Overture"},
	{"path": "res://assets/music/fucik_entry_of_the_gladiators.ogg", "title": "Fučík - Entry of the Gladiators"},
	{"path": "res://assets/music/rimsky_korsakov_flight_of_the_bumblebee.mp3", "title": "Rimsky-Korsakov - Flight of the Bumblebee"},
	{"path": "res://assets/music/beethoven_fur_elise.ogg", "title": "Beethoven - Für Elise"},
	{"path": "res://assets/music/mozart_rondo_alla_turca.ogg", "title": "Mozart - Rondo alla Turca"},
	{"path": "res://assets/music/abreu_tico_tico_no_fuba.ogg", "title": "Zequinha de Abreu - Tico-Tico no Fubá"},
]

const FADE_TIME := 2.5  # seconds of crossfade between tracks
const SKIP_FADE_TIME := 0.4  # quicker crossfade when the player skips
const RESTART_THRESHOLD := 3.0  # "previous" past this many seconds restarts the track instead
const QUIET_DB := -40.0
const HISTORY_SIZE := 50

var _players: Array[AudioStreamPlayer] = []
var _current := 0  # which of the two players is playing
var _queue: Array = []  # tracks left before the playlist reshuffles
var _history: Array = []  # tracks played, the last one is the current track
var _fade_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps playing in the pause menu
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = Settings.MUSIC_BUS
		player.volume_db = QUIET_DB
		player.finished.connect(_on_finished.bind(player))
		add_child(player)
		_players.append(player)
	next_track(FADE_TIME)

# Starts the next track while the current one is still in its last seconds, so they overlap
func _process(_delta: float) -> void:
	var player = _players[_current]
	if not player.playing or player.stream == null:
		return
	if player.get_playback_position() >= player.stream.get_length() - FADE_TIME:
		next_track(FADE_TIME)

# ---------------- Controls (used by the music player in the options) ----------------

func next_track(fade: float = SKIP_FADE_TIME) -> void:
	var track = _next_from_queue()
	if track.is_empty():
		return
	_history.append(track)
	if _history.size() > HISTORY_SIZE:
		_history.pop_front()
	_play(track, fade)

# Back to the previous track, or to the start of this one if it's been playing for a few seconds
func previous_track() -> void:
	if get_position() > RESTART_THRESHOLD or _history.size() < 2:
		_players[_current].seek(0.0)
		return
	var current = _history.pop_back()
	_queue.push_front(current)  # comes back up when skipping forward again
	_play(_history.back(), SKIP_FADE_TIME)

func get_title() -> String:
	return _history.back().title if not _history.is_empty() else ""

func get_position() -> float:
	var player = _players[_current]
	return player.get_playback_position() if player.playing else 0.0

func get_length() -> float:
	var stream = _players[_current].stream
	return stream.get_length() if stream else 0.0

# ---------------- Playback ----------------

# Only matters if a track ended without the early crossfade (e.g. one shorter than the fade)
func _on_finished(player: AudioStreamPlayer) -> void:
	if player == _players[_current]:
		next_track(FADE_TIME)

# Crossfades from the current track into `track`
func _play(track: Dictionary, fade: float) -> void:
	var stream = load(track.path)
	if stream == null:
		push_warning("Music track missing: %s" % track.path)
		return

	# a crossfade still running would stop the player we're about to reuse
	if _fade_tween:
		_fade_tween.kill()

	var outgoing = _players[_current]
	_current = 1 - _current
	var incoming = _players[_current]
	incoming.stream = stream
	incoming.volume_db = QUIET_DB
	incoming.play()

	_fade_tween = create_tween().set_parallel()
	_fade_tween.tween_property(incoming, "volume_db", 0.0, fade)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", QUIET_DB, fade)
		_fade_tween.chain().tween_callback(outgoing.stop)

	track_changed.emit(track.title)

# Shuffles the whole playlist, plays it through, then reshuffles (never the same track twice in a row)
func _next_from_queue() -> Dictionary:
	if _queue.is_empty():
		_queue = TRACKS.filter(func(track): return ResourceLoader.exists(track.path))
		_queue.shuffle()
		var last = _history.back() if not _history.is_empty() else {}
		if _queue.size() > 1 and _queue[0] == last:
			_queue.reverse()
	if _queue.is_empty():
		return {}
	return _queue.pop_front()
