#!/usr/bin/env python3
"""Generate faction chess pieces with FLUX.1-dev in ComfyUI (plan 13).

Composes each prompt from styles.yaml and factions.yaml, renders candidates
(FLUX.1-dev or Qwen-Image, same prompt) and keeps for each: the raw render, an RMBG-2.0 cutout and the metadata
(prompt, seed, guidance). Output: out/<pack>/<model>/<side>/<piece>_c<i>[_rgb].png
and .json; line-ups in out/<pack>/<model>/lineup/.

    python3 gen_pieces.py heaven_hell --lineup          # style check first
    python3 gen_pieces.py heaven_hell                   # 6 pieces x 2 sides x 4
    python3 gen_pieces.py heaven_hell --pieces king --side hell --candidates 2
    python3 gen_pieces.py heaven_hell --model qwen      # same prompts on Qwen-Image
    python3 gen_pieces.py heaven_hell --print           # prompts only

Connection as in ../fleet_art/gen_fleets.py: COMFY_URL, CF_ID / CF_SECRET
(dummies are fine through a tunnel), COMFY_FRONT=1 jumps a shared queue.
"""
import argparse
import json
import sys
import time
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "fleet_art"))

OUT = HERE / "out"
PIECES = ("king", "queen", "rook", "bishop", "knight", "pawn")
FLUX = "flux1-dev.safetensors"
QWEN = "qwen_image_fp8_e4m3fn.safetensors"
STEPS = {"dev": 26, "qwen": 20}
MODELS = ("dev", "qwen")


def load():
    styles = yaml.safe_load((HERE / "styles.yaml").read_text())
    packs = {p["id"]: p for p in yaml.safe_load((HERE / "factions.yaml").read_text())}
    return styles, packs


def piece_prompt(styles, pack, side, piece):
    frame = styles["frame"].format(base=side["base"], rim=side["rim"])
    return styles["piece"].format(
        style=styles["styles"][pack["style"]],
        subject=side["pieces"][piece]["subject"],
        silhouette=styles["silhouettes"][piece],
        dna=side["dna"],
        frame=frame,
    )


def lineup_prompt(styles, pack, side):
    subjects = {p: _lower_first(side["pieces"][p]["subject"]) for p in PIECES}
    return styles["lineup"].format(
        style=styles["styles"][pack["style"]], faction=side["name_en"] if "name_en" in side
        else side["id"].replace("_", " ").title(), base=side["base"],
        dna=_lower_first(side["dna"]), **subjects)


def _lower_first(text):
    return text[0].lower() + text[1:] if text and not text.startswith(("The ", "Queen ")) else text


