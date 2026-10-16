"""Backpack icon for the backpack bar (original art), rendered with signed distance fields.

Pure Python, no dependencies. Writes PNGs into the given folder:

    python3 tools/backpack_icons.py assets/ui              # every variant
    python3 tools/backpack_icons.py assets/ui b2           # just one

Variants (all the same rucksack: top straps, side pockets, rounded flap, centre strap with a buckle, front pocket):
    b   glossy game icon, flat shading (the original pick)
    b1  soft 3D: every part is lit like a rounded pillow and casts a small shadow
    b2  thick 3D: b1 plus visible depth (side and top of the bag)
    b3  puffy 3D: rounder and glossier, with a carry handle on top
    b4  thick 3D in forest green with a brass buckle
    b5  soft 3D like b1, with a faceted blue diamond on the strap instead of the buckle (the one in the game)
"""
import math
import os
import struct
import sys
import zlib


# ---------------- maths ----------------

def clamp(x, a=0.0, b=1.0):
    return a if x < a else b if x > b else x


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def smoothstep(e0, e1, x):
    t = clamp((x - e0) / (e1 - e0))
    return t * t * (3 - 2 * t)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def lighten(c, t):
    return mix(c, (1, 1, 1), t)


def darken(c, t):
    return mix(c, (0, 0, 0), t)


def normalize(v):
    n = math.sqrt(sum(a * a for a in v))
    return tuple(a / n for a in v)


def box(x, y, cx, cy, hw, hh, r):
    """Rounded box: centre, half size, corner radius."""
    qx = abs(x - cx) - (hw - r)
    qy = abs(y - cy) - (hh - r)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def circle(x, y, cx, cy, r):
    return math.hypot(x - cx, y - cy) - r


def ellipse(x, y, cx, cy, rx, ry):
    return (math.hypot((x - cx) / rx, (y - cy) / ry) - 1.0) * min(rx, ry)


def hash2(x, y):
    n = math.sin(x * 127.1 + y * 311.7) * 43758.5453
    return n - math.floor(n)


INK = hexc("#2b1308")
LIGHT = normalize((-0.45, -0.65, 0.62))  # from the upper left, towards the viewer
HALF = normalize((LIGHT[0], LIGHT[1], LIGHT[2] + 1.0))


# ---------------- compositing ----------------

class Canvas:
    """Collects layers for one sample point, painted back to front."""

    def __init__(self, aa):
        self.aa = aa  # edge softness, about one output pixel
        self.layers = []

    def fill(self, d, color, alpha=1.0, softness=None):
        s = softness or self.aa
        a = smoothstep(s, -s, d) * alpha
        if a > 0:
            self.layers.append((color, a))

    def result(self):
        r = g = b = 0.0
        alpha = 0.0
        for col, a in self.layers:
            r = col[0] * a + r * (1 - a)
            g = col[1] * a + g * (1 - a)
            b = col[2] * a + b * (1 - a)
            alpha = a + alpha * (1 - a)
        if alpha <= 0:
            return (0, 0, 0, 0)
        return (r / alpha, g / alpha, b / alpha, alpha)


def flat_shade(base, x, y, top, bottom):
    """Vertical gradient from light at `top` to dark at `bottom`, plus fine grain."""
    t = clamp((y - top) / (bottom - top))
    col = mix(lighten(base, 0.18), darken(base, 0.22), t)
    g = (hash2(math.floor(x * 300), math.floor(y * 300)) - 0.5) * 0.04
    return tuple(clamp(v + g) for v in col)


def lit_shade(sdf, d, x, y, base, bevel, gloss):
    """Pillow shading: the part's edge rounds over within `bevel`, lit by LIGHT with a specular highlight."""
    e = 0.003
    gx = (sdf(x + e, y) - sdf(x - e, y)) / (2 * e)
    gy = (sdf(x, y + e) - sdf(x, y - e)) / (2 * e)
    slope = (1.0 - clamp(-d / bevel)) ** 1.6 * 1.8  # steep at the edge, flat in the middle
    n = normalize((gx * slope, gy * slope, 1.0))
    diffuse = max(0.0, n[0] * LIGHT[0] + n[1] * LIGHT[1] + n[2] * LIGHT[2])
    spec = max(0.0, n[0] * HALF[0] + n[1] * HALF[1] + n[2] * HALF[2]) ** 36 * gloss
    grain = (hash2(math.floor(x * 300), math.floor(y * 300)) - 0.5) * 0.035
    return tuple(clamp(c * (0.38 + 0.8 * diffuse) + spec + grain) for c in base)


# ---------------- the rucksack ----------------

