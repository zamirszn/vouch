#!/usr/bin/env python3
"""Generate Vouch brand assets (icons, splash, notification silhouette)."""
import math
import os
from PIL import Image, ImageDraw, ImageChops

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "brand")
os.makedirs(OUT, exist_ok=True)

INDIGO = (91, 75, 255, 255)       # #5B4BFF
INDIGO_DEEP = (36, 23, 101, 255)  # #241765
INDIGO_DARK = (28, 18, 71, 255)   # #1C1247
INDIGO_MID = (54, 40, 160, 255)   # gradient centre
CORAL = (255, 106, 85, 255)       # #FF6A55
CREAM = (255, 248, 242, 255)      # #FFF8F2


def rounded_polygon(cx, cy, radius, sides, rot, corner_radius, samples=28):
    verts = []
    for i in range(sides):
        a = rot + 2 * math.pi * i / sides
        verts.append((cx + radius * math.cos(a), cy + radius * math.sin(a)))
    pts = []
    n = len(verts)
    for i in range(n):
        px, py = verts[(i - 1) % n]
        x, y = verts[i]
        nx, ny = verts[(i + 1) % n]
        v1 = (px - x, py - y)
        v2 = (nx - x, ny - y)
        l1 = math.hypot(*v1)
        l2 = math.hypot(*v2)
        r = min(corner_radius, l1 / 2, l2 / 2)
        ax, ay = x + v1[0] / l1 * r, y + v1[1] / l1 * r
        bx, by = x + v2[0] / l2 * r, y + v2[1] / l2 * r
        for s in range(samples):
            t = s / samples
            mt = 1 - t
            pts.append((
                mt * mt * ax + 2 * mt * t * x + t * t * bx,
                mt * mt * ay + 2 * mt * t * y + t * t * by,
            ))
    return pts


def cookie_points(cx, cy, radius):
    # A soft, seven-lobed M3 cookie silhouette; slightly turned for character.
    return rounded_polygon(cx, cy, radius, 7, -math.pi / 2 - 0.22, radius * 0.24)


def draw_check(draw, cx, cy, scale, color):
    w = max(2, int(92 * scale))
    p = [
        (cx - 132 * scale, cy + 6 * scale),
        (cx - 32 * scale, cy + 104 * scale),
        (cx + 166 * scale, cy - 106 * scale),
    ]
    draw.line(p, fill=color, width=w, joint="curve")
    r = w / 2
    for x, y in (p[0], p[-1]):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def gradient_background(n):
    img = Image.new("RGBA", (n, n))
    px = img.load()
    cx, cy = n * 0.35, n * 0.26
    maxd = math.hypot(n, n)
    for y in range(n):
        for x in range(n):
            d = min(1.0, math.hypot(x - cx, y - cy) / maxd * 1.2)
            col = tuple(
                int(INDIGO_MID[i] + (INDIGO_DARK[i] - INDIGO_MID[i]) * d)
                for i in range(3)
            )
            px[x, y] = (*col, 255)
    return img


def emblem(canvas, cx, cy, fraction, accent=True, check=True):
    """Draw the cookie mark on a transparent canvas at a 1024-design scale."""
    n = canvas.size[0]
    factor = n / 1024.0
    draw = ImageDraw.Draw(canvas)
    radius = 360 * fraction * factor
    if accent:
        draw.ellipse(
            [cx + radius * 0.16, cy - radius * 1.02,
             cx + radius * 0.86, cy - radius * 0.32],
            fill=CORAL,
        )
    draw.polygon(cookie_points(cx, cy, radius), fill=CREAM)
    if check:
        draw_check(draw, cx, cy, fraction * factor * 0.82, INDIGO_DEEP)
    return canvas


def icon(size=1024):
    S = 2
    n = size * S
    img = gradient_background(n)
    emblem(img, n * 0.5, n * 0.535, 1.0)
    return img.resize((size, size), Image.LANCZOS)


def foreground(size=1024):
    n = size * 2
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    emblem(img, n * 0.5, n * 0.5, 0.72)
    return img.resize((size, size), Image.LANCZOS)


def monochrome(size=1024):
    n = size * 2
    mask = Image.new("L", (n, n), 0)
    md = ImageDraw.Draw(mask)
    cx, cy = n * 0.5, n * 0.5
    md.polygon(cookie_points(cx, cy, 360 * 0.72 * n / 1024), fill=255)
    cut = Image.new("L", (n, n), 0)
    cd = ImageDraw.Draw(cut)
    w = int(92 * 0.72 * n / 1024)
    p = [
        (cx - 132 * 0.72 * n / 1024, cy + 6 * 0.72 * n / 1024),
        (cx - 32 * 0.72 * n / 1024, cy + 104 * 0.72 * n / 1024),
        (cx + 166 * 0.72 * n / 1024, cy - 106 * 0.72 * n / 1024),
    ]
    cd.line(p, fill=255, width=w, joint="curve")
    for x, y in (p[0], p[-1]):
        cd.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=255)
    alpha = ImageChops.subtract(mask, cut)
    img = Image.new("RGBA", (n, n), (255, 255, 255, 255))
    img.putalpha(alpha)
    return img.resize((size, size), Image.LANCZOS)


def splash(size=1024):
    n = size * 2
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    emblem(img, n * 0.5, n * 0.5, 0.78)
    return img.resize((size, size), Image.LANCZOS)


def notification(size=96):
    n = size * 4
    mask = Image.new("L", (n, n), 0)
    md = ImageDraw.Draw(mask)
    cx, cy = n * 0.5, n * 0.5
    radius = 360 * 0.74 * n / 1024
    md.polygon(cookie_points(cx, cy, radius), fill=255)
    cut = Image.new("L", (n, n), 0)
    cd = ImageDraw.Draw(cut)
    s = 0.74 * n / 1024
    w = int(92 * s)
    p = [
        (cx - 132 * s, cy + 6 * s),
        (cx - 32 * s, cy + 104 * s),
        (cx + 166 * s, cy - 106 * s),
    ]
    cd.line(p, fill=255, width=w, joint="curve")
    for x, y in (p[0], p[-1]):
        cd.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=255)
    alpha = ImageChops.subtract(mask, cut)
    img = Image.new("RGBA", (n, n), (255, 255, 255, 255))
    img.putalpha(alpha)
    return img.resize((size, size), Image.LANCZOS)


def mark(size=512):
    n = size * 2
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    emblem(img, n * 0.5, n * 0.52, 0.78)
    return img.resize((size, size), Image.LANCZOS)


icon().save(os.path.join(OUT, "icon.png"))
foreground().save(os.path.join(OUT, "icon_foreground.png"))
monochrome().save(os.path.join(OUT, "icon_monochrome.png"))
splash().save(os.path.join(OUT, "splash_logo.png"))
notification().save(os.path.join(OUT, "notification_icon.png"))
mark().save(os.path.join(OUT, "mark.png"))
print("wrote brand assets to", os.path.abspath(OUT))
