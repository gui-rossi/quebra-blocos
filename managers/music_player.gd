extends Node

# Background music: plays the public-domain classical playlist on the Music bus, shuffled, with crossfades.
# Volume and on/off come from Settings (the Music bus). Track sources and licenses: assets/music/CREDITS.md

const TRACKS := [
	"res://assets/music/satie_gymnopedie_1.ogg",
	"res://assets/music/chopin_nocturne_op15_no1.ogg",
	"res://assets/music/beethoven_pathetique_adagio.ogg",
	"res://assets/music/mozart_k545_allegro.ogg",
	"res://assets/music/chopin_nocturne_op72_no1.ogg",
	"res://assets/music/chopin_waltz_op64_no3.ogg",
	"res://assets/music/chopin_nocturne_op55_no1.ogg",
]

const FADE_TIME := 2.5  # seconds of crossfade between tracks
const QUIET_DB := -40.0

var _players: Array[AudioStreamPlayer] = []
var _current := 0  # which of the two players is playing
var _queue: Array = []  # tracks left before the playlist reshuffles
var _last_track := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps playing in the pause menu
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = Settings.MUSIC_BUS
		player.volume_db = QUIET_DB
		player.finished.connect(_on_finished.bind(player))
		add_child(player)
		_players.append(player)
	_play_next()

# Starts the next track while the current one is still in its last seconds, so they overlap
func _process(_delta: float) -> void:
	var player = _players[_current]
	if not player.playing or player.stream == null:
		return
	if player.get_playback_position() >= player.stream.get_length() - FADE_TIME:
		_play_next()

# Only matters if a track ended without the early crossfade (e.g. one shorter than the fade)
func _on_finished(player: AudioStreamPlayer) -> void:
	if player == _players[_current]:
		_play_next()

# Crossfades into the next track of the shuffled playlist
func _play_next() -> void:
	var path = _next_track()
	if path == "":
		return
	var stream = load(path)
	if stream == null:
		push_warning("Music track missing: %s" % path)
		return

	var outgoing = _players[_current]
	_current = 1 - _current
	var incoming = _players[_current]
	incoming.stream = stream
	incoming.volume_db = QUIET_DB
	incoming.play()

	var tween = create_tween().set_parallel()
	tween.tween_property(incoming, "volume_db", 0.0, FADE_TIME)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", QUIET_DB, FADE_TIME)
		tween.chain().tween_callback(outgoing.stop)

# Shuffles the whole playlist, plays it through, then reshuffles (never the same track twice in a row)
func _next_track() -> String:
	if _queue.is_empty():
		_queue = TRACKS.filter(func(path): return ResourceLoader.exists(path))
		_queue.shuffle()
		if _queue.size() > 1 and _queue[0] == _last_track:
			_queue.reverse()
	if _queue.is_empty():
		return ""
	_last_track = _queue.pop_front()
	return _last_track
