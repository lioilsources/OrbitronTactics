#!/usr/bin/env python3
"""Export the fleet cutouts as game-ready sprites.

Each cutout is cropped to its visible pixels, padded to a square with the ship
centred (aspect kept) and scaled to SIZE px. Every sprite fills its square the
same way, so relative ship size per unit is up to the game, not the file.

  python3 export_assets.py                     # into the app's assets/fleets
  python3 export_assets.py --dest /tmp/fleets
"""
import argparse
from pathlib import Path

from PIL import Image

from fleets import BOW_DOWN, FLEETS, UNITS

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
ASSETS = HERE.parents[1] / "assets" / "fleets"
SIZE = 256
MARGIN = 0.04          # transparent border kept around the ship, per side
ALPHA_FLOOR = 12       # ignore RMBG's faint halo when finding the ship's bounds


def export(src, dest, flip=False):
    ship = Image.open(src).convert("RGBA")
    solid = ship.getchannel("A").point(lambda a: 255 if a > ALPHA_FLOOR else 0)
    bbox = solid.getbbox()
    if bbox is None:
        raise ValueError(f"{src}: cutout is empty")
    ship = ship.crop(bbox)
    if flip:
        ship = ship.transpose(Image.Transpose.FLIP_TOP_BOTTOM)

    side = round(max(ship.size) * (1 + 2 * MARGIN))
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(ship, ((side - ship.width) // 2, (side - ship.height) // 2))
    square.resize((SIZE, SIZE), Image.LANCZOS).save(dest, optimize=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dest", type=Path, default=ASSETS)
    args = parser.parse_args()

    count = 0
    missing = []
    for fleet in FLEETS:
        for unit in UNITS:
            for color in ("white", "black"):
                src = OUT / fleet[0] / f"{unit}_{color}.png"
                if not src.exists():
                    missing.append(f"{fleet[0]}/{unit}_{color}")
                    continue
                folder = args.dest / fleet[0]
                folder.mkdir(parents=True, exist_ok=True)
                export(src, folder / f"{unit}_{color}.png",
                       flip=f"{fleet[0]}/{unit}" in BOW_DOWN)
                count += 1
    total = sum(p.stat().st_size for p in args.dest.rglob("*.png"))
    print(f"exported {count} sprites, {total / 1e6:.1f} MB; missing: {missing or 'none'}")


if __name__ == "__main__":
    main()
