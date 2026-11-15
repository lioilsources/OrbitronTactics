#!/usr/bin/env python3
"""Render the world art pilot of plan 12, step 1A (see worlds.py).

Same ComfyUI pipeline as gen_fleets.py: FLUX.1-dev txt2img for the light
side, FLUX Kontext repaint for the dark side, RMBG-2.0 cutout. Renders land
in out_worlds/<world>/<faction>/<unit>_<white|black>.png.

  python3 gen_worlds.py --first                  # the one piece drawn first
  python3 gen_worlds.py --worlds golems,actium   # pilot set: pawn and king
  python3 gen_worlds.py --worlds all --dark      # plus one dark repaint each
  python3 gen_worlds.py --audit
"""
import argparse
import hashlib
import shutil
import sys
import time
from collections import deque
from pathlib import Path

from PIL import Image

import gen_fleets as fleet_tools
from worlds import FIRST_PIECE, PILOT_UNITS, WORLDS, black_prompt, seed_for, white_prompt

HERE = Path(__file__).resolve().parent
OUT = HERE / "out_worlds"
BAD = HERE / "out_worlds_bad"

# Side figures: the largest connected blob must hold this share of the
# opaque pixels (one figure, no debris), and the figure keeps this margin to
# every edge (nothing cut off).
SINGLE_MIN = 0.97
MARGIN_MIN = 0.03
ATTEMPTS = {"white": 4, "black": 3}
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


def gate(folder, unit, color, view):
    cutout = folder / f"{unit}_{color}.png"
    if color == "black":
        ratio = fleet_tools.mean_luma(cutout) / fleet_tools.mean_luma(folder / f"{unit}_white.png")
        return -ratio, None if ratio <= fleet_tools.DARKNESS_MAX else (
            f"darkness {ratio:.2f} > {fleet_tools.DARKNESS_MAX}")
    if view == "top":
        iou = fleet_tools.mirror_iou(cutout)
        return iou, None if iou >= fleet_tools.SYMMETRY_MIN else (
            f"mirror IoU {iou:.2f} < {fleet_tools.SYMMETRY_MIN}")
    single, edge = single_share(cutout), margin(cutout)
    failures = []
    if single < SINGLE_MIN:
        failures.append(f"one figure {single:.2f} < {SINGLE_MIN}")
    if edge < MARGIN_MIN:
        failures.append(f"margin {edge:.3f} < {MARGIN_MIN}")
    return single + edge, "; ".join(failures) or None


def render(world_id, faction_id, unit, color):
    view = WORLDS[world_id]["view"]
    folder = OUT / world_id / faction_id
    folder.mkdir(parents=True, exist_ok=True)
    cutout, raw = folder / f"{unit}_{color}.png", folder / f"{unit}_{color}_rgb.png"
    if cutout.exists() and raw.exists() and gate(folder, unit, color, view)[1] is None:
        return "skip"
    stamp = time.strftime("%H%M%S")
    tries = []
    t0 = time.time()
    for attempt in range(ATTEMPTS[color]):
        seed = (seed_for(world_id, faction_id, unit) + attempt * 7919) % (1 << 32)
        prefix = f"orbitron_worlds/{world_id}_{faction_id}_{unit}_{color}"
        if color == "white":
            graph = fleet_tools.ship_graph(white_prompt(world_id, faction_id, unit), seed, prefix)
        else:
            white_raw = folder / f"{unit}_white_rgb.png"
            digest = hashlib.sha1(white_raw.read_bytes()).hexdigest()[:12]
            ref = fleet_tools.upload(white_raw, f"orbitron_{world_id}_{faction_id}_{unit}_{digest}.png")
            graph = fleet_tools.ship_graph(
                black_prompt(world_id, faction_id, unit, attempt), seed, prefix, ref=ref)
        outputs = fleet_tools.run(graph)
        raw.write_bytes(fleet_tools.fetch(outputs, "14"))
        cutout.write_bytes(fleet_tools.fetch(outputs, "31"))
        score, failure = gate(folder, unit, color, view)
        if failure is None:
            return f"{time.time() - t0:.0f}s" + (f", attempt {attempt + 1}" if attempt else "")
        log(f"  attempt {attempt + 1} fails the gate ({failure})")
        dest = BAD / world_id / faction_id
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


def jobs(args):
    if args.first:
        world_id, faction_id, unit = FIRST_PIECE
        return [(world_id, faction_id, unit, "white")]
    names = list(WORLDS) if args.worlds == "all" else args.worlds.split(",")
    out = []
    for world_id in names:
        if world_id not in WORLDS:
            sys.exit(f"unknown world {world_id}")
        factions = list(WORLDS[world_id]["factions"])[:2]
        for faction_id in factions:
            for unit in PILOT_UNITS:
                out.append((world_id, faction_id, unit, "white"))
        if args.dark:
            # One dark repaint per world: the first faction's king.
            out.append((world_id, factions[0], PILOT_UNITS[-1], "black"))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--worlds", default="all")
    parser.add_argument("--first", action="store_true", help="only the piece drawn first")
    parser.add_argument("--dark", action="store_true", help="add one dark repaint per world")
    parser.add_argument("--audit", action="store_true")
    args = parser.parse_args()

    if args.audit:
        for path in sorted(OUT.glob("*/*/*_*.png")):
            if path.stem.endswith("_rgb"):
                continue
            world_id, faction_id = path.parent.parent.name, path.parent.name
            unit, color = path.stem.rsplit("_", 1)
            _, failure = gate(path.parent, unit, color, WORLDS[world_id]["view"])
            print(f"{world_id}/{faction_id}/{path.stem}: {failure or 'ok'}")
        return

    failures = []
    for world_id, faction_id, unit, color in jobs(args):
        name = f"{world_id}/{faction_id}/{unit}_{color}"
        try:
            log(f"{name}: {render(world_id, faction_id, unit, color)}")
        except Exception as e:  # noqa: BLE001 - keep the batch going
            log(f"{name}: FAILED {e}")
            failures.append(name)
    log(f"done, {len(failures)} failed: {failures}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
