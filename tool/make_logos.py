"""Draws every logo the app ships, from the pen face it already bundles.

    python tool/make_logos.py

The identity is the whole word, handwritten: "notsince" on one line where
there is room (launch screen, store banner), and stacked as "not / since"
inside the square app icon. Outlines wobble the way the in-app sketch
renderer's do, from a fixed seed, so a re-run reproduces the same files.

Needs Pillow. Colours mirror AppColors / android values/colors.xml.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets/fonts/NanumPenScript-400.ttf"
BODY = ROOT / "assets/fonts/Quicksand-500.ttf"

PAPER = (250, 247, 240)
DARK_INK = (243, 237, 227)
DARK_GREEN = (134, 184, 72)
TINT = (234, 243, 222)
INK = (48, 44, 39)
GREEN = (99, 153, 34)
SHADE = (48, 44, 39, 70)

SS = 4  # supersampling: draw big, shrink with a good filter


# ── wobble ────────────────────────────────────────────────────────────────


def _noise(rng: random.Random, n: int, knots: int) -> list[float]:
    """Smooth, looping, low-frequency noise in -1..1."""
    ks = [rng.uniform(-1, 1) for _ in range(knots)]
    out = []
    for i in range(n):
        t = i / n * knots
        a, f = int(t) % knots, t - int(t)
        f = f * f * (3 - 2 * f)
        out.append(ks[a] * (1 - f) + ks[(a + 1) % knots] * f)
    return out


def _rrect_points(x0, y0, x1, y1, r, step=6.0):
    pts = []
    corners = [
        (x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0),
        (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180),
    ]
    for cx, cy, a0 in corners:
        n = max(6, int(r * math.pi / 2 / step))
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        # straight run to the next corner is filled in by resampling below
    dense = []
    for i, p in enumerate(pts):
        q = pts[(i + 1) % len(pts)]
        d = math.dist(p, q)
        k = max(1, int(d / step))
        for j in range(k):
            dense.append((p[0] + (q[0] - p[0]) * j / k, p[1] + (q[1] - p[1]) * j / k))
    return dense


def wobbly_rrect(box, r, amount, seed):
    x0, y0, x1, y1 = box
    pts = _rrect_points(x0, y0, x1, y1, r)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    noise = _noise(random.Random(seed), len(pts), 9)
    out = []
    for (x, y), n in zip(pts, noise):
        d = math.hypot(x - cx, y - cy) or 1
        out.append((x + (x - cx) / d * n * amount, y + (y - cy) / d * n * amount))
    return out


def pen_outline(draw, box, r, width, amount, seed):
    """Two passes that do not quite agree, like a line gone over twice."""
    for i, alpha in enumerate((255, 120)):
        pts = wobbly_rrect(box, r, amount, seed + i * 17)
        w = width if i == 0 else max(1, int(width * .4))
        draw.line(pts + pts[:2], fill=INK + (alpha,), width=w, joint="curve")


def scribble(draw, x0, x1, y, width, seed, color=GREEN):
    """A quick underline: one confident stroke and a lighter return stroke."""
    rng = random.Random(seed)
    span = x1 - x0
    for k, (alpha, dy) in enumerate(((255, 0), (170, width * .9))):
        n = 40
        noise = _noise(rng, n + 1, 4)
        pts = []
        for i in range(n + 1):
            t = i / n
            if k:
                t = 1 - t * .82
            pts.append((
                x0 + span * t,
                y + dy - span * .025 * t + noise[i] * width * .7
                + math.sin(t * math.pi) * width * .5,
            ))
        w = int(width if k == 0 else width * .7)
        draw.line(pts, fill=color + (alpha,), width=w, joint="curve")
        for p in (pts[0], pts[-1]):
            draw.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2],
                         fill=color + (alpha,))


def hatch(img, box, r, gap, width, seed):
    """Pencil hatching clipped to a rounded tile: the tile's shadow."""
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(wobbly_rrect(box, r, 0, seed), fill=255)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    x0, y0, x1, y1 = box
    h = y1 - y0
    x = x0 - h
    while x < x1:
        j = rng.uniform(-gap * .15, gap * .15)
        d.line([(x + j, y1), (x + h + j, y0)], fill=SHADE, width=width)
        x += gap
    img.paste(layer, (0, 0), Image.composite(layer, Image.new("RGBA", img.size), mask))


# ── lettering ─────────────────────────────────────────────────────────────


def font(size):
    return ImageFont.truetype(str(FONT), int(size))


def text_size(text, f, stroke=0):
    l, t, r, b = f.getbbox(text, stroke_width=stroke)
    return l, t, r - l, b - t


def draw_centered(draw, text, cx, cy, f, fill, stroke=0):
    l, t, w, h = text_size(text, f, stroke)
    draw.text((cx - w / 2 - l, cy - h / 2 - t), text, font=f, fill=fill,
              stroke_width=stroke, stroke_fill=fill)
    return w, h


def fit_font(text, width, stroke_ratio=0.0):
    size = 10
    while True:
        f = font(size + 2)
        if text_size(text, f, int(size * stroke_ratio))[2] > width:
            return font(size), int(size * stroke_ratio)
        size += 2


# ── the marks ─────────────────────────────────────────────────────────────


