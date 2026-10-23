"""App icon / logo for Blockpack (original art), rendered with signed distance fields like backpack_icons.py.

Pure Python, no dependencies. Reuses the in-game backpack (variant b5) and draws the game's glossy blocks
(same look as scenes/blocks/block_visual.gd) on the game's background colors.

    python3 tools/app_icon.py <out_dir> [size] [variant ...]   # previews, app_icon_<variant>.png
    python3 tools/app_icon.py --final assets/icon j2              # the game's icon files (see below)

Variants:
    i1  the backpack with three colored blocks peeking out of the top
    i2  the backpack with a tilted L piece flying out of it, and sparkles
    i3  a 2x2 square of glossy blocks with the backpack's blue diamond in the middle (simplest, reads at tiny sizes)
    j1  a 4x4 board with a T piece falling into its gap, the backpack in the bottom-right corner releasing a bomb,
        a star and the diamond
    j2  the same idea mirrored: an L piece falling, the backpack bottom-left releasing power-ups to the left

The Play Store wants a 512x512 PNG with a full square background (Google rounds the corners itself).

--final writes, for one variant (j2 is the game's icon):
    icon.png             512x512, the project icon and the Play Store upload
    icon_foreground.png  432x432, Android adaptive icon foreground: the artwork without the background, shrunk so the
                         launcher's mask (circle, squircle...) doesn't cut it off
    icon_background.png  432x432, Android adaptive icon background: just the gradient
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import backpack_icons as bp  # noqa: E402

clamp, mix, smoothstep = bp.clamp, bp.mix, bp.smoothstep
box, circle, ellipse = bp.box, bp.circle, bp.ellipse
lighten, darken = bp.lighten, bp.darken

# configs/palette.gd
BG_TOP = (0.17, 0.2, 0.47)
BG_BOTTOM = (0.06, 0.07, 0.2)
RED = (0.93, 0.29, 0.27)
ORANGE = (0.97, 0.56, 0.2)
YELLOW = (0.98, 0.8, 0.16)
GREEN = (0.32, 0.79, 0.38)
CYAN = (0.2, 0.78, 0.92)
BLUE = (0.27, 0.5, 0.96)
PURPLE = (0.62, 0.38, 0.93)
PINK = (0.93, 0.38, 0.72)

BACKPACK = bp.DESIGNS["b5"]


def background(x, y, c):
    """The game's vertical gradient, with a soft glow behind the middle."""
    col = mix(BG_TOP, BG_BOTTOM, clamp(y))
    glow = 1.0 - clamp(math.hypot(x - 0.5, y - 0.46) / 0.55)
    col = mix(col, (0.38, 0.45, 0.95), 0.28 * glow * glow)
    c.fill(-1.0, col)


def rotate(x, y, cx, cy, deg):
    a = math.radians(deg)
    dx, dy = x - cx, y - cy
    return cx + dx * math.cos(a) + dy * math.sin(a), cy - dx * math.sin(a) + dy * math.cos(a)


def block(c, x, y, cx, cy, half, color, deg=0.0, shadow=True):
    """A glossy block like block_visual.gd: dark bevel bottom-right, light bevel top-left, face, gloss and a shine."""
    if deg:
        x, y = rotate(x, y, cx, cy, deg)
    r = half * 0.32
    bevel = half * 0.24
    if shadow:
        c.fill(box(x, y, cx + half * 0.12, cy + half * 0.2, half, half, r), (0, 0, 0), 0.35, softness=half * 0.18)
    c.fill(box(x, y, cx, cy, half, half, r), darken(color, 0.42))
    c.fill(box(x, y, cx - bevel * 0.4, cy - bevel * 0.4, half - bevel * 0.4, half - bevel * 0.4, r), lighten(color, 0.32))
    face = box(x, y, cx, cy, half - bevel, half - bevel, r * 0.65)
    c.fill(face, color)
    # gloss over the top half of the face
    c.fill(max(face, y - cy), (1, 1, 1), 0.16)
    c.fill(circle(x, y, cx - (half - bevel) * 0.52, cy - (half - bevel) * 0.52, half * 0.13), (1, 1, 1), 0.5)


def backpack_at(c, x, y, ox, oy, scale):
    """The b5 backpack drawn in the square (ox, oy)-(ox + scale, oy + scale)."""
    bx, by = (x - ox) / scale, (y - oy) / scale
    if -0.05 < bx < 1.05 and -0.05 < by < 1.05:
        inner = bp.Canvas(c.aa / scale)
        BACKPACK(bx, by, inner)
        for col, a in inner.layers:
            c.layers.append((col, a))


