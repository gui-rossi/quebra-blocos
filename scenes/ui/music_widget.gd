extends VBoxContainer

# Small music player for the options screen: current track, how far it has played, previous / next

const UiStyle = preload("res://scenes/ui/ui_style.gd")
const TransportButton = preload("res://scenes/ui/transport_button.gd")

var _title: Label
var _progress: ProgressBar
var _time: Label

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)

	add_child(UiStyle.label("Now playing", 22, UiStyle.TEXT_SOFT))
	_title = UiStyle.label("", 28, UiStyle.TEXT)
	_title.custom_minimum_size = Vector2(420, 0)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)

	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(420, 10)
	_progress.max_value = 1.0
	_progress.step = 0.0  # smooth, not in 1% steps
	_progress.add_theme_stylebox_override("background", UiStyle.box(Color(1, 1, 1, 0.12), 5, 0.0))
	_progress.add_theme_stylebox_override("fill", UiStyle.box(UiStyle.PRIMARY.lightened(0.2), 5, 0.0))
	add_child(_progress)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	var previous = TransportButton.new()
	previous.kind = TransportButton.Kind.PREVIOUS
	previous.pressed.connect(MusicPlayer.previous_track)
	row.add_child(previous)

	_time = UiStyle.label("0:00 / 0:00", 26, UiStyle.TEXT_SOFT)
	_time.custom_minimum_size = Vector2(170, 0)
	row.add_child(_time)

	var next = TransportButton.new()
	next.kind = TransportButton.Kind.NEXT
	next.pressed.connect(func(): MusicPlayer.next_track())
	row.add_child(next)

	MusicPlayer.track_changed.connect(_on_track_changed)
	_on_track_changed(MusicPlayer.get_title())

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var length = MusicPlayer.get_length()
	var played = MusicPlayer.get_position()
	_progress.value = played / length if length > 0.0 else 0.0
	_time.text = "%s / %s" % [_format(played), _format(length)]

func _on_track_changed(title: String) -> void:
	_title.text = title if title != "" else "No music"

func _format(seconds: float) -> String:
	var total = int(seconds)
	return "%d:%02d" % [int(total / 60.0), total % 60]