def stacked(draw, cx, cy, width, color=INK, underline=GREEN, weight=.022):
    """"not" over "since", sharing a left edge, with a scribble under it."""
    f, stroke = fit_font("since", width, weight)
    _, _, w2, h2 = text_size("since", f, stroke)
    l1, t1, w1, h1 = text_size("not", f, stroke)
    lead = f.size * .64
    top = cy - (lead + h2) / 2 - f.size * .06
    left = cx - w2 / 2
    l2, t2, _, _ = text_size("since", f, stroke)
    draw.text((left - l1 + w2 * .02, top - t1), "not", font=f, fill=color,
              stroke_width=stroke, stroke_fill=color)
    draw.text((left - l2, top + lead - t2 + (h1 - h2) * 0), "since", font=f,
              fill=color, stroke_width=stroke, stroke_fill=color)
    if underline:
        y = top + lead + h2 + f.size * .13
        scribble(draw, left + w2 * .02, left + w2 * 1.0, y, max(2, f.size * .075),
                 7, underline)


def wordmark(height_px, color=INK, underline=GREEN, pad=.18):
    """"notsince" on one line with its underline, on transparency."""
    S = SS
    f = font(height_px * S * .86)
    stroke = int(f.size * .012)
    l, t, w, h = text_size("notsince", f, stroke)
    px = int(f.size * pad)
    W, H = w + px * 2, int(height_px * S)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y0 = (H - h) / 2 - f.size * .07
    d.text((px - l, y0 - t), "notsince", font=f, fill=color,
           stroke_width=stroke, stroke_fill=color)
    scribble(d, px + w * .02, px + w * .99, y0 + h + f.size * .12,
             max(2, f.size * .06), 7, underline)
    return img.resize((round(W / S), round(H / S)), Image.LANCZOS)


def tile(size, *, rounded=True, bleed=False):
    """The square icon. `bleed` fills edge to edge for launchers that mask."""
    S = SS
    n = size * S
    img = Image.new("RGBA", (n, n), TINT + (255,) if bleed else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if not bleed:
        m, lift = n * .05, n * .045
        box = (m, m, n - m - lift, n - m - lift)
        r = n * .2
        shadow = (box[0] + lift, box[1] + lift, box[2] + lift, box[3] + lift)
        hatch(img, shadow, r, n * .035, max(1, int(n * .009)), 3)
        d = ImageDraw.Draw(img)
        d.polygon(wobbly_rrect(box, r, n * .006, 5), fill=TINT + (255,))
        pen_outline(d, box, r, max(2, int(n * .022)), n * .006, 5)
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        stacked(d, cx, cy, (box[2] - box[0]) * .68)
    else:
        stacked(d, n / 2, n / 2, n * .6)
    return img.resize((size, size), Image.LANCZOS)


def foreground(size):
    """Adaptive-icon layer: only the lettering, inside the 66/108 safe zone."""
    n = size * SS
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    stacked(ImageDraw.Draw(img), n / 2, n / 2, n * .46, weight=.02)
    return img.resize((size, size), Image.LANCZOS)


def feature_graphic():
    S = 2
    W, H = 1024 * S, 500 * S
    img = Image.new("RGBA", (W, H), PAPER + (255,))
    d = ImageDraw.Draw(img)
    pitch = 22 * S
    for y in range(pitch, H, pitch):
        for x in range(pitch, W, pitch):
            d.ellipse([x - S, y - S, x + S, y + S], fill=(48, 44, 39, 26))
    icon = tile(300 * S // 1)
    img.alpha_composite(icon.resize((300 * S, 300 * S), Image.LANCZOS),
                        (96 * S, 100 * S))
    mark = wordmark(150 * S)
    img.alpha_composite(mark, (452 * S, 118 * S))
    f = font(50 * S)
    d = ImageDraw.Draw(img)
    d.text((470 * S, 296 * S), "Small care. Beautiful growth.", font=f,
           fill=INK + (215,))
    return img.resize((1024, 500), Image.LANCZOS).convert("RGB")


def save(img, path):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print("wrote", path.relative_to(ROOT))


def main():
    res = "android/app/src/main/res"
    for name, scale in (("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
                        ("xxhdpi", 3), ("xxxhdpi", 4)):
        save(tile(round(48 * scale)), f"{res}/mipmap-{name}/ic_launcher.png")
        save(foreground(round(108 * scale)),
             f"{res}/mipmap-{name}/ic_launcher_foreground.png")
        # The launch screen: the word itself, 72dp tall.
        save(wordmark(round(72 * scale)), f"{res}/drawable-{name}/splash_logo.png")
        save(wordmark(round(72 * scale), DARK_INK, DARK_GREEN),
             f"{res}/drawable-night-{name}/splash_logo.png")

    ios = "ios/Runner/Assets.xcassets"
    for pt, scales in ((20, (1, 2, 3)), (29, (1, 2, 3)), (40, (1, 2, 3)),
                       (60, (2, 3)), (76, (1, 2)), (83.5, (2,)), (1024, (1,))):
        for s in scales:
            label = f"{pt:g}x{pt:g}@{s}x"
            # App Store icons may not carry an alpha channel.
            save(tile(round(pt * s), bleed=True).convert("RGB"),
                 f"{ios}/AppIcon.appiconset/Icon-App-{label}.png")
    for s, suffix in ((1, ""), (2, "@2x"), (3, "@3x")):
        save(wordmark(72 * s), f"{ios}/LaunchImage.imageset/LaunchImage{suffix}.png")

    save(tile(512), "store/play_icon_512.png")
    save(feature_graphic(), "store/play_feature_graphic_1024x500.png")


if __name__ == "__main__":
    main()
