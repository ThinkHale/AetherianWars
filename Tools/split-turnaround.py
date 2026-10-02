"""Split a hero turnaround sheet into square front/back/side views for image-to-3D.

usage: split-turnaround.py <sheet.png> <out_dir> [hero_id]
Finds the three figures automatically; heroes listed in turnaround-crops.json use the manual boxes there.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

src, out = sys.argv[1], sys.argv[2]
hero = sys.argv[3] if len(sys.argv) > 3 else None
img = Image.open(src).convert("RGB")
im = np.asarray(img).astype(int)
H, W, _ = im.shape
# Sheets have a vertical grey gradient, so compare each row to its own edge colour.
rowbg = np.median(np.concatenate([im[:, :30], im[:, -30:]], 1), axis=1)
bg = tuple(int(v) for v in np.median(rowbg, axis=0))

overrides = json.load(open(os.path.join(os.path.dirname(__file__), "turnaround-crops.json")))
if hero in overrides:
    o = overrides[hero]
    d = ImageDraw.Draw(img)
    for x0, y0, x1, y1 in o.get("masks", []):
        for y in range(y0, y1):
            d.line([(x0, y), (x1, y)], fill=tuple(int(v) for v in rowbg[y]))
    boxes = [o["front"], o["back"], o["side"]]
else:
    diff = np.abs(im - rowbg[:, None, :]).sum(2) > 45
    rows = diff.mean(1)
    # Figures occupy the top band; stop at the first clear gap above the labels.
    top = np.argmax(rows > 0.01)
    bottom = top
    for y in range(top, H):
        if rows[y] > 0.01: bottom = y
        elif y - bottom > 3: break
    cols = diff[top:bottom + 1].mean(0) > 0.004
    segs, start = [], None
    for x, c in enumerate(list(cols) + [False]):
        if c and start is None: start = x
        if not c and start is not None:
            if x - start > 60: segs.append((start, x))
            start = None
    if len(segs) != 3:
        sys.exit(f"{src}: found {len(segs)} figures, add a manual entry to turnaround-crops.json")
    pad = 24
    boxes = [(max(a - pad, 0), max(top - pad, 0), min(b + pad, W), min(bottom + 6, H)) for a, b in segs]

for name, box in zip(["front", "back", "side"], boxes):
    crop = img.crop(tuple(box))
    s = int(max(crop.size) * 1.05)
    canvas = Image.new("RGB", (s, s), bg)
    canvas.paste(crop, ((s - crop.size[0]) // 2, (s - crop.size[1]) // 2))
    canvas.resize((1024, 1024), Image.LANCZOS).save(os.path.join(out, f"{name}.png"))
print(hero or src, "ok")
