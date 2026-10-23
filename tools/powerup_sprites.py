"""Power-up and trash can sprites in the same art style as the backpack (tools/backpack_icons.py, variant b5):
thick dark outline, soft 3D "pillow" shading lit from the upper left, small cast shadows, a ground shadow and fine grain.

Pure Python, no dependencies. Writes PNGs:

    python3 tools/powerup_sprites.py assets/powerups            # every sprite
    python3 tools/powerup_sprites.py assets/powerups laser       # just one
    python3 tools/powerup_sprites.py --preview <dir>             # all of them side by side in preview.png

Sprites (192x192 unless noted; the drawing code in scenes/ relies on where things sit, see the comments):
    bomb_body    198x198 for scenes/powerups/bomb_body.png: body centre at (99, 121), diameter 98px, cap at the top
                 right where the fuse (a Line2D in the scene) starts
    laser        cyan orb with a glowing cross
    prism        six-faceted gem, one facet per block color
    booster      gold star (the "+2" is drawn on top in code)
    hourglass    wooden caps, glass bulbs, sand
    trash_body   the bin without its lid
    trash_lid    the lid, hinged at its right end: hinge at (0.86, 0.5) of the texture
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import backpack_icons as bp  # noqa: E402

clamp, mix, smoothstep = bp.clamp, bp.mix, bp.smoothstep
box, circle, ellipse = bp.box, bp.circle, bp.ellipse
lighten, darken, hexc = bp.lighten, bp.darken, bp.hexc
INK = bp.INK
OUTLINE = 0.026  # same outline thickness as the backpack


def lit(c, sdf, x, y, base, bevel=0.035, gloss=0.45, shadow=True, outline=True):
    """Paints one part the way the backpack does: outline, soft cast shadow, pillow shading."""
    d = sdf(x, y)
    if outline:
        c.fill(d - OUTLINE, INK)
    if shadow:
        c.fill(sdf(x - 0.012, y - 0.02), (0, 0, 0), 0.28, softness=0.02)
    if d < c.aa:
        c.fill(d, bp.lit_shade(sdf, d, x, y, base, bevel, gloss))
    return d


def ground(c, x, y, cy=0.94, rx=0.34):
    c.fill(ellipse(x, y, 0.5, cy, rx, 0.045), (0, 0, 0), 0.35, softness=0.03)


def sparkle(c, x, y, cx, cy, s, alpha=0.95):
    star = min(bp.rhombus(x, y, cx, cy, s * 0.18, s), bp.rhombus(x, y, cx, cy, s, s * 0.18))
    c.fill(star, (1, 1, 1), alpha, softness=s * 0.1)


# ---------------- bomb ----------------

BOMB_C = (0.5, 121 / 198)
BOMB_R = 49 / 198


def bomb_body(x, y, c):
    cx, cy = BOMB_C
    c.fill(ellipse(x, y, cx, cy + BOMB_R + 0.03, BOMB_R * 0.9, 0.035), (0, 0, 0), 0.35, softness=0.025)
    body = lambda a, b: circle(a, b, cx, cy, BOMB_R)
    c.fill(body(x, y) - OUTLINE, INK)
    if body(x, y) < c.aa:
        c.fill(body(x, y), bp.lit_shade(body, body(x, y), x, y, hexc("#3a4160"), BOMB_R * 0.9, 0.9))
    # metal cap on the top right, where the fuse comes out
    cap = lambda a, b: box(a, b, cx + 0.03, cy - BOMB_R + 0.005, 0.045, 0.032, 0.012)
    lit(c, cap, x, y, hexc("#9aa6bd"), bevel=0.02, gloss=0.6)
    c.fill(box(x, y, cx + 0.03, cy - BOMB_R - 0.01, 0.03, 0.008, 0.004), darken(hexc("#9aa6bd"), 0.35))
    # a bright gloss spot, like the backpack's highlights
    c.fill(ellipse(x, y, cx - BOMB_R * 0.42, cy - BOMB_R * 0.45, BOMB_R * 0.22, BOMB_R * 0.12), (1, 1, 1), 0.55, softness=0.01)


# ---------------- laser ----------------

def laser(x, y, c):
    ground(c, x, y, 0.95, 0.28)
    cyan = hexc("#52e6ff")
    beam_w, beam_l = 0.075, 0.42
    beams = lambda a, b: min(box(a, b, 0.5, 0.5, beam_l, beam_w, beam_w), box(a, b, 0.5, 0.5, beam_w, beam_l, beam_w))
    orb = lambda a, b: circle(a, b, 0.5, 0.5, 0.3)
    # outline around both shapes together, then the orb, then the beams on top
    c.fill(min(beams(x, y), orb(x, y)) - OUTLINE, INK)
    c.fill(orb(x - 0.012, y - 0.02), (0, 0, 0), 0.28, softness=0.02)
    if orb(x, y) < c.aa:
        c.fill(orb(x, y), bp.lit_shade(orb, orb(x, y), x, y, hexc("#1d6fb3"), 0.2, 0.7))
    # soft cyan glow inside the orb around the cross
    c.fill(circle(x, y, 0.5, 0.5, 0.16), cyan, 0.35, softness=0.08)
    db = beams(x, y)
    c.fill(db + 0.012, INK, 0.5)
    if db < c.aa:
        c.fill(db + 0.012, bp.lit_shade(beams, db, x, y, cyan, 0.04, 0.5))
    # bright core lines and the centre
    core = min(box(x, y, 0.5, 0.5, beam_l - 0.03, 0.022, 0.02), box(x, y, 0.5, 0.5, 0.022, beam_l - 0.03, 0.02))
    c.fill(core, (1, 1, 1), 0.85)
    c.fill(circle(x, y, 0.5, 0.5, 0.06), (1, 1, 1))
    sparkle(c, x, y, 0.34, 0.33, 0.05)


# ---------------- prism ----------------

PRISM_COLORS = [hexc("#ee4a45"), hexc("#f78f33"), hexc("#facc29"), hexc("#52ca61"), hexc("#4580f5"), hexc("#9e61ed")]


def hexagon(x, y, cx, cy, r):
    """Pointy-top hexagon with circumradius r: vertical sides left and right, points up and down."""
    px, py = abs(x - cx), abs(y - cy)
    return max(px, 0.5 * px + 0.8660254 * py) - 0.8660254 * r


def prism(x, y, c):
    ground(c, x, y, 0.95, 0.27)
    cx, cy, r = 0.5, 0.5, 0.36
    hx = lambda a, b: hexagon(a, b, cx, cy, r)
    d = hx(x, y)
    c.fill(d - OUTLINE, INK)
    c.fill(hx(x - 0.012, y - 0.02), (0, 0, 0), 0.28, softness=0.02)
    if d < c.aa:
        # facet by angle around the centre, lit by how much it faces the upper left
        a = math.atan2(y - cy, x - cx)
        i = int(((a + math.pi / 2) % math.tau) / (math.tau / 6)) % 6
        mid = -math.pi / 2 + (i + 0.5) * math.tau / 6
        facing = math.cos(mid) * -0.6 + math.sin(mid) * -0.8
        base = PRISM_COLORS[i]
        col = lighten(base, 0.3 * max(facing, 0)) if facing > 0 else darken(base, 0.3 * -facing)
        c.fill(d, bp.lit_shade(hx, d, x, y, col, 0.05, 0.35))
        # dark seams between the facets
        seam = abs(math.sin((a - mid) * 3)) * math.hypot(x - cx, y - cy)
        c.fill(seam - 0.006, darken(base, 0.45), 0.55)
    # the table: a lighter hexagon in the middle
    table = lambda a, b: hexagon(a, b, cx, cy - 0.01, r * 0.42)
    dt = table(x, y)
    c.fill(dt - 0.008, INK, 0.45)
    if dt < c.aa:
        c.fill(dt, bp.lit_shade(table, dt, x, y, (0.93, 0.96, 1.0), 0.03, 0.8))
    sparkle(c, x, y, 0.36, 0.31, 0.06)


# ---------------- booster ----------------

def star5(x, y, cx, cy, r, rf):
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
    return math.hypot(qx, qy) * (1.0 if py * bax - px * bay > 0 else -1.0)


def booster(x, y, c):
    ground(c, x, y, 0.93, 0.3)
    st = lambda a, b: star5(a, b, 0.5, 0.53, 0.42, 0.5) - 0.025  # rounded points
    d = st(x, y)
    c.fill(d - OUTLINE, INK)
    c.fill(st(x - 0.012, y - 0.02), (0, 0, 0), 0.28, softness=0.02)
    if d < c.aa:
        c.fill(d, bp.lit_shade(st, d, x, y, hexc("#f5b52a"), 0.09, 0.7))
    sparkle(c, x, y, 0.36, 0.3, 0.05)


# ---------------- hourglass ----------------

def hourglass(x, y, c):
    ground(c, x, y, 0.95, 0.3)
    wood = hexc("#b8652d")  # the backpack's leather brown
    # glass: two bulbs that meet at the neck
    bulb_top = lambda a, b: ellipse(a, b, 0.5, 0.33, 0.21, 0.17)
    bulb_bottom = lambda a, b: ellipse(a, b, 0.5, 0.67, 0.21, 0.17)
    neck = lambda a, b: box(a, b, 0.5, 0.5, 0.035, 0.08, 0.02)
    glass = lambda a, b: min(bulb_top(a, b), bulb_bottom(a, b), neck(a, b))
    dg = glass(x, y)
    c.fill(dg - OUTLINE, INK)
    if dg < c.aa:
        c.fill(dg, mix(hexc("#2a3a6a"), hexc("#bfe9ff"), 0.35))
    # sand: what's left on top, the stream, and the pile at the bottom
    sand = hexc("#f4c45a")
    sand_top = lambda a, b: max(bulb_top(a, b) + 0.02, -(b - 0.36))
    sand_bottom = lambda a, b: max(bulb_bottom(a, b) + 0.02, -(b - 0.66) + abs(a - 0.5) * -0.6)
    for s in (sand_top, sand_bottom):
        ds = s(x, y)
        if ds < c.aa:
            c.fill(ds, bp.lit_shade(s, ds, x, y, sand, 0.03, 0.3))
    c.fill(box(x, y, 0.5, 0.53, 0.008, 0.13, 0.006), sand)
    # shine on the glass
    c.fill(ellipse(x, y, 0.41, 0.28, 0.035, 0.07), (1, 1, 1), 0.6, softness=0.01)
    c.fill(ellipse(x, y, 0.41, 0.63, 0.03, 0.05), (1, 1, 1), 0.4, softness=0.01)
    # wooden caps and the posts between them
    for px in (0.27, 0.73):
        lit(c, lambda a, b, px=px: box(a, b, px, 0.5, 0.025, 0.34, 0.015), x, y, darken(wood, 0.15), bevel=0.02)
    for cy in (0.13, 0.87):
        lit(c, lambda a, b, cy=cy: box(a, b, 0.5, cy, 0.3, 0.055, 0.03), x, y, wood)


# ---------------- trash can ----------------

METAL = hexc("#8e9bb8")


def trash_body(x, y, c):
    ground(c, x, y, 0.93, 0.3)

    # a bin that narrows towards the bottom: squeeze x by how far down we are
    def bin_shape(a, b):
        t = clamp((b - 0.32) / 0.56)
        squeeze = 1.0 + 0.22 * t
        return box(0.5 + (a - 0.5) * squeeze, b, 0.5, 0.6, 0.26, 0.28, 0.06)

    lit(c, bin_shape, x, y, METAL, bevel=0.06, gloss=0.5, shadow=False)
    # grooves down the front
    for gx in (0.4, 0.5, 0.6):
        t = clamp((y - 0.32) / 0.56)
        gxx = 0.5 + (gx - 0.5) / (1.0 + 0.22 * t)
        groove = lambda a, b, gxx=gxx: box(a, b, gxx, 0.62, 0.016, 0.2, 0.016)
        c.fill(groove(x, y), darken(METAL, 0.4), 0.75)
        c.fill(groove(x + 0.008, y), lighten(METAL, 0.35), 0.35)
    # a dark rim where the lid sits
    c.fill(box(x, y, 0.5, 0.345, 0.255, 0.02, 0.01), darken(METAL, 0.45))


LID_HINGE = (0.86, 0.5)


def trash_lid(x, y, c):
    lid = lambda a, b: box(a, b, 0.5, 0.5, 0.36, 0.05, 0.035)
    handle = lambda a, b: max(abs(box(a, b, 0.5, 0.43, 0.08, 0.05, 0.04)) - 0.018, b - 0.46)
    lit(c, handle, x, y, darken(METAL, 0.2), bevel=0.02)
    lit(c, lid, x, y, lighten(METAL, 0.12), bevel=0.04, gloss=0.6)
    c.fill(ellipse(x, y, 0.33, 0.475, 0.1, 0.012), (1, 1, 1), 0.45, softness=0.006)


SPRITES = {
    "bomb_body": (bomb_body, 198),
    "laser": (laser, 192),
    "prism": (prism, 192),
    "booster": (booster, 192),
    "hourglass": (hourglass, 192),
    "trash_body": (trash_body, 192),
    "trash_lid": (trash_lid, 192),
}


def preview(out_dir):
    """All sprites side by side on the game's background color, 160px each."""
    size, n = 160, len(SPRITES)
    bg = (0.1, 0.13, 0.31)
    tiles = [bp.render(design, size, ss=2) for design, _ in SPRITES.values()]
    rows = []
    for py in range(size):
        row = bytearray([0])
        for t in tiles:
            line = t[py * (size * 4 + 1) + 1:(py + 1) * (size * 4 + 1)]
            for i in range(0, len(line), 4):
                a = line[i + 3] / 255
                row += bytes([int(line[i + k] * a + bg[k] * 255 * (1 - a)) for k in range(3)] + [255])
        rows.append(bytes(row))
    raw = b"".join(rows)
    path = os.path.join(out_dir, "preview.png")
    write_png_wh(path, size * n, size, raw)
    print("wrote", path)


def write_png_wh(path, w, h, raw):
    import struct
    import zlib

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    if sys.argv[1] == "--preview":
        preview(sys.argv[2])
        sys.exit(0)
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for key in sys.argv[2:] or list(SPRITES):
        design, size = SPRITES[key]
        path = os.path.join(out_dir, f"{key}.png")
        bp.write_png(path, size, bp.render(design, size))
        print("wrote", path, flush=True)