BROWN = {
    "leather": hexc("#b8652d"),
    "flap": hexc("#d07e3e"),
    "dark": hexc("#6a3115"),
    "pocket": hexc("#9c5226"),
    "metal": hexc("#cfe3ea"),
    "metal_dark": hexc("#7e98a3"),
}
GREEN = {
    "leather": hexc("#4f7a3a"),
    "flap": hexc("#69974c"),
    "dark": hexc("#2f4a22"),
    "pocket": hexc("#43682f"),
    "metal": hexc("#f0c75a"),
    "metal_dark": hexc("#a7791f"),
}


GEM = {
    "light": hexc("#bfe9ff"),
    "mid": hexc("#4fb6f5"),
    "dark": hexc("#1f6fc2"),
    "deep": hexc("#164c8f"),
}


def rhombus(x, y, cx, cy, hw, hh):
    """Diamond (rotated square) with half width hw and half height hh."""
    k = math.hypot(hw, hh)
    return (abs(x - cx) * hh + abs(y - cy) * hw - hw * hh) / k


def paint_gem(c, x, y, cx, cy, hw, hh):
    """Faceted gem: dark outline, four facets lit from the upper left, a lighter table and a sparkle."""
    d = rhombus(x, y, cx, cy, hw, hh)
    c.fill(d - 0.012, INK)
    if d < c.aa:
        left, top = x < cx, y < cy
        facet = GEM["mid"] if left and top else GEM["dark"] if top or left else GEM["deep"]
        if left and top:
            facet = lighten(facet, 0.25)
        c.fill(d, facet)
        table = rhombus(x, y, cx, cy - hh * 0.08, hw * 0.48, hh * 0.48)
        c.fill(table, mix(GEM["mid"], GEM["light"], 0.55 if x < cx else 0.2))
        # sparkle: a small four-pointed star near the top-left facet
        sx, sy = cx - hw * 0.35, cy - hh * 0.4
        star = min(rhombus(x, y, sx, sy, hw * 0.06, hh * 0.32), rhombus(x, y, sx, sy, hw * 0.3, hh * 0.05))
        c.fill(star, (1, 1, 1), 0.9)