def sparkle(c, x, y, cx, cy, s, alpha=0.9):
    star = min(bp.rhombus(x, y, cx, cy, s * 0.18, s), bp.rhombus(x, y, cx, cy, s, s * 0.18))
    c.fill(star, (1, 1, 1), alpha, softness=s * 0.08)


def icon_i1(x, y, c):
    background(x, y, c)
    # blocks behind the bag's flap, so they look like they're sticking out of it
    block(c, x, y, 0.36, 0.25, 0.085, RED, deg=-14)
    block(c, x, y, 0.52, 0.19, 0.09, YELLOW, deg=6)
    block(c, x, y, 0.66, 0.26, 0.085, CYAN, deg=16)
    backpack_at(c, x, y, 0.1, 0.17, 0.8)


def icon_i2(x, y, c):
    background(x, y, c)
    # an L piece tumbling out of the bag, up and to the right
    for (gx, gy), col in (((0, 0), GREEN), ((0, 1), GREEN), ((0, 2), GREEN), ((1, 2), GREEN)):
        px, py = rotate(0.64 + gx * 0.1, 0.12 + gy * 0.1, 0.69, 0.22, -22)
        block(c, x, y, px, py, 0.05, col, deg=22)
    block(c, x, y, 0.27, 0.22, 0.055, PINK, deg=-18)
    sparkle(c, x, y, 0.2, 0.36, 0.035)
    sparkle(c, x, y, 0.86, 0.46, 0.03, 0.7)
    sparkle(c, x, y, 0.46, 0.12, 0.025, 0.6)
    backpack_at(c, x, y, 0.14, 0.24, 0.72)


def icon_i3(x, y, c):
    background(x, y, c)
    half = 0.16
    gap = 0.012
    for (gx, gy), col in (((-1, -1), RED), ((1, -1), YELLOW), ((-1, 1), BLUE), ((1, 1), GREEN)):
        block(c, x, y, 0.5 + gx * (half + gap), 0.5 + gy * (half + gap), half, col)
    c.fill(bp.rhombus(x - 0.012, y - 0.02, 0.5, 0.5, 0.11, 0.15), (0, 0, 0), 0.35, softness=0.02)
    bp.paint_gem(c, x, y, 0.5, 0.5, 0.11, 0.15)


# ---------------- board + falling piece ----------------

BOARD = (0.05, 0.07, 0.19)
BOARD_BORDER = (0.36, 0.42, 0.85)
CELL_EMPTY = (0.1, 0.13, 0.31)
INK_NAVY = (0.04, 0.05, 0.13)


def star5(x, y, cx, cy, r, rf):
    """Five-pointed star (Inigo Quilez's sdStar5), point up. rf = inner/outer radius ratio."""
    k1x, k1y = 0.809016994375, -0.587785252292
    k2x, k2y = -k1x, k1y
    px, py = abs(x - cx), (cy - y)
    d = max(k1x * px + k1y * py, 0.0)
    px, py = px - 2 * d * k1x, py - 2 * d * k1y
    d = max(k2x * px + k2y * py, 0.0)
    px, py = px - 2 * d * k2x, py - 2 * d * k2y
    px = abs(px)
    py -= r
    bax, bay = rf * -k1y, rf * k1x - 1.0
    h = clamp((px * bax + py * bay) / (bax * bax + bay * bay), 0.0, r)
    qx, qy = px - bax * h, py - bay * h
    sign = 1.0 if py * bax - px * bay > 0 else -1.0
    return math.hypot(qx, qy) * sign


def gold_star(c, x, y, cx, cy, r, deg=0.0):
    if deg:
        x, y = rotate(x, y, cx, cy, deg)
    c.fill(star5(x + r * 0.08, y - r * 0.12, cx, cy, r, 0.45), (0, 0, 0), 0.3, softness=r * 0.15)
    c.fill(star5(x, y, cx, cy, r, 0.45) - r * 0.1, bp.INK)
    c.fill(star5(x, y, cx, cy, r, 0.45), (0.95, 0.66, 0.12))
    c.fill(star5(x, y, cx - r * 0.06, cy - r * 0.08, r * 0.72, 0.45), (1.0, 0.86, 0.3))
    c.fill(circle(x, y, cx - r * 0.25, cy - r * 0.3, r * 0.12), (1, 1, 1), 0.7)


