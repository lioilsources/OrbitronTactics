#!/usr/bin/env python3
"""Review sheets and acceptance tests of a pack (plan 13, ch. 1.4 and 6).

    python3 sheets.py heaven_hell --compare             # dev and qwen side by side
    python3 sheets.py heaven_hell --candidates --model qwen
    python3 sheets.py heaven_hell --model qwen          # tests on the final pieces

Writes into out/<pack>/sheets/ (model sheets get the model in the name):
  compare_<side>.png     rows = pieces, columns = candidates of each model
  candidates_<side>.png  rows = pieces, columns = candidates (picked one framed)
  silhouettes.png        test 1: alpha filled with one color, 64 px
  board.png              test 2-4: starting position on 64 px squares, in
                         color, grayscale, deuteranopia and protanopia
  metrics.json           test 3 in numbers: luma of the bases and outlines
"""
import argparse
import json
import sys
from pathlib import Path

import yaml
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps, ImageStat

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
PIECES = ("king", "queen", "rook", "bishop", "knight", "pawn")
COLORS = ("white", "black")
BACK_RANK = ("rook", "knight", "bishop", "queen", "king", "bishop", "knight", "rook")
# Machado et al. 2009, severity 1.0, as PIL RGB->RGB matrices.
CVD = {
    "deuteranopia": (0.367322, 0.860646, -0.227968, 0, 0.280085, 0.672501, 0.047413, 0,
                     -0.011820, 0.042940, 0.968881, 0),
    "protanopia": (0.152286, 1.052583, -0.204868, 0, 0.114503, 0.786281, 0.099216, 0,
                   -0.003882, -0.048116, 1.051998, 0),
}
GREY = (128, 128, 128)
# A font with Czech diacritics for the labels; PIL's default has none.
FONT_PATHS = ("/System/Library/Fonts/Supplemental/Arial.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")


def font(size=13):
    for path in FONT_PATHS:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()
# Test 3: the sides differ in luma by at least this share of full scale.
LUMA_GAP_MIN = 0.30


def load(pack_id):
    packs = {p["id"]: p for p in yaml.safe_load((HERE / "factions.yaml").read_text())}
    picks_file = HERE / "picks.yaml"
    picks = (yaml.safe_load(picks_file.read_text()) or {}) if picks_file.exists() else {}
    pack = packs.get(pack_id) or sys.exit(f"unknown pack {pack_id}")
    return pack, picks.get(pack_id, {})


def compare_sheet(pack, dest, models=("dev", "qwen")):
    cell, label = 220, 16
    for side in pack["sides"]:
        cols = [(m, c) for m in models for c in range(4)
                if (OUT / pack["id"] / m / side["id"] / f"king_c{c}.png").exists()]
        img = Image.new("RGB", (cell * max(1, len(cols)), label + (cell + label) * len(PIECES)), GREY)
        draw = ImageDraw.Draw(img)
        for c, (model, cand) in enumerate(cols):
            draw.text((c * cell + 4, 2), f"{model} c{cand}", fill="white", font=font())
        for r, piece in enumerate(PIECES):
            y = label + r * (cell + label)
            draw.text((4, y + 2), f"{piece}  {side['pieces'][piece]['name_cs']}", fill="white", font=font())
            for c, (model, cand) in enumerate(cols):
                path = OUT / pack["id"] / model / side["id"] / f"{piece}_c{cand}.png"
                if path.exists():
                    sprite = Image.open(path).convert("RGBA").resize((cell, cell))
                    img.paste(sprite, (c * cell, y + label), sprite)
        img.save(dest / f"compare_{side['id']}.png")


def candidates_sheet(pack, model, picks, dest):
    cell, label = 220, 16
    for side in pack["sides"]:
        folder = OUT / pack["id"] / model / side["id"]
        counts = [len(list(folder.glob(f"{p}_c*_rgb.png"))) for p in PIECES]
        cols = max(counts + [1])
        img = Image.new("RGB", (cell * cols, (cell + label) * len(PIECES)), GREY)
        draw = ImageDraw.Draw(img)
        for r, piece in enumerate(PIECES):
            y = r * (cell + label)
            draw.text((4, y + 2), f"{piece}  {side['pieces'][piece]['name_cs']}", fill="white", font=font())
            picked = picks.get(side["id"], {}).get(piece)
            for c in range(cols):
                path = folder / f"{piece}_c{c}.png"
                if not path.exists():
                    continue
                sprite = Image.open(path).convert("RGBA").resize((cell, cell))
                img.paste(sprite, (c * cell, y + label), sprite)
                draw.text((c * cell + 4, y + label + 2), f"c{c}", fill="white", font=font())
                if picked == c:
                    draw.rectangle((c * cell, y + label, (c + 1) * cell - 1, y + label + cell - 1),
                                   outline=(255, 220, 0), width=4)
        img.save(dest / f"candidates_{model}_{side['id']}.png")


MODEL = "qwen"


