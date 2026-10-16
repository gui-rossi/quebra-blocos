extends Node

# The run in progress (board, tray, score, combo), saved to user://run.json so it can be continued

const PATH := "user://run.json"
const VERSION := 1  # bump when the saved data changes shape, older saves are then ignored

# Set by the main menu: true when the game scene should continue the saved run instead of starting fresh
var pending_resume: bool = false

func has_run() -> bool:
	return FileAccess.file_exists(PATH)

func save_run(data: Dictionary) -> void:
	data["version"] = VERSION
	var file = FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't save the run: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))

# Returns {} when there is no save or it can't be used
func load_run() -> Dictionary:
	if not has_run():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return {}
	return parsed

func clear_run() -> void:
	if has_run():
		DirAccess.remove_absolute(PATH)
