extends RefCounted

# Colors for the whole game in one place, tweak here to restyle

# Background gradient, top to bottom
const BG_TOP := Color(0.17, 0.2, 0.47)
const BG_BOTTOM := Color(0.06, 0.07, 0.2)

# The board behind the grid
const BOARD := Color(0.05, 0.07, 0.19)
const BOARD_BORDER := Color(0.36, 0.42, 0.85, 0.55)
const BOARD_SHADOW := Color(0, 0, 0, 0.35)

# An empty grid cell (drawn recessed into the board)
const CELL_EMPTY := Color(0.1, 0.13, 0.31)

# Tray slots where pieces spawn
const SLOT_FILL := Color(1, 1, 1, 0.05)
const SLOT_RING := Color(1, 1, 1, 0.14)

# Pieces get one of these at random
const PIECE_COLORS := [
	Color(0.93, 0.29, 0.27),  # red
	Color(0.97, 0.56, 0.2),   # orange
	Color(0.98, 0.8, 0.16),   # yellow
	Color(0.32, 0.79, 0.38),  # green
	Color(0.2, 0.78, 0.92),   # cyan
	Color(0.27, 0.5, 0.96),   # blue
	Color(0.62, 0.38, 0.93),  # purple
	Color(0.93, 0.38, 0.72),  # pink
]

# Tint for a tray piece that doesn't fit anywhere on the board
const PIECE_UNPLAYABLE := Color(0.42, 0.42, 0.5)