def bomb(c, x, y, cx, cy, r):
    """A round bomb with a fuse and a spark, like the game's bomb power-up."""
    c.fill(circle(x, y, cx + r * 0.1, cy + r * 0.15, r), (0, 0, 0), 0.3, softness=r * 0.2)
    c.fill(circle(x, y, cx, cy, r + r * 0.12), bp.INK)
    c.fill(circle(x, y, cx, cy, r), (0.16, 0.18, 0.3))
    c.fill(circle(x, y, cx - r * 0.12, cy - r * 0.12, r * 0.75), (0.24, 0.27, 0.42))
    c.fill(circle(x, y, cx - r * 0.38, cy - r * 0.4, r * 0.2), (1, 1, 1), 0.55)
    # neck and fuse curling up to the right
    c.fill(box(x, y, cx + r * 0.55, cy - r * 0.78, r * 0.22, r * 0.18, r * 0.05), bp.INK)
    c.fill(box(x, y, cx + r * 0.55, cy - r * 0.78, r * 0.15, r * 0.11, r * 0.04), (0.55, 0.58, 0.68))
    fuse = abs(circle(x, y, cx + r * 1.05, cy - r * 0.95, r * 0.45)) - r * 0.07
    fuse = max(fuse, (x - (cx + r * 1.05)), -(y - (cy - r * 0.95)) - r * 0.05)
    c.fill(fuse, (0.82, 0.68, 0.45))
    sx, sy = cx + r * 1.05, cy - r * 1.45
    c.fill(circle(x, y, sx, sy, r * 0.35), (1.0, 0.55, 0.15), 0.5, softness=r * 0.2)
    sparkle(c, x, y, sx, sy, r * 0.42)


def board(c, x, y, ox, oy, cols, rows, cell, filled, colors):
    """A board panel with recessed empty cells and glossy blocks where `filled` has a color index."""
    pad = cell * 0.22
    w, h = cols * cell + pad * 2, rows * cell + pad * 2
    cx, cy = ox + w / 2, oy + h / 2
    c.fill(box(x, y, cx + cell * 0.08, cy + cell * 0.16, w / 2, h / 2, cell * 0.35), (0, 0, 0), 0.4, softness=cell * 0.3)
    c.fill(box(x, y, cx, cy, w / 2 + cell * 0.05, h / 2 + cell * 0.05, cell * 0.4), mix(BOARD_BORDER, BOARD, 0.45))
    c.fill(box(x, y, cx, cy, w / 2, h / 2, cell * 0.35), BOARD)
    half = cell * 0.46
    for r in range(rows):
        for col in range(cols):
            bx, by = ox + pad + (col + 0.5) * cell, oy + pad + (r + 0.5) * cell
            if abs(x - bx) > cell or abs(y - by) > cell:
                continue
            k = filled[r][col]
            if k is None:
                c.fill(box(x, y, bx, by, half, half, half * 0.3), CELL_EMPTY)
                c.fill(max(box(x, y, bx, by, half, half, half * 0.3), y - (by - half * 0.1)), (0, 0, 0), 0.14)
            else:
                block(c, x, y, bx, by, half, colors[k], shadow=False)
    return pad


def falling_piece(c, x, y, ox, oy, cell, shape, color, drop):
    """The piece hovering `drop` above its spot, with speed streaks above it and a faint ghost where it lands."""
    half = cell * 0.46
    for gx, gy in shape:
        bx, by = ox + (gx + 0.5) * cell, oy + (gy + 0.5) * cell
        # ghost in the gap
        c.fill(abs(box(x, y, bx, by, half * 0.9, half * 0.9, half * 0.3)) - cell * 0.025, lighten(color, 0.4), 0.55)
    tops = {}
    for gx, gy in shape:
        tops[gx] = min(tops.get(gx, gy), gy)
    for gx, gy in tops.items():
        sx = ox + (gx + 0.5) * cell
        top = oy + gy * cell - drop
        for i, (w, ln) in enumerate(((0.07, 0.55), (0.045, 0.85))):
            off = (i * 2 - 1) * cell * 0.18
            d = box(x, y, sx + off, top - cell * ln / 2 - cell * 0.1, cell * w, cell * ln / 2, cell * w)
            fade = clamp((y - (top - cell * (ln + 0.1))) / (cell * ln))
            if fade > 0:
                c.fill(d, (1, 1, 1), 0.35 * fade)
    for gx, gy in shape:
        block(c, x, y, ox + (gx + 0.5) * cell, oy + (gy + 0.5) * cell - drop, half, color)


