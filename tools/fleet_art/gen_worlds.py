#!/usr/bin/env python3
"""Render the world art pilot of plan 12, step 1A (see worlds.py).

Both sides are txt2img renders of their own designs, light side as white and
hell side as black, cut out with RMBG-2.0. Two models:

  dev   FLUX.1-dev, the fleet pipeline (gen_fleets.py); non-commercial licence
  qwen  Qwen-Image fp8, Apache 2.0

Renders land in out_worlds/<model>/<world>/<unit>_<white|black>.png, with a
contact sheet per model in out_worlds/<model>/sheet.png.

  python3 gen_worlds.py --model qwen                     # pilot: pawn and king
  python3 gen_worlds.py --model dev --worlds golems,actium
  python3 gen_worlds.py --model qwen --worlds fable --units all   # whole army
  python3 gen_worlds.py --model qwen --audit
"""
import argparse
import shutil
import sys
import time
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

import gen_fleets as fleet_tools
from worlds import ALL_UNITS, PILOT_UNITS, WORLDS, prompt_for, seed_for

HERE = Path(__file__).resolve().parent
OUT = HERE / "out_worlds"
BAD = HERE / "out_worlds_bad"
MODELS = ("dev", "qwen")
COLORS = ("white", "black")

# Every figure: the largest connected blob holds this share of the opaque
# pixels (one subject, no debris) and keeps this margin to every edge
# (nothing cut off). Symmetric worlds (ships) also keep the fleet mirror gate.
SINGLE_MIN = 0.97
MARGIN_MIN = 0.03
ATTEMPTS = 4
log = fleet_tools.log


def _mask(path, size=256):
    image = Image.open(path).convert("RGBA").resize((size, size), Image.NEAREST)
    return fleet_tools._solid(image)


def single_share(path):
    """Share of opaque pixels in the largest 4-connected blob."""
    mask = _mask(path)
    w, h = mask.size
    px = mask.load()
    seen = set()
    total = 0
    best = 0
    for y in range(h):
        for x in range(w):
            if px[x, y] == 0 or (x, y) in seen:
                continue
            size = 0
            queue = deque([(x, y)])
            seen.add((x, y))
            while queue:
                cx, cy = queue.popleft()
                size += 1
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            total += size
            best = max(best, size)
    return best / total if total else 0.0


def margin(path):
    """Smallest gap between the figure and an edge, as a share of the size."""
    mask = _mask(path)
    box = mask.getbbox()
    if box is None:
        return 0.0
    w, h = mask.size
    return min(box[0] / w, box[1] / h, (w - box[2]) / w, (h - box[3]) / h)


def gate(cutout, world_id):
    single, edge = single_share(cutout), margin(cutout)
    failures = []
    if single < SINGLE_MIN:
        failures.append(f"one subject {single:.2f} < {SINGLE_MIN}")
    if edge < MARGIN_MIN:
        failures.append(f"margin {edge:.3f} < {MARGIN_MIN}")
    score = single + edge
    if WORLDS[world_id]["mirror"]:
        iou = fleet_tools.mirror_iou(cutout)
        score += iou
        if iou < fleet_tools.SYMMETRY_MIN:
            failures.append(f"mirror IoU {iou:.2f} < {fleet_tools.SYMMETRY_MIN}")
    return score, "; ".join(failures) or None


