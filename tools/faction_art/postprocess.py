#!/usr/bin/env python3
"""Turn the picked candidates of a pack into the final pieces (plan 13, ch. 6).

For every piece: the RMBG cutout is cropped to its alpha, scaled to the
target height of its type (styles.yaml `heights`, the king fills the
canvas), aligned to the bottom edge, given a 2-3 px outline (dark on the
light side, light on the dark side) and exported at 512, 256 and 128 px.
Writes out/<pack>/<model>/final/<size>/<piece>_<white|black>.png (board, with
the plinth the model draws), final/battle/<size>/ (plinth cut off for the
realtime battle) and manifest.json.

Picks live in picks.yaml (pack -> model -> side -> piece -> candidate); a
missing entry takes candidate 0.

    python3 postprocess.py heaven_hell --model qwen
"""
import argparse
import json
import sys
from pathlib import Path

import yaml
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
SIZES = (512, 256, 128)
COLORS = ("white", "black")
# Share of the canvas the king takes (Olin: the king fills almost the whole
# square; the outline keeps it off the edge), and the floor gap.
KING_HEIGHT = 1.0
BOTTOM_GAP = 0.0
MAX_WIDTH = 1.0
OUTLINE_RGB = {"dark": (34, 26, 38), "light": (246, 240, 228)}
ALPHA_FLOOR = 10


def load(pack_id):
    styles = yaml.safe_load((HERE / "styles.yaml").read_text())
    packs = {p["id"]: p for p in yaml.safe_load((HERE / "factions.yaml").read_text())}
    picks_file = HERE / "picks.yaml"
    picks = (yaml.safe_load(picks_file.read_text()) or {}) if picks_file.exists() else {}
    pack = packs.get(pack_id) or sys.exit(f"unknown pack {pack_id}")
    return styles, pack, picks.get(pack_id, {})


def model_picks(picks, model):
    return picks.get(model, {})


def outline_width(size):
    return max(2, round(size / 64))


def largest_blob(alpha, work=256):
    """Mask of the largest connected opaque area: drops a stray extra figure
    the model sometimes stands beside a building on its own base."""
    small = alpha.resize((work, work), Image.NEAREST).point(lambda a: 255 if a > 96 else 0)
    px = small.load()
    seen, best = set(), []
    for y in range(work):
        for x in range(work):
            if not px[x, y] or (x, y) in seen:
                continue
            blob, stack = [], [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                blob.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < work and 0 <= ny < work and px[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if len(blob) > len(best):
                best = blob
    keep = Image.new("L", (work, work), 0)
    kp = keep.load()
    for x, y in best:
        kp[x, y] = 255
    # Grow a little so the edge of the kept figure is not clipped.
    return keep.filter(ImageFilter.MaxFilter(5)).resize(alpha.size, Image.NEAREST)


def cutout_of(pack_id, model, side_id, piece, candidate):
    image = Image.open(OUT / pack_id / model / side_id / f"{piece}_c{candidate}.png").convert("RGBA")
    alpha = image.getchannel("A").point(lambda a: 0 if a < ALPHA_FLOOR else a)
    keep = largest_blob(alpha)
    alpha = Image.composite(alpha, Image.new("L", alpha.size, 0), keep)
    image.putalpha(alpha)
    return image.crop(alpha.getbbox())


# A plinth is a flat band at the bottom: at most this share of the piece's
# height, and the piece above it narrower than this share of its width.
PLINTH_MAX = 0.16
PLINTH_STEP = 0.75


def row_widths(alpha):
    px = alpha.load()
    w, h = alpha.size
    widths = []
    for y in range(h):
        xs = [x for x in range(w) if px[x, y] > 96]
        widths.append(xs[-1] - xs[0] + 1 if xs else 0)
    return widths


def strip_plinth(cutout):
    """The cutout without the thin display base Qwen likes to put under a
    miniature, for the battle arena; unchanged when it finds none."""
    work = cutout.resize((max(1, cutout.width // 4), max(1, cutout.height // 4)), Image.NEAREST)
    widths = row_widths(work.getchannel("A"))
    h = len(widths)
    bottom = next((y for y in range(h - 1, -1, -1) if widths[y]), None)
    if bottom is None:
        return cutout
    band = range(bottom, max(-1, bottom - int(PLINTH_MAX * h)), -1)
    base = max(widths[y] for y in band)
    inside = False
    for y in band:
        if not inside:
            # The rounded lower rim of the plinth: wait for its full width.
            inside = widths[y] >= 0.9 * base
            continue
        if widths[y] < PLINTH_STEP * base:
            # What stands on the plinth is clearly narrower: cut here.
            return cutout.crop((0, 0, cutout.width, (y + 1) * 4))
    return cutout


def place(cutout, ratio, canvas):
    """The cutout scaled to [ratio] of the king's height, centered and
    standing on the bottom edge of a square [canvas]."""
    target_h = ratio * KING_HEIGHT * canvas
    scale = min(target_h / cutout.height, MAX_WIDTH * canvas / cutout.width)
    w, h = max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))
    sprite = cutout.resize((w, h), Image.LANCZOS)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.alpha_composite(sprite, ((canvas - w) // 2, canvas - round(BOTTOM_GAP * canvas) - h))
    return out


def with_outline(image, tone):
    width = outline_width(image.width)
    alpha = image.getchannel("A").point(lambda a: 255 if a > 96 else 0)
    ring = alpha.filter(ImageFilter.MaxFilter(2 * width + 1))
    base = Image.new("RGBA", image.size, OUTLINE_RGB[tone] + (0,))
    base.putalpha(ring)
    base.alpha_composite(image)
    return base


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pack")
    parser.add_argument("--model", choices=("dev", "qwen"), default="qwen")
    args = parser.parse_args()
    styles, pack, picks = load(args.pack)
    picks = model_picks(picks, args.model)
    final = OUT / pack["id"] / args.model / "final"
    manifest = {"id": pack["id"], "name_cs": pack["name_cs"], "style": pack["style"],
                "sensitivity": pack["sensitivity"], "model": args.model, "board": pack["board"], "sides": []}
    for color, side in zip(COLORS, pack["sides"]):
        manifest["sides"].append({
            "id": side["id"], "color": color, "name_cs": side["name_cs"],
            "pieces": {p: {"name_cs": v["name_cs"],
                           "candidate": picks.get(side["id"], {}).get(p, 0)}
                       for p, v in side["pieces"].items()}})
        for piece in side["pieces"]:
            candidate = picks.get(side["id"], {}).get(piece, 0)
            cutout = cutout_of(pack["id"], args.model, side["id"], piece, candidate)
            # Board pieces keep their plinth; battle sprites lose it.
            for variant, source in (("board", cutout), ("battle", strip_plinth(cutout))):
                stripped = source.crop(source.getchannel("A").getbbox())
                big = place(stripped, styles["heights"][piece], 1024)
                for size in SIZES:
                    small = big.resize((size, size), Image.LANCZOS)
                    folder = final / str(size) if variant == "board" else final / "battle" / str(size)
                    folder.mkdir(parents=True, exist_ok=True)
                    with_outline(small, side["outline"]).save(folder / f"{piece}_{color}.png")
    (final / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1))
    print(f"wrote {final}")


if __name__ == "__main__":
    main()