def icon_j1(x, y, c):
    background(x, y, c)
    cols = colors = (RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, PINK)
    R, O, Y, G, C, B, P = range(7)
    _ = cols
    n = None
    filled = [
        [B, n, n, n],
        [G, Y, n, R],
        [C, R, O, B],
        [O, B, G, Y],
    ]
    cell = 0.13
    ox, oy = 0.09, 0.33
    pad = board(c, x, y, ox, oy, 4, 4, cell, filled, colors)
    # T piece (3 on top, 1 under the middle) dropping into the gap, which completes the two top rows
    falling_piece(c, x, y, ox + pad, oy + pad, cell, [(1, 0), (2, 0), (3, 0), (2, 1)], PURPLE, drop=cell * 1.6)
    # power-ups bursting out of the backpack (everything stays inside the rounded-corner safe area)
    bomb(c, x, y, 0.67, 0.43, 0.05)
    gold_star(c, x, y, 0.86, 0.45, 0.062, deg=12)
    c.fill(bp.rhombus(x - 0.008, y - 0.012, 0.8, 0.3, 0.037, 0.05), (0, 0, 0), 0.3, softness=0.015)
    bp.paint_gem(c, x, y, 0.8, 0.3, 0.037, 0.05)
    sparkle(c, x, y, 0.9, 0.31, 0.022, 0.8)
    backpack_at(c, x, y, 0.54, 0.5, 0.4)


def icon_j2(x, y, c):
    background(x, y, c)
    content_j2(x, y, c)


def content_j2(x, y, c):
    colors = (RED, ORANGE, YELLOW, GREEN, CYAN, BLUE, PINK)
    R, O, Y, G, C, B, P = range(7)
    n = None
    filled = [
        [n, n, n, P],
        [n, R, Y, C],
        [O, B, G, R],
        [Y, G, C, B],
    ]
    cell = 0.13
    ox, oy = 0.33, 0.33
    pad = board(c, x, y, ox, oy, 4, 4, cell, filled, colors)
    # L piece (three across on top, one hanging down on the left)
    falling_piece(c, x, y, ox + pad, oy + pad, cell, [(0, 0), (1, 0), (2, 0), (0, 1)], CYAN, drop=cell * 1.6)
    bomb(c, x, y, 0.3, 0.43, 0.05)
    gold_star(c, x, y, 0.13, 0.45, 0.062, deg=-12)
    c.fill(bp.rhombus(x - 0.008, y - 0.012, 0.2, 0.3, 0.037, 0.05), (0, 0, 0), 0.3, softness=0.015)
    bp.paint_gem(c, x, y, 0.2, 0.3, 0.037, 0.05)
    sparkle(c, x, y, 0.1, 0.31, 0.022, 0.8)
    backpack_at(c, x, y, 0.06, 0.5, 0.4)


DESIGNS = {"i1": icon_i1, "i2": icon_i2, "i3": icon_i3, "j1": icon_j1, "j2": icon_j2}

# The artwork without the background, for the adaptive icon foreground
CONTENT = {"j2": content_j2}

# Adaptive icons: the launcher shows the middle 72 of 108dp and may mask it to a circle, so the artwork is shrunk
# to this fraction of the canvas, around its centre
ADAPTIVE_SCALE = 0.6


def scaled(design, scale):
    """The design shrunk to `scale` around the centre, transparent around it."""
    def wrapped(x, y, c):
        sx, sy = 0.5 + (x - 0.5) / scale, 0.5 + (y - 0.5) / scale
        if -0.05 < sx < 1.05 and -0.05 < sy < 1.05:
            inner = bp.Canvas(c.aa / scale)
            design(sx, sy, inner)
            c.layers.extend(inner.layers)
    return wrapped


def write_final(out_dir, key):
    os.makedirs(out_dir, exist_ok=True)
    jobs = [
        ("icon.png", 512, DESIGNS[key]),
        ("icon_foreground.png", 432, scaled(CONTENT[key], ADAPTIVE_SCALE)),
        ("icon_background.png", 432, background),
    ]
    for name, size, design in jobs:
        path = os.path.join(out_dir, name)
        bp.write_png(path, size, bp.render(design, size, ss=2))
        print("wrote", path, flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "--final":
        write_final(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "j2")
        sys.exit(0)
    out_dir = sys.argv[1]
    size = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 512
    keys = [a for a in sys.argv[2:] if not a.isdigit()] or list(DESIGNS)
    for key in keys:
        path = os.path.join(out_dir, f"app_icon_{key}.png")
        bp.write_png(path, size, bp.render(DESIGNS[key], size, ss=2))
        print("wrote", path, flush=True)