def final_piece(pack, piece, color, size=128):
    """A final piece at [size]; sizes below the exported 128 px are scaled
    down from it, as the app would."""
    source = size if size in (512, 256, 128) else 128
    path = OUT / pack["id"] / MODEL / "final" / str(source) / f"{piece}_{color}.png"
    image = Image.open(path).convert("RGBA")
    return image if source == size else image.resize((size, size), Image.LANCZOS)


def silhouettes(pack, dest):
    cell = 64
    img = Image.new("RGB", (cell * len(PIECES), cell * 2), (235, 235, 235))
    for r, color in enumerate(COLORS):
        for c, piece in enumerate(PIECES):
            alpha = final_piece(pack, piece, color, 64).getchannel("A")
            img.paste((30, 30, 30), (c * cell, r * cell), alpha)
    img.resize((img.width * 3, img.height * 3), Image.NEAREST).save(dest / f"silhouettes_{MODEL}.png")


def board(pack):
    cell = 64
    light, dark = (ImageColor(pack["board"]["light"]), ImageColor(pack["board"]["dark"]))
    img = Image.new("RGB", (cell * 8, cell * 8))
    draw = ImageDraw.Draw(img)
    for rank in range(8):
        for file in range(8):
            fill = light if (rank + file) % 2 == 0 else dark
            draw.rectangle((file * cell, rank * cell, (file + 1) * cell - 1, (rank + 1) * cell - 1),
                           fill=fill)
    rows = {0: ("black", BACK_RANK), 1: ("black", ("pawn",) * 8),
            6: ("white", ("pawn",) * 8), 7: ("white", BACK_RANK)}
    for rank, (color, pieces) in rows.items():
        for file, piece in enumerate(pieces):
            sprite = final_piece(pack, piece, color, 64)
            if color == "black":
                # The app mirrors the opponent so the armies face each other.
                sprite = ImageOps.mirror(sprite)
            img.paste(sprite, (file * cell, rank * cell), sprite)
    return img


def ImageColor(hex_color):  # noqa: N802 - mirrors PIL.ImageColor
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def board_tests(pack, dest):
    color = board(pack)
    variants = [("color", color), ("grayscale", ImageOps.grayscale(color).convert("RGB"))]
    variants += [(name, color.convert("RGB", matrix)) for name, matrix in CVD.items()]
    w, h = color.size
    sheet = Image.new("RGB", (w * 2 + 12, (h + 18) * 2 + 6), (40, 40, 40))
    draw = ImageDraw.Draw(sheet)
    for i, (name, image) in enumerate(variants):
        x, y = (i % 2) * (w + 12), (i // 2) * (h + 24)
        draw.text((x + 4, y + 2), name, fill="white", font=font())
        sheet.paste(image, (x, y + 18))
    sheet.save(dest / f"board_{MODEL}.png")


def luma_bands(pack):
    """Mean luma of the bottom band of each side's pieces (the base) and of
    the outline ring, over the 128 px finals."""
    out = {}
    for color in COLORS:
        bases, rings = [], []
        for piece in PIECES:
            image = final_piece(pack, piece, color)
            alpha = image.getchannel("A")
            box = alpha.getbbox()
            band = (box[0], box[3] - max(4, (box[3] - box[1]) // 8), box[2], box[3])
            gray = image.convert("L")
            mask = alpha.point(lambda a: 255 if a > 200 else 0)
            bases.append(ImageStat.Stat(gray.crop(band), mask=mask.crop(band)).mean[0])
            # Outline = opaque pixels at the very edge of the silhouette.
            edge = mask.filter(ImageFilter.FIND_EDGES)
            rings.append(ImageStat.Stat(gray, mask=edge).mean[0])
        out[color] = {"base": sum(bases) / len(bases), "outline": sum(rings) / len(rings)}
    gaps = {k: abs(out["white"][k] - out["black"][k]) / 255 for k in ("base", "outline")}
    return {"luma": out, "gap": gaps,
            "pass": max(gaps.values()) >= LUMA_GAP_MIN, "gap_min": LUMA_GAP_MIN}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pack")
    parser.add_argument("--model", choices=("dev", "qwen"), default="qwen")
    parser.add_argument("--candidates", action="store_true")
    parser.add_argument("--compare", action="store_true")
    args = parser.parse_args()
    global MODEL
    MODEL = args.model
    pack, picks = load(args.pack)
    picks = picks.get(args.model, {})
    dest = OUT / pack["id"] / "sheets"
    dest.mkdir(parents=True, exist_ok=True)
    if args.compare:
        compare_sheet(pack, dest)
    elif args.candidates:
        candidates_sheet(pack, args.model, picks, dest)
    else:
        silhouettes(pack, dest)
        board_tests(pack, dest)
        metrics = luma_bands(pack)
        (dest / f"metrics_{args.model}.json").write_text(json.dumps(metrics, indent=1))
        print(json.dumps(metrics, indent=1))
    print(f"wrote {dest}")


if __name__ == "__main__":
    main()
