extends Control

# Backpack bar between the board and the tray: a backpack icon and 3 slots for storing power-ups.
# Drag a power-up from the tray onto a free slot to keep it, drag it from the slot onto the grid to use it later.
# Slots past the first unlock for good once a game reaches GameConfig.backpack_unlock_scores.

const BackpackSlot = preload("res://scenes/ui/backpack_slot.gd")
const FloatingText = preload("res://scenes/effects/floating_text.gd")

const SLOT_COUNT := 3
const ITEM_RATIO := 0.84  # slot size relative to the bar's height
const GAP_RATIO := 0.18  # space between slots, relative to the slot size
const DROP_MARGIN_RATIO := 0.25  # how far outside a slot a drop still counts, relative to the slot size

var _icon: Control
var _slots: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_icon = BackpackIcon.new()
	add_child(_icon)
	for i in range(SLOT_COUNT):
		var slot = BackpackSlot.new()
		add_child(slot)
		_slots.append(slot)

	# scores reached before the backpack existed count too
	Settings.backpack_slots = maxi(Settings.backpack_slots, _slots_for_score(Settings.best_score))
	_refresh_locks()

	resized.connect(_layout)
	_layout()

# ---------------- Used by the drag controller ----------------

# A slot holding a power-up under `global_point`, or null
func filled_slot_at(global_point: Vector2) -> Control:
	for slot in _slots:
		if not slot.locked and not slot.is_empty() and _drop_rect(slot).has_point(global_point):
			return slot
	return null

# A free (unlocked, empty) slot under `global_point`, or null
func free_slot_at(global_point: Vector2) -> Control:
	for slot in _slots:
		if slot.is_free() and _drop_rect(slot).has_point(global_point):
			return slot
	return null

# Free slots glow while a power-up from the tray is being dragged
func set_accepting(on: bool) -> void:
	for slot in _slots:
		slot.accepting = on and slot.is_free()
		if not on:
			slot.hovered = false

func set_hover(hovered_slot: Control) -> void:
	for slot in _slots:
		slot.hovered = slot == hovered_slot

func has_items() -> bool:
	return _slots.any(func(slot): return not slot.is_empty())

# ---------------- Unlocks ----------------

# Called whenever the score changes: opens the slots this score reaches, for good
func update_unlocks(score: int) -> void:
	var reached = _slots_for_score(score)
	if reached <= Settings.backpack_slots:
		return
	var previous = Settings.backpack_slots
	Settings.backpack_slots = reached
	Settings.save_settings()

	for i in range(previous, mini(reached, SLOT_COUNT)):
		_slots[i].unlock()
	Sfx.play("combo_up", 1.2)
	Settings.vibrate(30)
	_celebrate("New backpack slot!")

func _slots_for_score(score: int) -> int:
	var count := 0
	for threshold in GameConfig.backpack_unlock_scores:
		if score >= threshold:
			count += 1
	return clampi(count, 1, SLOT_COUNT)

func _refresh_locks() -> void:
	for i in range(SLOT_COUNT):
		_slots[i].unlock_score = GameConfig.backpack_unlock_scores[i] if i < GameConfig.backpack_unlock_scores.size() else 0
		_slots[i].locked = i >= Settings.backpack_slots

func _celebrate(text: String) -> void:
	var popup = FloatingText.new()
	popup.text = text
	popup.color = Color(1.0, 0.82, 0.3)
	popup.font_size = 40
	popup.position = Vector2(size.x / 2.0, 0)
	add_child(popup)
	popup.play()

# ---------------- Save / restore (part of the saved run) ----------------

func to_save() -> Array:
	return _slots.map(func(slot): return slot.powerup_name)

func restore(items: Array) -> void:
	for i in range(mini(items.size(), SLOT_COUNT)):
		var key = str(items[i])
		if key != "" and not _slots[i].locked:
			_slots[i].store(key)

# ---------------- Layout ----------------

# Icon then the 3 slots, all the same size, centered in the bar
func _layout() -> void:
	if size.y <= 0.0:
		return
	var item = size.y * ITEM_RATIO
	var gap = item * GAP_RATIO
	var total = item * (SLOT_COUNT + 1) + gap * SLOT_COUNT
	var x = (size.x - total) / 2.0
	var y = (size.y - item) / 2.0

	_icon.position = Vector2(x, y)
	_icon.size = Vector2(item, item)
	for slot in _slots:
		x += item + gap
		slot.position = Vector2(x, y)
		slot.size = Vector2(item, item)

func _drop_rect(slot: Control) -> Rect2:
	return slot.get_global_rect().grow(slot.size.x * DROP_MARGIN_RATIO)

# The little backpack drawn next to the slots
class BackpackIcon extends Control:
	const LEATHER := Color(0.87, 0.52, 0.26)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var s = minf(size.x, size.y)
		var o = (size - Vector2(s, s)) / 2.0
		# handle on top
		draw_arc(o + Vector2(s * 0.5, s * 0.3), s * 0.13, PI, TAU, 20, LEATHER.darkened(0.3), s * 0.06, true)
		# body, flap, pocket
		_box(Rect2(o + Vector2(s * 0.2, s * 0.28), Vector2(s * 0.6, s * 0.62)), LEATHER, s * 0.14)
		_box(Rect2(o + Vector2(s * 0.2, s * 0.28), Vector2(s * 0.6, s * 0.24)), LEATHER.darkened(0.18), s * 0.14)
		_box(Rect2(o + Vector2(s * 0.32, s * 0.62), Vector2(s * 0.36, s * 0.2)), LEATHER.darkened(0.12), s * 0.06)
		# buckle and a bit of shine
		draw_rect(Rect2(o + Vector2(s * 0.46, s * 0.46), Vector2(s * 0.08, s * 0.1)), Color(1.0, 0.85, 0.4))
		_box(Rect2(o + Vector2(s * 0.26, s * 0.33), Vector2(s * 0.2, s * 0.06)), Color(1, 1, 1, 0.22), s * 0.03)

	func _box(rect: Rect2, color: Color, radius: float) -> void:
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(radius))
		style.anti_aliasing = true
		draw_style_box(style, rect)
