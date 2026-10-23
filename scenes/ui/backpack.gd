extends Control

# Backpack bar between the board and the tray: a backpack icon, 5 slots for storing power-ups and a trash can.
# Drag a power-up from the tray onto a free slot to keep it, drag it from the slot onto the grid to use it later.
# Any power-up (from the tray or a slot) can be dropped in the trash can to get rid of it for some points.
# Slots past the first unlock for good once a game reaches GameConfig.backpack_unlock_scores.

const BackpackSlot = preload("res://scenes/ui/backpack_slot.gd")
const TrashCan = preload("res://scenes/ui/trash_can.gd")
const FloatingText = preload("res://scenes/effects/floating_text.gd")
const ICON: Texture2D = preload("res://assets/ui/backpack.png")  # made by tools/backpack_icons.py

const SLOT_COUNT := 5
const ITEM_RATIO := 0.84  # slot size relative to the bar's height
const GAP_RATIO := 0.14  # space between slots, relative to the slot size
const DROP_MARGIN_RATIO := 0.25  # how far outside a slot a drop still counts, relative to the slot size

var _icon: TextureRect
var _slots: Array = []
var _trash: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_icon = TextureRect.new()
	_icon.texture = ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	for i in range(SLOT_COUNT):
		var slot = BackpackSlot.new()
		add_child(slot)
		_slots.append(slot)
	_trash = TrashCan.new()
	add_child(_trash)

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

# A slot holding `key` under `global_point` (not `excluded`, the slot being dragged out of), or null
func slot_with_at(key: String, global_point: Vector2, excluded: Control) -> Control:
	var slot = filled_slot_at(global_point)
	return slot if slot != null and slot != excluded and slot.powerup_name == key else null

# Slots holding `key` glow while the same power-up is dragged, it can be merged into them (set_accepting(false) clears it)
func set_merge_ready(key: String, excluded: Control) -> void:
	for slot in _slots:
		if slot != excluded and not slot.locked and slot.powerup_name == key:
			slot.accepting = true

func set_hover(hovered_slot: Control) -> void:
	for slot in _slots:
		slot.hovered = slot == hovered_slot

# The trash can glows while any power-up is being dragged
func set_trash_accepting(on: bool) -> void:
	_trash.accepting = on
	if not on:
		_trash.hovered = false

# Whether `global_point` is over the trash can. A tighter margin than the slots: slot 5's drop area reaches into it,
# and the drag controller checks the trash can first, so this keeps the two apart.
func trash_at(global_point: Vector2) -> bool:
	return _trash.get_global_rect().grow(_trash.size.x * 0.12).has_point(global_point)

func set_trash_hover(on: bool) -> void:
	_trash.hovered = on

# A power-up was dropped in the trash can: a gulp and its points floating up from it
func trashed(points: int) -> void:
	_trash.swallow()
	var popup = FloatingText.new()
	popup.text = "+%d" % points
	popup.color = Color(1.0, 0.82, 0.3)
	popup.font_size = 36
	popup.position = _trash.position + Vector2(_trash.size.x / 2.0, 0)
	add_child(popup)
	popup.play()

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
	_celebrate(tr("BACKPACK_SLOT_UNLOCKED"))

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

# Icon, the slots, then the trash can, all the same size, centered in the bar (smaller if the bar is too narrow)
func _layout() -> void:
	if size.y <= 0.0:
		return
	var items = SLOT_COUNT + 2  # icon + slots + trash can
	var fits_width = size.x * 0.94 / (items + GAP_RATIO * (items - 1))
	var item = minf(size.y * ITEM_RATIO, fits_width)
	var gap = item * GAP_RATIO
	var total = item * items + gap * (items - 1)
	var x = (size.x - total) / 2.0
	var y = (size.y - item) / 2.0

	_icon.position = Vector2(x, y)
	_icon.size = Vector2(item, item)
	for slot in _slots:
		x += item + gap
		slot.position = Vector2(x, y)
		slot.size = Vector2(item, item)
	x += item + gap
	_trash.position = Vector2(x, y)
	_trash.size = Vector2(item, item)

func _drop_rect(slot: Control) -> Rect2:
	return slot.get_global_rect().grow(slot.size.x * DROP_MARGIN_RATIO)
