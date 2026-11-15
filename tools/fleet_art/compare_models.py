#!/usr/bin/env python3
"""Compare commercially usable image models with the FLUX.1-dev pilot.

Renders one piece per world with FLUX.1-schnell (Apache 2.0) and Qwen-Image
(Apache 2.0) from the same prompt and seed as `gen_worlds.py`, repaints each
dark with an img2img pass of the same model (no Kontext), runs the same gates
and writes a contact sheet next to the FLUX.1-dev pieces in `out_worlds/`.

    COMFY_URL=... python3 compare_models.py
"""
import hashlib
import json
import time
from pathlib import Path

from PIL import Image, ImageDraw

import gen_fleets as fleet_tools
import gen_worlds
from worlds import WORLDS, black_prompt, seed_for, white_prompt

HERE = Path(__file__).resolve().parent
OUT = HERE / "out_compare"
SUBJECTS = [
    ("golems", "marble", "rook"),
    ("sky_beasts", "dragons", "king"),
    ("actium", "rome", "king"),
    ("rome_egypt", "legion", "pawn"),
]
MODELS = ["schnell", "qwen"]
DARK_DENOISE = 0.7


def _tail(g, decoded, prefix):
    g["14"] = {"class_type": "SaveImage",
               "inputs": {"images": decoded, "filename_prefix": prefix + "_rgb"}}
    g["30"] = {"class_type": "RMBG",
               "inputs": {"image": decoded, "model": "RMBG-2.0", "sensitivity": 1.0,
                          "process_res": 1024, "mask_blur": 0, "mask_offset": 0,
                          "invert_output": False, "refine_foreground": True,
                          "background": "Alpha", "background_color": "#808080"}}
    g["31"] = {"class_type": "SaveImage",
               "inputs": {"images": ["30", 0], "filename_prefix": prefix + "_rgba"}}
    return g


def graph(model, prompt, seed, prefix, ref=None):
    """txt2img, or an img2img pass over the uploaded [ref]."""
    if model == "schnell":
        g = {
            "1": {"class_type": "CheckpointLoaderSimple",
                  "inputs": {"ckpt_name": "flux1-schnell-fp8.safetensors"}},
            "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": prompt}},
            "5": {"class_type": "CLIPTextEncode",
                  "inputs": {"clip": ["1", 1], "text": fleet_tools.NEGATIVE}},
            "15": {"class_type": "NAGuidance",
                   "inputs": {"model": ["1", 0], "nag_scale": 5.0, "nag_alpha": 0.5,
                              "nag_tau": 1.5}},
        }
        model_ref, vae, steps, cfg = ["15", 0], ["1", 2], 4, 1.0
    else:
        g = {
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
        }
        model_ref, vae, steps, cfg = ["15", 0], ["3", 0], 20, 2.5
    if ref:
        g["20"] = {"class_type": "LoadImage", "inputs": {"image": ref}}
        g["7"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["20", 0], "vae": vae}}
        denoise = DARK_DENOISE
    else:
        g["7"] = {"class_type": "EmptySD3LatentImage",
                  "inputs": {"width": 1024, "height": 1024, "batch_size": 1}}
        denoise = 1.0
    g["8"] = {"class_type": "KSampler",
              "inputs": {"model": model_ref, "positive": ["4", 0], "negative": ["5", 0],
                         "latent_image": ["7", 0], "seed": seed, "steps": steps, "cfg": cfg,
                         "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}}
    g["9"] = {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": vae}}
    return _tail(g, ["9", 0], prefix)


def render(model, world_id, faction_id, unit, color):
    folder = OUT / model / world_id / faction_id
    folder.mkdir(parents=True, exist_ok=True)
    seed = seed_for(world_id, faction_id, unit)
    prefix = f"orbitron_compare/{model}_{world_id}_{faction_id}_{unit}_{color}"
    ref = None
    if color == "white":
        prompt = white_prompt(world_id, faction_id, unit)
    else:
        white_raw = folder / f"{unit}_white_rgb.png"
        digest = hashlib.sha1(white_raw.read_bytes()).hexdigest()[:12]
        ref = fleet_tools.upload(white_raw, f"orbitron_cmp_{model}_{digest}.png")
        prompt = black_prompt(world_id, faction_id, unit)
    t0 = time.time()
    outputs = fleet_tools.run(graph(model, prompt, seed, prefix, ref))
    seconds = time.time() - t0
    (folder / f"{unit}_{color}_rgb.png").write_bytes(fleet_tools.fetch(outputs, "14"))
    (folder / f"{unit}_{color}.png").write_bytes(fleet_tools.fetch(outputs, "31"))
    _, failure = gen_worlds.gate(folder, unit, color, WORLDS[world_id]["view"])
    return seconds, failure


def sheet(results):
    cell = 256
    cols = [("dev", "white"), ("schnell", "white"), ("qwen", "white"),
            ("dev", "black"), ("schnell", "black"), ("qwen", "black")]
    img = Image.new("RGB", (cell * len(cols), 24 + cell * len(SUBJECTS)), (128, 128, 128))
    draw = ImageDraw.Draw(img)
    for c, (model, color) in enumerate(cols):
        draw.text((c * cell + 6, 6), f"{model} {color}", fill=(255, 255, 255))
    for r, (world_id, faction_id, unit) in enumerate(SUBJECTS):
        for c, (model, color) in enumerate(cols):
            base = gen_worlds.OUT if model == "dev" else OUT / model
            path = base / world_id / faction_id / f"{unit}_{color}.png"
            if not path.exists():
                continue
            sprite = Image.open(path).convert("RGBA").resize((cell, cell))
            img.paste(sprite, (c * cell, 24 + r * cell), sprite)
            failure = results.get((model, world_id, faction_id, unit, color), (0, None))[1]
            if failure:
                draw.text((c * cell + 6, 24 + r * cell + cell - 16), failure[:38], fill=(255, 60, 60))
    img.save(OUT / "sheet.png")


def main():
    results = {}
    for world_id, faction_id, unit in SUBJECTS:
        for color in ("white", "black"):
            folder = gen_worlds.OUT / world_id / faction_id
            if (folder / f"{unit}_{color}.png").exists():
                results[("dev", world_id, faction_id, unit, color)] = (
                    None, gen_worlds.gate(folder, unit, color, WORLDS[world_id]["view"])[1])
    for model in MODELS:
        for world_id, faction_id, unit in SUBJECTS:
            for color in ("white", "black"):
                name = f"{model} {world_id}/{faction_id}/{unit}_{color}"
                try:
                    seconds, failure = render(model, world_id, faction_id, unit, color)
                    results[(model, world_id, faction_id, unit, color)] = (seconds, failure)
                    fleet_tools.log(f"{name}: {seconds:.0f}s {failure or 'ok'}")
                except Exception as e:  # noqa: BLE001 - keep the comparison going
                    fleet_tools.log(f"{name}: FAILED {e}")
    sheet(results)
    (OUT / "results.json").write_text(json.dumps(
        {"/".join(str(p) for p in k): v for k, v in results.items()}, indent=1))
    fleet_tools.log("done")


if __name__ == "__main__":
    main()
