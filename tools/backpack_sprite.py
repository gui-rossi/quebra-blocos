"""Renders an original leather-sack backpack icon to PNG with signed distance fields (pure Python, no deps).

Usage: python3 backpack_sprite.py OUT.png [SIZE]
"""
import math
import struct
import sys
import zlib

SIZE = int(sys.argv[2]) if len(sys.argv) > 2 else 256
SS = 3  # supersamples per axis

LEATHER = (0.72, 0.39, 0.16)
LEATHER_DARK = (0.22, 0.09, 0.03)
OUTLINE = (0.16, 0.07, 0.03)
LIGHT_DIR = (-0.55, -0.7)  # light from the upper left


def clamp(x, a=0.0, b=1.0):
    return a if x < a else b if x > b else x


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def smoothstep(e0, e1, x):
    t = clamp((x - e0) / (e1 - e0))
    return t * t * (3 - 2 * t)


def ellipse_sdf(x, y, cx, cy, rx, ry):
    # approximate: scaled distance, good enough for soft shapes
    dx, dy = (x - cx) / rx, (y - cy) / ry
    k = math.hypot(dx, dy)
    return (k - 1.0) * min(rx, ry)


def smin(a, b, k):
    h = clamp(0.5 + 0.5 * (b - a) / k)
    return b + (a - b) * h - k * h * (1 - h)


def hash_noise(x, y):
    n = math.sin(x * 127.1 + y * 311.7) * 43758.5453
    return n - math.floor(n)


def value_noise(x, y):
    xi, yi = math.floor(x), math.floor(y)
    xf, yf = x - xi, y - yi
    u, v = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
    a = hash_noise(xi, yi)
    b = hash_noise(xi + 1, yi)
    c = hash_noise(xi, yi + 1)
    d = hash_noise(xi + 1, yi + 1)
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v


def grain(x, y):
    return 0.6 * value_noise(x * 40, y * 40) + 0.4 * value_noise(x * 90, y * 90)


def warp(x, y):
    # lumpy, hand-made outline instead of perfect ellipses
    return (x + 0.018 * (value_noise(x * 6, y * 6) - 0.5), y + 0.018 * (value_noise(x * 6 + 7, y * 6 + 3) - 0.5))


def body_sdf(x, y):
    x, y = warp(x, y)
    bottom = ellipse_sdf(x, y, 0.47, 0.64, 0.38, 0.27)
    top = ellipse_sdf(x, y, 0.44, 0.37, 0.29, 0.25)
    # gathered neck at the very top
    neck = ellipse_sdf(x, y, 0.45, 0.23, 0.11, 0.05)
    return smin(smin(bottom, top, 0.09), neck, 0.06)


def flap_sdf(x, y):
    wx, wy = warp(x, y)
    # wide flap folded over the front, its lower lip bulging down past the middle
    shape = smin(ellipse_sdf(wx, wy, 0.43, 0.38, 0.33, 0.2), ellipse_sdf(wx, wy, 0.42, 0.53, 0.22, 0.09), 0.05)
    return max(shape, body_sdf(x, y) + 0.01)


def strap_sdf(x, y):
    ring = abs(ellipse_sdf(x, y, 0.74, 0.58, 0.15, 0.3)) - 0.017
    return max(ring, 0.7 - x)


def clasp_sdf(x, y):
    return ellipse_sdf(x, y, 0.33, 0.4, 0.034, 0.03)


def shade_leather(x, y, d, base, light_center):
    lx, ly = light_center
    dist = math.hypot(x - lx, y - ly)
    light = 1.3 - dist * 1.75
    rim = smoothstep(0.0, -0.11, d)
    light *= 0.35 + 0.65 * rim
    g = grain(x, y)
    light *= 0.82 + 0.36 * g
    # creases: thin dark streaks from stretched noise
    crease = value_noise(x * 26, y * 6)
    light *= 1.0 - 0.16 * smoothstep(0.64, 0.82, crease)
    color = mix(LEATHER_DARK, base, clamp(light))
    spec = max(0.0, 1.0 - dist * 4.2) ** 3 * 0.38
    return tuple(clamp(c + spec) for c in color)


