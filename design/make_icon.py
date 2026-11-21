"""Builds the AssureSky app icons: a smiling fluffy cloud (eyes + big smile, no
arms or legs) on the pastel sky background in design/icon_background.png.

Run from the project root:  python design/make_icon.py
Needs Pillow.
"""
import json
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG_PATH = os.path.join(ROOT, 'design', 'icon_background.png')
S = 1024  # design canvas for the cloud
OUTLINE = (120, 170, 220, 255)
INK = (43, 58, 85, 255)
MOUTH = (122, 46, 62, 255)
TONGUE = (255, 143, 163, 255)


def bezier(p0, p1, p2, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def cloud_mask():
    m = Image.new('L', (S * 2, S * 2), 0)
    d = ImageDraw.Draw(m)
    cx, cy = S, S + 20  # centre in the 2x canvas
    d.ellipse([cx - 280, cy - 150, cx + 280, cy + 170], fill=255)
    n = 12
    for i in range(n):
        a = i * 2 * math.pi / n + 0.2
        r = 112 if i % 2 == 0 else 92
        x = cx + math.cos(a) * 262
        y = cy + math.sin(a) * 150
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    return m


def make_cloud():
    """Returns the cloud with its face as an RGBA image (tight crop)."""
    mask = cloud_mask()
    W = mask.size[0]
    cx, cy = W // 2, W // 2 + 20

    # soft shadow
    shadow = Image.new('RGBA', mask.size, (0, 0, 0, 0))
    sh_mask = mask.filter(ImageFilter.GaussianBlur(22))
    shadow.paste((70, 90, 160, 90), (0, 22), sh_mask)

    # body: vertical white -> pale blue gradient
    grad = Image.new('RGBA', mask.size)
    gd = ImageDraw.Draw(grad)
    top, bot = cy - 330, cy + 320
    for y in range(W):
        t = min(1, max(0, (y - top) / (bot - top)))
        c = (int(255 - 40 * t), int(255 - 22 * t), 255, 255)
        gd.line([(0, y), (W, y)], fill=c)
    body = Image.new('RGBA', mask.size, (0, 0, 0, 0))
    body.paste(grad, (0, 0), mask)

    # outline
    grown = mask.filter(ImageFilter.MaxFilter(15))
    ring = Image.new('L', mask.size, 0)
    ring.paste(grown, (0, 0))
    ring_draw = Image.composite(Image.new('L', mask.size, 0), ring, mask)
    outline = Image.new('RGBA', mask.size, (0, 0, 0, 0))
    outline.paste(OUTLINE, (0, 0), ring_draw)

    img = Image.alpha_composite(shadow, outline)
    img = Image.alpha_composite(img, body)

    d = ImageDraw.Draw(img, 'RGBA')
    # top-left shine
    d.ellipse([cx - 230, cy - 215, cx - 80, cy - 150], fill=(255, 255, 255, 190))

    # cheeks
    for x in (cx - 190, cx + 190):
        d.ellipse([x - 52, cy + 10, x + 52, cy + 62], fill=(255, 150, 175, 150))

    # eyes
    for x in (cx - 105, cx + 105):
        d.ellipse([x - 38, cy - 105, x + 38, cy + 15], fill=INK)
        d.ellipse([x - 24, cy - 92, x + 2, cy - 62], fill=(255, 255, 255, 255))
        d.ellipse([x + 6, cy - 30, x + 22, cy - 12], fill=(255, 255, 255, 255))

    # big open smile
    left, right = (cx - 120, cy + 8), (cx + 120, cy + 8)
    outline_pts = bezier(left, (cx, cy + 250), right)
    mouth_layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mouth_layer)
    md.polygon(outline_pts, fill=MOUTH)
    # tongue clipped to the mouth
    tongue = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(tongue).ellipse(
        [cx - 62, cy + 100, cx + 62, cy + 190], fill=TONGUE)
    mm = Image.new('L', img.size, 0)
    ImageDraw.Draw(mm).polygon(outline_pts, fill=255)
    mouth_layer = Image.alpha_composite(
        mouth_layer, Image.composite(tongue, Image.new('RGBA', img.size, (0, 0, 0, 0)), mm))
    # upper teeth strip
    teeth = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(teeth).rectangle([cx - 100, cy + 8, cx + 100, cy + 44],
                                    fill=(255, 255, 255, 255))
    mouth_layer = Image.alpha_composite(
        mouth_layer, Image.composite(teeth, Image.new('RGBA', img.size, (0, 0, 0, 0)), mm))
    img = Image.alpha_composite(img, mouth_layer)

    bbox = img.getbbox()
    return img.crop(bbox)


CLOUD = make_cloud()


def cloud_at(width):
    h = round(CLOUD.size[1] * width / CLOUD.size[0])
    return CLOUD.resize((max(1, round(width)), max(1, h)), Image.LANCZOS)


def background(size):
    return Image.open(BG_PATH).convert('RGB').resize((size, size), Image.LANCZOS)


def compose(size, cloud_frac, rounded):
    base = background(size).convert('RGBA')
    c = cloud_at(size * cloud_frac)
    base.alpha_composite(c, ((size - c.size[0]) // 2,
                             (size - c.size[1]) // 2 + round(size * 0.01)))
    if rounded:
        k = 4
        mask = Image.new('L', (size * k, size * k), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size * k - 1, size * k - 1], radius=int(size * k * 0.22), fill=255)
        mask = mask.resize((size, size), Image.LANCZOS)
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        out.paste(base, (0, 0), mask)
        return out
    return base


def foreground(size):
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    c = cloud_at(size * 0.56)  # stays inside the adaptive-icon safe zone
    canvas.alpha_composite(c, ((size - c.size[0]) // 2,
                               (size - c.size[1]) // 2 + round(size * 0.01)))
    return canvas


res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
adaptive = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
for dpi, px in legacy.items():
    compose(px * 4, 0.70, True).resize((px, px), Image.LANCZOS).save(
        os.path.join(res, f'mipmap-{dpi}', 'ic_launcher.png'))
for dpi, px in adaptive.items():
    d = os.path.join(res, f'mipmap-{dpi}')
    foreground(px * 2).resize((px, px), Image.LANCZOS).save(
        os.path.join(d, 'ic_launcher_foreground.png'))
    background(px).convert('RGB').save(os.path.join(d, 'ic_launcher_background.png'))

with open(os.path.join(res, 'mipmap-anydpi-v26', 'ic_launcher.xml'), 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')
old = os.path.join(res, 'values', 'ic_launcher_background.xml')
if os.path.exists(old):
    os.remove(old)

ios = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
if os.path.isdir(ios):
    with open(os.path.join(ios, 'Contents.json')) as f:
        data = json.load(f)
    for im in data['images']:
        fn = im.get('filename')
        if not fn:
            continue
        w = round(float(im['size'].split('x')[0]) * int(im['scale'].rstrip('x')))
        compose(w * 2, 0.70, False).convert('RGB').resize((w, w), Image.LANCZOS).save(
            os.path.join(ios, fn))

compose(512, 0.70, True).save(os.path.join(ROOT, 'design', 'icon_preview.png'))
print('ok')
