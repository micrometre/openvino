"""
classify.py  –  Image classification with MobileNetV2 (OpenVINO IR)

Note: MobileNetV2 is a classifier, not an object detector.
      It returns a ranked list of ImageNet class labels for the whole image.
      For bounding-box object detection, use SSD MobileNet instead.

Usage:
    python classify.py [image_path]          # defaults to images/1.jpg
"""

import sys
import numpy as np
import openvino as ov
from PIL import Image

# ── Config ────────────────────────────────────────────────────────────────────
IMAGE_PATH  = sys.argv[1] if len(sys.argv) > 1 else "images/4.jpg"
MODEL_XML   = "mobilenetv2.xml"
INPUT_SIZE  = (224, 224)   # MobileNetV2 expected input
TOP_K       = 5

# ── Load ImageNet class labels ────────────────────────────────────────────────
import urllib.request, json
LABELS_URL = (
    "https://storage.googleapis.com/download.tensorflow.org/"
    "data/imagenet_class_index.json"
)
print("Loading ImageNet labels …")
with urllib.request.urlopen(LABELS_URL) as r:
    raw = json.load(r)
# raw = {"0": ["n01440764", "tench"], ...}
labels = {int(k): v[1] for k, v in raw.items()}

# ── Load & preprocess image ───────────────────────────────────────────────────
orig_img = Image.open(IMAGE_PATH).convert("RGB")          # keep original size
img = orig_img.resize(INPUT_SIZE)
data = np.array(img, dtype=np.float32)

# MobileNetV2 preprocessing: scale pixels to [-1, 1]
data = (data / 127.5) - 1.0
data = np.expand_dims(data, axis=0)          # (1, 224, 224, 3)

# ── Load OpenVINO model ───────────────────────────────────────────────────────
core  = ov.Core()
model = core.read_model(MODEL_XML)
compiled = core.compile_model(model, "GPU")

# ── Run inference ─────────────────────────────────────────────────────────────
output_layer = compiled.output(0)
result = compiled({0: data})[output_layer]   # shape: (1, 1000)
scores = result[0]

# ── Print top-K predictions ───────────────────────────────────────────────────
top_indices = np.argsort(scores)[::-1][:TOP_K]

print(f"\nImage : {IMAGE_PATH}")
print(f"{'Rank':<6} {'Class':<35} {'Score':>8}")
print("-" * 52)
for rank, idx in enumerate(top_indices, 1):
    label = labels.get(idx, f"class_{idx}")
    print(f"{rank:<6} {label:<35} {scores[idx]:>8.4f}")

# ── Annotate & save output image ──────────────────────────────────────────────
from PIL import ImageDraw, ImageFont
import pathlib

draw       = ImageDraw.Draw(orig_img, "RGBA")
pad        = 12
line_h     = 28
panel_w    = 320
panel_h    = pad + (TOP_K + 1) * line_h + pad   # +1 for header row

# Semi-transparent dark panel in the top-left corner
draw.rectangle([(0, 0), (panel_w, panel_h)], fill=(0, 0, 0, 175))

# Try to load a nicer font; fall back to PIL default if not available
try:
    font_bold  = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    font_reg   = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
except OSError:
    font_bold = font_reg = ImageFont.load_default()

# Header
draw.text((pad, pad), "Top predictions (MobileNetV2)", font=font_bold, fill=(255, 215, 0, 255))

# Score bar colours: gold → green gradient
bar_colors = [
    (255, 215,   0),   # gold
    (100, 220, 100),   # green-ish
    (100, 180, 255),   # blue-ish
    (200, 130, 255),   # purple-ish
    (255, 130, 130),   # red-ish
]

for rank, idx in enumerate(top_indices, 1):
    label   = labels.get(idx, f"class_{idx}")
    score   = scores[idx]
    y       = pad + rank * line_h

    # Score bar background
    bar_max = panel_w - 2 * pad
    bar_len = int(bar_max * min(score, 1.0))
    color   = bar_colors[rank - 1]
    draw.rectangle([(pad, y + 2), (pad + bar_len, y + line_h - 4)],
                   fill=(*color, 80))

    # Label and score text
    text = f"{rank}. {label.replace('_', ' ')}  {score:.3f}"
    draw.text((pad + 4, y + 3), text, font=font_reg, fill=(255, 255, 255, 255))

# Save next to the original image as  classified_<name>.jpg
stem     = pathlib.Path(IMAGE_PATH).stem
outdir   = pathlib.Path(IMAGE_PATH).parent
out_path = outdir / f"classified_{stem}.jpg"
orig_img.save(out_path, quality=92)
print(f"\nAnnotated image saved → {out_path}")