def graph(model, prompt, seed, guidance, prefix, size):
    if model == "qwen":
        return qwen_graph(prompt, seed, prefix, size)
    w, h = size
    return {
        "1": {"class_type": "UNETLoader",
              "inputs": {"unet_name": FLUX, "weight_dtype": "fp8_e4m3fn"}},
        "2": {"class_type": "DualCLIPLoader",
              "inputs": {"clip_name1": "t5xxl_fp16.safetensors",
                         "clip_name2": "clip_l.safetensors", "type": "flux"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        # The plan uses no negative prompt; at cfg 1 the empty one is ignored.
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": ""}},
        "6": {"class_type": "FluxGuidance",
              "inputs": {"conditioning": ["4", 0], "guidance": guidance}},
        "7": {"class_type": "EmptySD3LatentImage",
              "inputs": {"width": w, "height": h, "batch_size": 1}},
        "8": {"class_type": "KSampler",
              "inputs": {"model": ["1", 0], "positive": ["6", 0], "negative": ["5", 0],
                         "latent_image": ["7", 0], "seed": seed, "steps": STEPS["dev"],
                         "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple",
                         "denoise": 1.0}},
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


def _tail(g, prefix):
    g["14"] = {"class_type": "SaveImage",
               "inputs": {"images": ["9", 0], "filename_prefix": prefix + "_rgb"}}
    g["30"] = {"class_type": "RMBG",
               "inputs": {"image": ["9", 0], "model": "RMBG-2.0", "sensitivity": 1.0,
                          "process_res": 1024, "mask_blur": 0, "mask_offset": 0,
                          "invert_output": False, "refine_foreground": True,
                          "background": "Alpha", "background_color": "#808080"}}
    g["31"] = {"class_type": "SaveImage",
               "inputs": {"images": ["30", 0], "filename_prefix": prefix + "_rgba"}}
    return g


def qwen_graph(prompt, seed, prefix, size):
    """Qwen-Image (Apache 2.0) with the same prompt and cutout; cfg 2.5 and
    an empty negative, as measured on L40S."""
    w, h = size
    return _tail({
        "1": {"class_type": "UNETLoader",
              "inputs": {"unet_name": QWEN, "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader",
              "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors",
                         "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": ""}},
        "15": {"class_type": "ModelSamplingAuraFlow",
               "inputs": {"model": ["1", 0], "shift": 3.1}},
        "7": {"class_type": "EmptySD3LatentImage",
              "inputs": {"width": w, "height": h, "batch_size": 1}},
        "8": {"class_type": "KSampler",
              "inputs": {"model": ["15", 0], "positive": ["4", 0], "negative": ["5", 0],
                         "latent_image": ["7", 0], "seed": seed, "steps": STEPS["qwen"],
                         "cfg": 2.5, "sampler_name": "euler", "scheduler": "simple",
                         "denoise": 1.0}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 0]}},
    }, prefix)


def render(model, prompt, seed, guidance, stem, size=(1024, 1024)):
    import gen_fleets as comfy  # connects on import; keep --print offline
    stem.parent.mkdir(parents=True, exist_ok=True)
    if stem.with_suffix(".png").exists() and stem.with_suffix(".json").exists():
        meta = json.loads(stem.with_suffix(".json").read_text())
        if (meta.get("prompt") == prompt and meta.get("seed") == seed
                and meta.get("guidance") == guidance and meta.get("model", "dev") == model):
            return "skip"
    t0 = time.time()
    prefix = "orbitron_factions/" + "_".join(stem.parts[-3:])
    outputs = comfy.run(graph(model, prompt, seed, guidance, prefix, size))
    Path(f"{stem}_rgb.png").write_bytes(comfy.fetch(outputs, "14"))
    stem.with_suffix(".png").write_bytes(comfy.fetch(outputs, "31"))
    stem.with_suffix(".json").write_text(json.dumps(
        {"prompt": prompt, "seed": seed, "guidance": guidance, "steps": STEPS[model],
         "model": model, "checkpoint": FLUX if model == "dev" else QWEN,
         "size": list(size)}, indent=1))
    return f"{time.time() - t0:.0f}s"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pack")
    parser.add_argument("--model", choices=MODELS, default="dev")
    parser.add_argument("--side", help="one side id; default both")
    parser.add_argument("--pieces", default=",".join(PIECES))
    parser.add_argument("--candidates", type=int, default=4)
    parser.add_argument("--guidance", type=float, default=3.5)
    parser.add_argument("--lineup", action="store_true", help="line-up preview per side")
    parser.add_argument("--print", action="store_true", help="print the prompts only")
    args = parser.parse_args()

    styles, packs = load()
    pack = packs.get(args.pack) or sys.exit(f"unknown pack {args.pack}")
    sides = [s for s in pack["sides"] if args.side in (None, s["id"])]
    pieces = args.pieces.split(",")

    def log(msg):
        print(time.strftime("%H:%M:%S"), msg, flush=True)

    for side in sides:
        if args.lineup:
            prompt = lineup_prompt(styles, pack, side)
            if args.print:
                print(f"--- {side['id']} lineup\n{prompt}\n")
                continue
            for i in range(args.candidates):
                stem = (OUT / pack["id"] / args.model / "lineup"
                        / f"{side['id']}_g{round(args.guidance * 10)}_c{i}")
                log(f"lineup {side['id']} c{i}: "
                    f"{render(args.model, prompt, side['seed'] + i, args.guidance, stem, (1536, 1024))}")
            continue
        for piece in pieces:
            prompt = piece_prompt(styles, pack, side, piece)
            if args.print:
                print(f"--- {side['id']} {piece} ({len(prompt.split())} words)\n{prompt}\n")
                continue
            for i in range(args.candidates):
                stem = OUT / pack["id"] / args.model / side["id"] / f"{piece}_c{i}"
                log(f"{side['id']} {piece} c{i}: "
                    f"{render(args.model, prompt, side['seed'] + i, args.guidance, stem)}")


if __name__ == "__main__":
    main()
