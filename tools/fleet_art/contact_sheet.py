#!/usr/bin/env python3
"""Contact sheets of the generated fleets on the arena's dark background.

  python3 contact_sheet.py            -> sheets/<fleet>.png + sheets/all_fleets.jpg
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from fleets import BOW_DOWN, FLEETS, UNITS

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
SHEETS = HERE / "sheets"
BG = (26, 26, 46)          # GameScreen background 0xFF1A1A2E
CELL_BG = (40, 30, 70)     # arena gradient's purple end
TEXT = (200, 200, 220)
COLORS = ("white", "black")


def font(size):
    for path in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def sprite(slug, unit, color, cell):
    path = OUT / slug / f"{unit}_{color}.png"
    tile = Image.new("RGBA", (cell, cell), CELL_BG + (255,))
    if not path.exists():
        return tile
    ship = Image.open(path).convert("RGBA")
    if f"{slug}/{unit}" in BOW_DOWN:
        ship = ship.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    ship.thumbnail((cell - 8, cell - 8), Image.LANCZOS)
    tile.alpha_composite(ship, ((cell - ship.width) // 2, (cell - ship.height) // 2))
    return tile


def fleet_sheet(fleet, cell=192, label=40, pad=8):
    slug, name = fleet[0], fleet[1]
    units = list(UNITS)
    w = label * 3 + len(COLORS) * (cell + pad) + pad
    h = label + len(units) * (cell + pad) + pad
    sheet = Image.new("RGBA", (w, h), BG + (255,))
    draw = ImageDraw.Draw(sheet)
    draw.text((pad, 10), name, fill=TEXT, font=font(22))
    for row, unit in enumerate(units):
        y = label + pad + row * (cell + pad)
        draw.text((pad, y + cell // 2 - 10), unit, fill=TEXT, font=font(18))
        for col, color in enumerate(COLORS):
            x = label * 3 + pad + col * (cell + pad)
            sheet.alpha_composite(sprite(slug, unit, color, cell), (x, y))
    return sheet


def overview(cell=112, pad=6, label=190):
    units = list(UNITS)
    cols = [(u, c) for u in units for c in COLORS]
    head = 34
    w = label + len(cols) * (cell + pad) + pad
    h = head + len(FLEETS) * (cell + pad) + pad
    sheet = Image.new("RGBA", (w, h), BG + (255,))
    draw = ImageDraw.Draw(sheet)
    for i, (unit, color) in enumerate(cols):
        x = label + pad + i * (cell + pad)
        draw.text((x + 4, 8), f"{unit} {color[0].upper()}", fill=TEXT, font=font(15))
    for row, fleet in enumerate(FLEETS):
        y = head + pad + row * (cell + pad)
        draw.text((pad, y + cell // 2 - 9), fleet[1], fill=TEXT, font=font(16))
        for i, (unit, color) in enumerate(cols):
            x = label + pad + i * (cell + pad)
            sheet.alpha_composite(sprite(fleet[0], unit, color, cell), (x, y))
    return sheet


def main():
    SHEETS.mkdir(exist_ok=True)
    for fleet in FLEETS:
        if (OUT / fleet[0]).exists():
            fleet_sheet(fleet).convert("RGB").save(SHEETS / f"{fleet[0]}.png")
    overview().convert("RGB").save(SHEETS / "all_fleets.jpg", quality=90)
    print("sheets in", SHEETS)


if __name__ == "__main__":
    main()
