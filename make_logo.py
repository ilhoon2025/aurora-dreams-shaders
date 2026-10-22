"""Render the Aurora Dreams icon (assets/logo.png, 512x512)."""
import numpy as np, random, pathlib
from PIL import Image, ImageDraw, ImageFilter

S = 512
rng = random.Random(7)
out = pathlib.Path(__file__).parent / "assets"; out.mkdir(exist_ok=True)

# --- night sky gradient
y = np.linspace(0, 1, S)[:, None]
top, mid, bot = np.array([6, 8, 30]), np.array([22, 20, 70]), np.array([18, 70, 100])
t = np.clip(y * 1.25, 0, 1)
sky = np.where(t < 0.55, top + (mid - top) * (t / 0.55), mid + (bot - mid) * ((t - 0.55) / 0.45))
img = np.repeat(sky[:, None, :], S, axis=1).reshape(S, S, 3).astype(float)

# --- aurora curtains
xs, ys = np.meshgrid(np.arange(S), np.arange(S))
def curtain(base, amp, ph, height, c_low, c_high, gain):
    wave = base + amp * np.sin(xs * 0.012 + ph) + amp * 0.55 * np.sin(xs * 0.031 + ph * 2.1) + 10 * np.sin(xs * 0.07 + ph * 3)
    d = wave - ys
    prof = np.where(d > 0, np.exp(-d / height), 0) * np.clip(d / 6.0, 0, 1)
    rays = 0.65 + 0.35 * np.sin(xs * 0.42 + np.sin(xs * 0.05 + ph) * 3.0)
    k = np.clip(d / (height * 2.6), 0, 1)[..., None]
    col = np.array(c_low) * (1 - k) + np.array(c_high) * k
    return col * (prof * rays * gain)[..., None]
glow = (curtain(250, 34, 0.4, 95, (40, 255, 150), (120, 70, 255), 1.0) +
        curtain(215, 26, 2.2, 70, (60, 230, 255), (200, 80, 255), 0.7))
glow = np.array(Image.fromarray(np.clip(glow, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3.0))).astype(float)
img = 255 - (255 - img) * (255 - np.clip(glow, 0, 255)) / 255          # screen blend
base = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert("RGBA")

# --- stars
d = ImageDraw.Draw(base)
for _ in range(130):
    x, yy = rng.randrange(S), rng.randrange(0, 250)
    b = rng.randrange(150, 255)
    r = 1 if rng.random() < 0.85 else 2
    d.ellipse([x - r, yy - r, x + r, yy + r], fill=(b, b, 255, rng.randrange(120, 255)))
for sx, sy in ((90, 70), (400, 120), (320, 40)):          # a few sparkles
    d.line([sx - 7, sy, sx + 7, sy], fill=(255, 255, 255, 230), width=1)
    d.line([sx, sy - 7, sx, sy + 7], fill=(255, 255, 255, 230), width=1)

# --- crescent moon with glow
moon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
md = ImageDraw.Draw(moon)
cx, cy, R = 372, 118, 44
md.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(255, 246, 215, 255))
md.ellipse([cx - R + 24, cy - R - 8, cx + R + 24, cy + R - 8], fill=(0, 0, 0, 0))
moon = Image.composite(moon, Image.new("RGBA", (S, S), (0, 0, 0, 0)), moon.split()[3])
halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse([cx - 80, cy - 80, cx + 80, cy + 80], fill=(180, 200, 255, 90))
halo = halo.filter(ImageFilter.GaussianBlur(26))
base = Image.alpha_composite(Image.alpha_composite(base, halo), moon)

# --- blocky mountains + pines (16 px voxels)
CELL = 16
def ridge(seed, lo, hi):
    r = random.Random(seed); h = []; v = (lo + hi) / 2
    for _ in range(S // CELL):
        v = min(hi, max(lo, v + r.choice((-2, -1, 0, 0, 1, 2))))
        h.append(v)
    return h
layers = [(ridge(3, 7, 12), (20, 40, 78), (46, 86, 140)), (ridge(11, 4, 8), (10, 20, 44), (28, 52, 96))]
top_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0)); td = ImageDraw.Draw(top_layer)
for heights, body, edge in layers:
    for i, hgt in enumerate(heights):
        y0 = S - hgt * CELL
        td.rectangle([i * CELL, y0, i * CELL + CELL - 1, S], fill=body + (255,))
        td.rectangle([i * CELL, y0, i * CELL + CELL - 1, y0 + 3], fill=edge + (255,))
# pixel pines on the front ridge
front = layers[1][0]
for i in (2, 3, 5, 24, 27, 29):
    px, base_y = i * CELL, S - front[i] * CELL
    for row, w in enumerate((1, 2, 3, 3)):
        td.rectangle([px + 8 - w * 4 - 0, base_y - (row + 1) * 8, px + 8 + w * 4 - 1, base_y - row * 8],
                     fill=(6, 26, 40, 255))
    td.rectangle([px + 6, base_y, px + 9, base_y + 4], fill=(6, 26, 40, 255))
base = Image.alpha_composite(base, top_layer)

# --- reflected aurora shimmer on the foreground
shim = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sd = ImageDraw.Draw(shim)
for i in range(26):
    x = rng.randrange(0, S); yy = rng.randrange(440, 505); w = rng.randrange(14, 46)
    sd.rectangle([x, yy, x + w, yy + 2], fill=(90, 255, 200, rng.randrange(40, 110)))
base = Image.alpha_composite(base, shim)

# --- rounded corners + thin rim
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=96, fill=255)
final = Image.new("RGBA", (S, S), (0, 0, 0, 0)); final.paste(base, (0, 0), mask)
ImageDraw.Draw(final).rounded_rectangle([1, 1, S - 2, S - 2], radius=95, outline=(160, 220, 255, 90), width=2)
final.save(out / "logo.png", optimize=True)
final.resize((256, 256), Image.LANCZOS).save(out / "logo_256.png", optimize=True)
print(out / "logo.png")