def qwen_graph(prompt, seed, prefix):
    """Qwen-Image txt2img with the same RMBG cutout as ship_graph: raw render
    at node 14, cutout with alpha at node 31."""
    return {
        "1": {"class_type": "UNETLoader",
              "inputs": {"unet_name": "qwen_image_fp8_e4m3fn.safetensors",
                         "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader",
              "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors",
                         "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        "5": {"class_type": "CLIPTextEncode",
              "inputs": {"clip": ["2", 0], "text": fleet_tools.NEGATIVE}},
        "15": {"class_type": "ModelSamplingAuraFlow",
               "inputs": {"model": ["1", 0], "shift": 3.1}},
        "7": {"class_type": "EmptySD3LatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "8": {"class_type": "KSampler",
              "inputs": {"model": ["15", 0], "positive": ["4", 0], "negative": ["5", 0],
                         "latent_image": ["7", 0], "seed": seed, "steps": 20, "cfg": 2.5,
                         "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 0]}},
        "14": {"class_type": "SaveImage",
               "inputs": {"images": ["9", 0], "filename_prefix": prefix + "_rgb"}},
        "30": {"class_type": "RMBG",
               "inputs": {"image": ["9", 0], "model": "RMBG-2.0", "sensitivity": 1.0,
                          "process_res": 1024, "mask_blur": 0, "mask_offset": 0,
                          "invert_output": False, "refine_foreground": True,
                          "background": "Alpha", "background_color": "#808080"}},
        "31": {"class_type": "SaveImage",
               "inputs": {"images": ["30", 0], "filename_prefix": prefix + "_rgba"}},
    }


def render(model, world_id, unit, color):
    folder = OUT / model / world_id
    folder.mkdir(parents=True, exist_ok=True)
    cutout, raw = folder / f"{unit}_{color}.png", folder / f"{unit}_{color}_rgb.png"
    if cutout.exists() and raw.exists() and gate(cutout, world_id)[1] is None:
        return "skip"
    prompt = prompt_for(world_id, color, unit)
    stamp = time.strftime("%H%M%S")
    tries = []
    t0 = time.time()
    for attempt in range(ATTEMPTS):
        seed = (seed_for(world_id, color, unit) + attempt * 7919) % (1 << 32)
        prefix = f"orbitron_worlds/{model}_{world_id}_{unit}_{color}"
        graph = (fleet_tools.ship_graph(prompt, seed, prefix) if model == "dev"
                 else qwen_graph(prompt, seed, prefix))
        outputs = fleet_tools.run(graph)
        raw.write_bytes(fleet_tools.fetch(outputs, "14"))
        cutout.write_bytes(fleet_tools.fetch(outputs, "31"))
        score, failure = gate(cutout, world_id)
        if failure is None:
            return f"{time.time() - t0:.0f}s" + (f", attempt {attempt + 1}" if attempt else "")
        log(f"  attempt {attempt + 1} fails the gate ({failure})")
        dest = BAD / model / world_id
        dest.mkdir(parents=True, exist_ok=True)
        kept = []
        for path in (cutout, raw):
            target = dest / path.name.replace(f"{unit}_{color}", f"{unit}_{color}_try{attempt}{stamp}")
            shutil.move(str(path), target)
            kept.append(target)
        tries.append((score, kept))
    score, (best_cutout, best_raw) = max(tries, key=lambda t: t[0])
    shutil.copy(best_cutout, cutout)
    shutil.copy(best_raw, raw)
    return f"{time.time() - t0:.0f}s, no attempt passed — kept the best, REVIEW"


def sheet(model, names, units, review, file_name="sheet"):
    """One row per world and side, one column per role."""
    cell, label = 256, 18
    rows = [(w, c) for w in names for c in COLORS]
    img = Image.new("RGB", (cell * len(units), (cell + label) * len(rows)), (110, 110, 110))
    draw = ImageDraw.Draw(img)
    for r, (world_id, color) in enumerate(rows):
        y = r * (cell + label)
        for c, unit in enumerate(units):
            path = OUT / model / world_id / f"{unit}_{color}.png"
            if not path.exists():
                continue
            sprite = Image.open(path).convert("RGBA").resize((cell, cell))
            img.paste(sprite, (c * cell, y + label), sprite)
            name = f"{world_id}/{unit}_{color}"
            flagged = name in review
            draw.text((c * cell + 4, y + 3), name + (" REVIEW" if flagged else ""),
                      fill=(255, 80, 80) if flagged else (255, 255, 255))
    img.save(OUT / model / f"{file_name}.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", choices=MODELS, default="qwen")
    parser.add_argument("--worlds", default="all")
    parser.add_argument("--units", default="pilot", help="pilot, all, or a list")
    parser.add_argument("--sheet", default="sheet", help="contact sheet file name")
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()
    names = list(WORLDS) if args.worlds == "all" else args.worlds.split(",")
    units = {"pilot": PILOT_UNITS, "all": ALL_UNITS}.get(args.units) or tuple(args.units.split(","))
    for world_id in names:
        if world_id not in WORLDS:
            sys.exit(f"unknown world {world_id}")
        for side in WORLDS[world_id]["sides"].values():
            missing = set(units) - set(side["units"])
            if missing:
                sys.exit(f"{world_id}/{side['name']} has no {sorted(missing)}")

    if args.audit:
        for path in sorted((OUT / args.model).glob("*/*_*.png")):
            if not path.stem.endswith("_rgb"):
                print(f"{path.parent.name}/{path.stem}: {gate(path, path.parent.name)[1] or 'ok'}")
        return

    failures, review = [], set()
    for world_id in names:
        for color in COLORS:
            for unit in units:
                name = f"{world_id}/{unit}_{color}"
                try:
                    result = render(args.model, world_id, unit, color)
                    if "REVIEW" in result:
                        review.add(name)
                    log(f"{args.model} {name}: {result}")
                except Exception as e:  # noqa: BLE001 - keep the batch going
                    log(f"{args.model} {name}: FAILED {e}")
                    failures.append(name)
    sheet(args.model, names, units, review, args.sheet)
    log(f"done, {len(failures)} failed: {failures}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