def make_rucksack(palette, lit=False, depth=None, puffy=False, handle=False, gem=False):
    """Builds a design function. depth = (dx, dy) shows the bag's side and top, receding that way."""
    p = palette
    k = 1.25 if puffy else 1.0  # corner roundness
    bevel = 0.06 if puffy else 0.035
    gloss = 0.75 if puffy else 0.45
    fx = -depth[0] * 0.5 if depth else 0.0  # the front face moves away from the depth so the whole bag stays centred
    fy = -depth[1] * 0.5 if depth else 0.0

    def parts(x, y):
        x, y = x - fx, y - fy
        return {
            "ears": [] if handle else [lambda a, b, ex=ex: box(a - fx, b - fy, ex, 0.2, 0.07, 0.09, 0.05 * k) for ex in (0.33, 0.67)],
            "handle": (lambda a, b: max(abs(circle(a - fx, b - fy, 0.5, 0.2, 0.09)) - 0.03, (b - fy) - 0.24)) if handle else None,
            "sides": [lambda a, b, sx=sx: box(a - fx, b - fy, sx, 0.62, 0.1, 0.17, min(0.1, 0.07 * k)) for sx in (0.18, 0.82)],
            "body": lambda a, b: box(a - fx, b - fy, 0.5, 0.56, 0.29, 0.33, min(0.2, 0.15 * k)),
        }

    def design(x, y, c):
        pr = parts(x, y)
        body = pr["body"]
        flap = lambda a, b: max(box(a - fx, b - fy, 0.5, 0.39, 0.27, 0.17, min(0.2, 0.15 * k)), body(a, b) + 0.012)
        pocket = lambda a, b: box(a - fx, b - fy, 0.5, 0.73, 0.19, 0.12, 0.07 * k)
        strap = lambda a, b: box(a - fx, b - fy, 0.5, 0.5, 0.05, 0.17, 0.02)
        buckle = lambda a, b: box(a - fx, b - fy, 0.5, 0.62, 0.075, 0.06, 0.02 * k)

        back = list(pr["ears"]) + list(pr["sides"])
        if pr["handle"]:
            back.append(pr["handle"])
        silhouette = lambda a, b: min([body(a, b)] + [f(a, b) for f in back])

        # how far the bag reaches back: the silhouette swept along the depth direction
        if depth:
            steps = 7
            def extruded(a, b):
                return min(silhouette(a - depth[0] * i / steps, b - depth[1] * i / steps) for i in range(steps + 1))
        else:
            extruded = silhouette

        # ground shadow and the thick outline around everything
        c.fill(ellipse(x, y, 0.5, 0.94, 0.36, 0.045), (0, 0, 0), 0.35, softness=0.03)
        ext = extruded(x, y)
        c.fill(ext - 0.026, INK)

        # the bag's side and top, darker than the front and getting darker further back
        if depth:
            if ext < c.aa:
                t = clamp(((x - fx) * depth[0] + (y - fy) * depth[1]) / (depth[0] ** 2 + depth[1] ** 2))
                c.fill(ext, darken(p["leather"], 0.35 + 0.25 * t))

        def paint(sdf, base, shadow=True, part_bevel=None):
            d = sdf(x, y)
            if lit and shadow:
                # soft shadow this part casts down-right onto what's under it
                c.fill(sdf(x - 0.012, y - 0.02), (0, 0, 0), 0.28, softness=0.02)
            if d < c.aa:
                if lit:
                    col = lit_shade(sdf, d, x, y, base, part_bevel or bevel, gloss)
                else:
                    col = flat_shade(base, x, y, 0.1, 0.9)
                c.fill(d, col)
            return d

        for f in back:
            paint(f, p["dark"], shadow=False)
        if not lit:
            for f in pr["sides"]:
                d = f(x, y)
                c.fill(d + 0.03, flat_shade(lighten(p["dark"], 0.12), x, y, 0.45, 0.8))

        paint(body, p["leather"], shadow=False, part_bevel=bevel * 1.6)

        # flap with a dark seam under its lower edge
        fd = flap(x, y)
        c.fill(fd + 0.012 - 0.022 * smoothstep(0.4, 0.56, y - fy), INK, 0.55)
        paint(lambda a, b: flap(a, b) + 0.02, p["flap"])

        pd = pocket(x, y)
        c.fill(pd, INK, 0.6)
        paint(lambda a, b: pocket(a, b) + 0.014, p["pocket"])

        sd = strap(x, y)
        c.fill(sd, INK, 0.5)
        paint(lambda a, b: strap(a, b) + 0.008, p["dark"], part_bevel=0.02)

        if gem:
            c.fill(rhombus(x - 0.01, y - 0.016, 0.5 + fx, 0.62 + fy, 0.085, 0.11), (0, 0, 0), 0.3, softness=0.02)
            paint_gem(c, x, y, 0.5 + fx, 0.62 + fy, 0.085, 0.11)
        else:
            bd = buckle(x, y)
            c.fill(bd, INK)
            paint(lambda a, b: buckle(a, b) + 0.008, p["metal"], part_bevel=0.025)
            c.fill(box(x - fx, y - fy, 0.5, 0.62, 0.03, 0.022, 0.008), p["metal_dark"] if lit else p["dark"])

        # gloss
        if not lit:
            c.fill(ellipse(x, y, 0.38 + fx, 0.29 + fy, 0.11, 0.045), (1, 1, 1), 0.28)
            c.fill(ellipse(x, y, 0.3 + fx, 0.6 + fy, 0.025, 0.09), (1, 1, 1), 0.12)
        elif puffy:
            c.fill(ellipse(x, y, 0.37 + fx, 0.27 + fy, 0.1, 0.035), (1, 1, 1), 0.45, softness=0.012)

    return design


DESIGNS = {
    "b": make_rucksack(BROWN),
    "b1": make_rucksack(BROWN, lit=True),
    "b2": make_rucksack(BROWN, lit=True, depth=(0.07, -0.045)),
    "b3": make_rucksack(BROWN, lit=True, puffy=True, handle=True),
    "b4": make_rucksack(GREEN, lit=True, depth=(0.07, -0.045)),
    "b5": make_rucksack(BROWN, lit=True, gem=True),
}


# ---------------- rendering ----------------

def render(design, size, ss=3):
    rows = []
    aa = 1.0 / size
    for py in range(size):
        row = bytearray([0])
        for px in range(size):
            acc = [0.0, 0.0, 0.0, 0.0]
            for sy in range(ss):
                for sx in range(ss):
                    x = (px + (sx + 0.5) / ss) / size
                    y = (py + (sy + 0.5) / ss) / size
                    canvas = Canvas(aa)
                    design(x, y, canvas)
                    r, g, b, a = canvas.result()
                    acc[0] += r * a
                    acc[1] += g * a
                    acc[2] += b * a
                    acc[3] += a
            a = acc[3] / (ss * ss)
            rgb = [clamp(acc[i] / acc[3]) for i in range(3)] if acc[3] > 0 else [0, 0, 0]
            row += bytes([int(rgb[0] * 255 + 0.5), int(rgb[1] * 255 + 0.5), int(rgb[2] * 255 + 0.5), int(a * 255 + 0.5)])
        rows.append(bytes(row))
    return b"".join(rows)


def write_png(path, size, raw):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    size = 192
    for key in sys.argv[2:] or list(DESIGNS):
        path = os.path.join(out_dir, f"backpack_option_{key}.png")
        write_png(path, size, render(DESIGNS[key], size))
        print("wrote", path, flush=True)
