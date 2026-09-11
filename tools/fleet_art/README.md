# Fleet ship art

Generates the battle ship sprites in `assets/fleets/`: 10 fleets × 6 unit types × white/black, drawn top-down with the bow up. Rendering runs on the ComfyUI server at https://comfyui.ol1n.com (DGX Spark).

| File | What it does |
|------|--------------|
| `fleets.py` | Unit roles, fleet design languages and colors, prompts, stable seeds, `BOW_DOWN` |
| `gen_fleets.py` | Renders every sprite into `out/<fleet>/`, with quality gates and re-rolls |
| `contact_sheet.py` | Review sheets on the arena background in `sheets/` |
| `export_assets.py` | Crops, squares and scales the cutouts to 256 px into `assets/fleets/` |
| `rerolls.json` | Manual re-rolls: `{"fleet/unit": n}` moves a ship to a fresh seed |

## Requirements

- Python 3 with Pillow (`pip install pillow`)
- ComfyUI with FLUX.1-dev (`flux1-dev.safetensors`), FLUX Kontext (`flux1-dev-kontext_fp8_scaled.safetensors`), `t5xxl_fp16` and `clip_l`, `ae.safetensors`, the `NAGuidance` node and the RMBG node pack (RMBG-2.0)
- A Cloudflare Access service token: `CF_ID` and `CF_SECRET` in the environment, or a Dart file defining `cfAccessClientId` and `cfAccessClientSecret` at `CF_SECRETS_FILE` (defaults to the MangaPrompts secrets file on the dev Mac). `COMFY_URL` overrides the server.

## Pipeline

1. **White ship:** FLUX.1-dev txt2img at 1024² on a flat gray ground. NAGuidance makes the negative prompt (shadows, ground, text) work at cfg 1. RMBG-2.0 cuts the ship out.
2. **Black ship:** FLUX Kontext repaints the white render's hull, so both sides share one design, then the same cutout.
3. **Gates:** a white cutout must mirror onto itself (IoU ≥ 0.90), which catches diagonal or perspective ships. A black one must be clearly darker than its white twin (mean luma ratio ≤ 0.60). A failing render is re-rolled with a new seed, white up to 4×, black up to 3× with a darker wording; rejects go to `out_bad/`.

The server is shared: one job runs at a time, a job left behind by a killed client is adopted instead of queued again, and a job interrupted by another client is re-queued. An interrupted batch resumes where it stopped.

## Workflow

```bash
cd tools/fleet_art
python3 gen_fleets.py --fleets all        # or: --fleets void_hive --units king
python3 gen_fleets.py --audit             # re-check the sprites on disk
python3 contact_sheet.py                  # sheets/<fleet>.png, sheets/all_fleets.jpg
python3 export_assets.py                  # into ../../assets/fleets
```

Review the sheets by eye before exporting, because the gates cannot tell which way the bow points. FLUX likes to draw queens and kings bow-down, sword-like with the tower on top. Either re-roll the ship (bump its count in `rerolls.json`, move `out/<fleet>/<unit>_white.png` and `<unit>_white_rgb.png` into `out_bad/`, run the batch again; the black repaint follows), or, when the design is good, add it to `BOW_DOWN` so the sheets and the export flip it top to bottom.

## Adding a fleet

Add it to `FLEETS` in `fleets.py`, generate and export it, then add the slug to `FleetSkin` (`lib/features/battle/data/fleet_skin.dart`) and its folder to the `assets` list in `pubspec.yaml`. `test/features/battle/fleet_skin_test.dart` fails until all three agree.