def sample(x, y):
    """Returns (r, g, b, a) for a point in 0..1 space."""
    layers = []

    sh = ellipse_sdf(x, y, 0.49, 0.93, 0.33, 0.055)
    shadow_a = smoothstep(0.05, -0.04, sh) * 0.5
    if shadow_a > 0:
        layers.append(((0, 0, 0), shadow_a))

    sd = strap_sdf(x, y)
    if sd < 0.01:
        a = smoothstep(0.004, -0.004, sd)
        t = clamp(0.35 + (y - 0.5) * 1.4)
        col = mix((0.6, 0.31, 0.13), LEATHER_DARK, t)
        col = mix(col, OUTLINE, smoothstep(-0.008, 0.0, sd))
        layers.append((col, a))

    bd = body_sdf(x, y)
    if bd < 0.01:
        a = smoothstep(0.004, -0.004, bd)
        col = shade_leather(x, y, bd, LEATHER, (0.3, 0.45))
        fold = math.sin((x * 2.0 + 0.1 * math.sin(y * 8)) * math.tau * 2.6)
        fold_strength = smoothstep(0.55, 0.7, y) * smoothstep(0.95, 0.78, y)
        col = mix(col, LEATHER_DARK, clamp(fold * 0.5 + 0.5) ** 3 * 0.45 * fold_strength)
        col = mix(col, OUTLINE, smoothstep(-0.016, 0.0, bd))
        layers.append((col, a))

    fd = flap_sdf(x, y)
    if fd < 0.01:
        a = smoothstep(0.004, -0.004, fd)
        col = shade_leather(x, y, fd, (0.86, 0.5, 0.22), (0.27, 0.28))
        # the flap's edge is rolled: a light lip just inside the dark outline
        col = mix(col, (0.86, 0.56, 0.3), smoothstep(-0.035, -0.02, fd) * (1 - smoothstep(-0.02, -0.012, fd)) * 0.6)
        col = mix(col, OUTLINE, smoothstep(-0.016, 0.0, fd))
        layers.append((col, a))
    elif bd < 0 and fd < 0.06:
        # the flap casts a soft shadow on the body below it
        layers.append((OUTLINE, smoothstep(0.07, 0.0, fd) * 0.7))

    cd = clasp_sdf(x, y)
    if cd < 0.01:
        a = smoothstep(0.004, -0.004, cd)
        h = math.hypot(x - 0.322, y - 0.39)
        col = mix((1.0, 1.0, 0.95), (0.5, 0.46, 0.4), clamp(h * 22))
        col = mix(col, (0.1, 0.08, 0.06), smoothstep(-0.006, 0.0, cd))
        layers.append((col, a))

    r = g = b = 0.0
    alpha = 0.0
    for col, a in layers:
        r = col[0] * a + r * (1 - a)
        g = col[1] * a + g * (1 - a)
        b = col[2] * a + b * (1 - a)
        alpha = a + alpha * (1 - a)
    if alpha > 0:
        return (r / alpha, g / alpha, b / alpha, alpha)
    return (0, 0, 0, 0)


def render(size):
    rows = []
    for py in range(size):
        row = bytearray([0])  # PNG filter type 0
        for px in range(size):
            acc = [0.0, 0.0, 0.0, 0.0]
            for sy in range(SS):
                for sx in range(SS):
                    x = (px + (sx + 0.5) / SS) / size
                    y = (py + (sy + 0.5) / SS) / size
                    r, g, b, a = sample(x, y)
                    acc[0] += r * a
                    acc[1] += g * a
                    acc[2] += b * a
                    acc[3] += a
            n = SS * SS
            a = acc[3] / n
            if a > 0:
                rgb = [clamp(acc[i] / acc[3]) for i in range(3)]
            else:
                rgb = [0, 0, 0]
            row += bytes([int(rgb[0] * 255 + 0.5), int(rgb[1] * 255 + 0.5), int(rgb[2] * 255 + 0.5), int(a * 255 + 0.5)])
        rows.append(bytes(row))
    return b"".join(rows)


def write_png(path, size, raw):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    write_png(sys.argv[1], SIZE, render(SIZE))
    print("wrote", sys.argv[1], SIZE)
