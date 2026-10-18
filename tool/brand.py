#!/usr/bin/env python3
"""Generate Vouch brand assets (icons, splash, notification silhouette).

The mark is deliberately simple: one bold cream check on an indigo gradient,
with a single coral dot as the witness. It reads cleanly down to 24 px.
"""
import math
import os
from PIL import Image, ImageDraw, ImageChops, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "brand")
os.makedirs(OUT, exist_ok=True)

INDIGO = (91, 75, 255, 255)        # #5B4BFF
INDIGO_LIFT = (124, 108, 255, 255)  # glow
INDIGO_DEEP = (36, 23, 101, 255)   # #241765
CORAL = (255, 106, 85, 255)        # #FF6A55
CREAM = (255, 248, 242, 255)       # #FFF8F2
WHITE = (255, 255, 255, 255)

# Check geometry in a 1024 px design box, centred on (0, 0).
CHECK = ((-300.0, 40.0), (-70.0, 225.0), (270.0, -160.0))
CHECK_WEIGHT = 128.0
DOT_CENTER = (170.0, -268.0)
DOT_RADIUS = 52.0


def _check(draw, cx, cy, scale, color, weight_scale=1.0):
    pts = [(cx + x * scale, cy + y * scale) for x, y in CHECK]
    w = max(2, int(CHECK_WEIGHT * scale * weight_scale))
    draw.line(pts, fill=color, width=w, joint="curve")
    r = w / 2
    for x, y in pts:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def _dot(draw, cx, cy, scale, color, radius_scale=1.0):
    r = DOT_RADIUS * scale * radius_scale
    x = cx + DOT_CENTER[0] * scale
    y = cy + DOT_CENTER[1] * scale
    draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def _backdrop(n):
    """Indigo tile with a soft top-left glow."""
    img = Image.new("RGBA", (n, n))
    px = img.load()
    cx, cy = n * 0.24, n * 0.18
    maxd = math.hypot(n, n) * 0.82
    for y in range(n):
        for x in range(n):
            d = min(1.0, math.hypot(x - cx, y - cy) / maxd)
            d = d * d * (3 - 2 * d)  # smoothstep
            col = tuple(
                int(INDIGO_LIFT[i] + (INDIGO_DEEP[i] - INDIGO_LIFT[i]) * d)
                for i in range(3)
            )
            px[x, y] = (*col, 255)
    return img


def icon(size=1024):
    s = 2
    n = size * s
    img = _backdrop(n)
    draw = ImageDraw.Draw(img)
    scale = n / 1024.0
    _check(draw, n * 0.5, n * 0.5, scale, CREAM)
    _dot(draw, n * 0.5, n * 0.5, scale, CORAL)
    return img.resize((size, size), Image.LANCZOS)


def foreground(size=1024):
    """Adaptive-icon foreground: safe inside a 66% circular mask."""
    s = 2
    n = size * s
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = 0.78 * n / 1024.0
    _check(draw, n * 0.5, n * 0.5, scale, CREAM)
    _dot(draw, n * 0.5, n * 0.5, scale, CORAL)
    return img.resize((size, size), Image.LANCZOS)


def _silhouette(size, scale_fraction):
    """White check + dot mask on a transparent canvas."""
    s = 4
    n = size * s
    mask = Image.new("L", (n, n), 0)
    draw = ImageDraw.Draw(mask)
    scale = scale_fraction * n / 1024.0
    _check(draw, n * 0.5, n * 0.5, scale, 255)
    _dot(draw, n * 0.5, n * 0.5, scale, 255)
    img = Image.new("RGBA", (n, n), (255, 255, 255, 255))
    img.putalpha(mask)
    return img.resize((size, size), Image.LANCZOS)


def monochrome(size=1024):
    return _silhouette(size, 0.78)


def notification(size=96):
    return _silhouette(size, 0.86)


def splash(size=1024):
    s = 4
    n = size * s
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = 0.84 * n / 1024.0
    _check(draw, n * 0.5, n * 0.5, scale, CREAM)
    _dot(draw, n * 0.5, n * 0.5, scale, CORAL)
    return img.resize((size, size), Image.LANCZOS)


def mark(size=512):
    s = 4
    n = size * s
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = 0.84 * n / 1024.0
    _check(draw, n * 0.5, n * 0.5, scale, CREAM)
    _dot(draw, n * 0.5, n * 0.5, scale, CORAL)
    return img.resize((size, size), Image.LANCZOS)


icon().save(os.path.join(OUT, "icon.png"))
foreground().save(os.path.join(OUT, "icon_foreground.png"))
monochrome().save(os.path.join(OUT, "icon_monochrome.png"))
splash().save(os.path.join(OUT, "splash_logo.png"))
notification().save(os.path.join(OUT, "notification_icon.png"))
mark().save(os.path.join(OUT, "mark.png"))
print("wrote brand assets to", os.path.abspath(OUT))
