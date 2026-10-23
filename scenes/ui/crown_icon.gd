extends Control

# A small gold crown, drawn in code, shown next to the best score in the top tray. It fills its own rect
# (set custom_minimum_size), so it scales with whatever size the HUD gives it.

const INK := Color(0.12, 0.07, 0.02, 0.85)
const GOLD_DARK := Color(0.85, 0.55, 0.1)
const GOLD := Color(1.0, 0.8, 0.25)
const GOLD_LIGHT := Color(1.0, 0.93, 0.6)
const GEM_RED := Color(0.95, 0.3, 0.32)
const GEM_BLUE := Color(0.35, 0.7, 1.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w = size.x
	var h = size.y
	if w <= 0.0 or h <= 0.0:
		return
	var o = maxf(1.5, h * 0.09)  # outline thickness

	# three points on top, a band at the bottom
	var top = h * 0.16
	var dip = h * 0.48
	var band_top = h * 0.66
	var bottom = h * 0.92
	var crown = PackedVector2Array([
		Vector2(w * 0.06, top + h * 0.06), Vector2(w * 0.3, dip), Vector2(w * 0.5, top), Vector2(w * 0.7, dip),
		Vector2(w * 0.94, top + h * 0.06), Vector2(w * 0.86, band_top), Vector2(w * 0.14, band_top),
	])
	var band = Rect2(Vector2(w * 0.12, band_top), Vector2(w * 0.76, bottom - band_top))

	# outline
	draw_colored_polygon(_grow(crown, o), INK)
	draw_rect(band.grow(o), INK)

	# gold, darker on the band, with a lighter left half for some volume
	draw_colored_polygon(crown, GOLD)
	var left_half = PackedVector2Array([crown[0], crown[1], crown[2], Vector2(w * 0.5, band_top), crown[6]])
	draw_colored_polygon(left_half, GOLD_LIGHT.lerp(GOLD, 0.45))
	draw_rect(band, GOLD_DARK)
	draw_rect(Rect2(band.position, Vector2(band.size.x, band.size.y * 0.35)), GOLD.lerp(GOLD_DARK, 0.3))

	# little balls on the points and gems on the band
	var ball = maxf(1.5, h * 0.09)
	for p in [crown[0], crown[2], crown[4]]:
		draw_circle(p, ball + o * 0.6, INK)
		draw_circle(p, ball, GOLD_LIGHT)
	var gem = maxf(1.2, h * 0.07)
	var gem_y = band.position.y + band.size.y / 2.0
	draw_circle(Vector2(w * 0.3, gem_y), gem, GEM_BLUE)
	draw_circle(Vector2(w * 0.5, gem_y), gem * 1.15, GEM_RED)
	draw_circle(Vector2(w * 0.7, gem_y), gem, GEM_BLUE)

# The polygon pushed out by `amount` from its centre (for the outline)
func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center = Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	var grown = PackedVector2Array()
	for p in points:
		var dir = p - center
		grown.append(center + dir * (dir.length() + amount) / maxf(dir.length(), 0.001))
	return grown
