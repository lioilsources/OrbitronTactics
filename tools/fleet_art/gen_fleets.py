#!/usr/bin/env python3
"""Generate OrbitronTactics fleet ship sprites on comfyui.ol1n.com (SPARK).

For every fleet and unit:
  white: FLUX.1-dev txt2img on a flat gray ground -> RMBG-2.0 cutout
  black: FLUX Kontext repaint of the white render    -> RMBG-2.0 cutout

Every sprite passes a gate or is re-rolled with a new seed: a white ship must
be left-right symmetric (top-down, bow up), a black ship clearly darker than
its white twin. Sprites already on disk are re-checked too.

One job in flight at a time (SPARK's memory is shared). A job left on the
server by a killed client is adopted instead of queued twice, so an
interrupted run just resumes.

  python3 gen_fleets.py --fleets vanguard
  python3 gen_fleets.py --fleets all
  python3 gen_fleets.py --audit          # check sprites on disk, render nothing
"""
import argparse
import hashlib
import io
import json
import os
import re
import shutil
import sys
import time
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

from PIL import Image, ImageChops, ImageOps, ImageStat

from fleets import FLEETS, UNITS, black_prompt, seed_for, white_prompt

API = os.environ.get("COMFY_URL", "https://comfyui.ol1n.com")
# Cloudflare Access service token: CF_ID / CF_SECRET, else the
# cfAccessClientId / cfAccessClientSecret constants of this Dart file.
SECRETS = Path(os.environ.get("CF_SECRETS_FILE",
                              "/Volumes/YOTTA/Dev/MangaPrompts/lib/config/secrets.dart"))
HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
BAD = HERE / "out_bad"

FLUX = "flux1-dev.safetensors"
KONTEXT = "flux1-dev-kontext_fp8_scaled.safetensors"
SIZE = (1024, 1024)
STEPS = 24

# FLUX runs at cfg 1, where a plain negative prompt does nothing and "no
# shadow" reads as shadow. NAG gives the negatives teeth; the pilot render
# otherwise sat on the gray ground with a cast shadow RMBG half kept.
NEGATIVE = ("shadow, drop shadow, cast shadow, ground, floor, surface, text, letters, "
            "watermark, logo, frame, border")

# Gates, calibrated on the first 34 sprites. Mirror IoU of the white cutout:
# top-down ships scored 0.962-0.996, the diagonal / 3/4-view Void Hive bishop,
# queen and rook 0.05-0.56. Black-to-white mean luminance: good pairs
# 0.27-0.58, the washed-out Solar Crusade king 0.65.
SYMMETRY_MIN = 0.90
DARKNESS_MAX = 0.60
ATTEMPTS = {"white": 4, "black": 3}


def _credentials():
    cf_id = os.environ.get("CF_ID")
    cf_secret = os.environ.get("CF_SECRET")
    if cf_id and cf_secret:
        return cf_id, cf_secret
    text = SECRETS.read_text()

    def const(name):
        m = re.search(name + r"\s*=\s*'([^']*)'", text, re.S)
        if not m:
            sys.exit(f"cannot read {name} from {SECRETS}")
        return m.group(1)

    return const("cfAccessClientId"), const("cfAccessClientSecret")


CF_ID, CF_SECRET = _credentials()
HEADERS = {
    "CF-Access-Client-Id": CF_ID,
    "CF-Access-Client-Secret": CF_SECRET,
    "User-Agent": "orbitron-fleets/1.0",
}


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


# --------------------------------------------------------------------- API --
def api(path, payload=None, timeout=60):
    headers = dict(HEADERS)
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    req = urllib.request.Request(API + path, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        body = r.read()
        return json.loads(body) if body else {}


def upload(path, name):
    """Upload [path] to ComfyUI's input folder as [name]."""
    boundary = uuid.uuid4().hex
    body = io.BytesIO()
    for field, value in (("overwrite", "true"), ("type", "input")):
        body.write(f"--{boundary}\r\nContent-Disposition: form-data; "
                   f"name=\"{field}\"\r\n\r\n{value}\r\n".encode())
    body.write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; "
               f"filename=\"{name}\"\r\nContent-Type: image/png\r\n\r\n".encode())
    body.write(path.read_bytes())
    body.write(f"\r\n--{boundary}--\r\n".encode())
    headers = dict(HEADERS, **{"Content-Type": f"multipart/form-data; boundary={boundary}"})
    req = urllib.request.Request(API + "/upload/image", data=body.getvalue(), headers=headers)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())["name"]


def _signature(graph):
    """What makes two jobs the same render: output prefix, both prompts, the
    seed and, for a repaint, the reference image. The reference name carries
    a content hash — without it a re-rendered white ship matched the black
    repaint of the ship it replaced — and without the seed a re-roll would
    just reuse the render the gate rejected."""
    return (graph["14"]["inputs"]["filename_prefix"],
            graph["4"]["inputs"]["text"],
            graph["5"]["inputs"].get("text"),
            graph["8"]["inputs"]["seed"],
            graph.get("20", {}).get("inputs", {}).get("image"))


def find_existing(graph):
    """A job for this exact render left behind by a killed client:
    (pid, outputs) if it finished, (pid, None) if still queued, else (None, None)."""
    wanted = _signature(graph)

    def matches(stored):
        try:
            return _signature(stored) == wanted
        except (KeyError, TypeError, AttributeError):
            return False

    queue = api("/queue")
    for entry in queue.get("queue_running", []) + queue.get("queue_pending", []):
        if matches(entry[2]):
            return entry[1], None
    for pid, entry in api("/history?max_items=200").items():
        if (matches(entry["prompt"][2])
                and entry.get("status", {}).get("status_str") == "success"
                and entry.get("outputs")):
            return pid, entry["outputs"]
    return None, None


def run(graph, timeout=3600):
    """Run [graph] — or adopt an identical job already on the server — and
    return its outputs by node id."""
    pid, outputs = find_existing(graph)
    if outputs is not None:
        log(f"  reusing finished job {pid[:8]}")
        return outputs
    if pid:
        log(f"  adopting queued job {pid[:8]}")
    else:
        pid = api("/prompt", {"prompt": graph, "client_id": "orbitron-fleets"})["prompt_id"]
    t0 = time.time()
    retries = 2
    while time.time() - t0 < timeout:
        time.sleep(3)
        try:
            hist = api(f"/history/{pid}")
        except Exception as e:  # noqa: BLE001 - transient network hiccup
            log(f"  (poll failed: {e})")
            continue
        entry = hist.get(pid)
        if not entry:
            continue
        status = entry.get("status", {})
        if status.get("status_str") == "error":
            kinds = [m[0] for m in status.get("messages", [])]
            if "execution_interrupted" in kinds and retries > 0:
                # SPARK is shared: another client's /interrupt stops whatever
                # is running, which may be this job. Queue it again.
                retries -= 1
                log(f"  job {pid[:8]} was interrupted by another client, re-queueing")
                pid = api("/prompt", {"prompt": graph,
                                      "client_id": "orbitron-fleets"})["prompt_id"]
                continue
            msgs = [m for m in status.get("messages", []) if m[0] == "execution_error"]
            detail = msgs[0][1].get("exception_message", "") if msgs else ""
            raise RuntimeError(f"ComfyUI job failed ({', '.join(kinds)}): {detail[:600]}")
        if entry.get("outputs"):
            return entry["outputs"]
    raise TimeoutError(f"job {pid} did not finish in {timeout}s")


def fetch(outputs, node):
    info = outputs[node]["images"][0]
    q = urllib.parse.urlencode({"filename": info["filename"],
                                "subfolder": info.get("subfolder", ""),
                                "type": info.get("type", "output")})
    req = urllib.request.Request(f"{API}/view?{q}", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


# ------------------------------------------------------------------ graphs --
def ship_graph(prompt, seed, prefix, ref=None):
    """FLUX txt2img, or a Kontext edit of [ref]; saves the raw render (14)
    and the RMBG-2.0 cutout with alpha (31)."""
    w, h = SIZE
    g = {
        "1": {"class_type": "UNETLoader",
              "inputs": {"unet_name": KONTEXT if ref else FLUX,
                         "weight_dtype": "default" if ref else "fp8_e4m3fn"}},
        "2": {"class_type": "DualCLIPLoader",
              "inputs": {"clip_name1": "t5xxl_fp16.safetensors",
                         "clip_name2": "clip_l.safetensors", "type": "flux"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": NEGATIVE}},
        "6": {"class_type": "FluxGuidance",
              "inputs": {"conditioning": ["4", 0], "guidance": 2.5 if ref else 3.5}},
        "7": {"class_type": "EmptySD3LatentImage",
              "inputs": {"width": w, "height": h, "batch_size": 1}},
        "15": {"class_type": "NAGuidance",
               "inputs": {"model": ["1", 0], "nag_scale": 5.0, "nag_alpha": 0.5,
                          "nag_tau": 1.5}},
        "8": {"class_type": "KSampler",
              "inputs": {"model": ["15", 0], "positive": ["6", 0], "negative": ["5", 0],
                         "latent_image": ["7", 0], "seed": seed, "steps": STEPS,
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
    if ref:
        g["20"] = {"class_type": "LoadImage", "inputs": {"image": ref}}
        g["21"] = {"class_type": "FluxKontextImageScale", "inputs": {"image": ["20", 0]}}
        g["22"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["21", 0], "vae": ["3", 0]}}
        g["23"] = {"class_type": "ReferenceLatent",
                   "inputs": {"conditioning": ["6", 0], "latent": ["22", 0]}}
        g["8"]["inputs"]["positive"] = ["23", 0]
    return g


# ------------------------------------------------------------------- gates --
def _paths(folder, unit, color):
    return folder / f"{unit}_{color}.png", folder / f"{unit}_{color}_rgb.png"


def _solid(image):
    return image.getchannel("A").point(lambda a: 255 if a > 128 else 0)


def mirror_iou(path):
    """Overlap of the ship's silhouette with its own left-right mirror image."""
    mask = _solid(Image.open(path).convert("RGBA"))
    box = mask.getbbox()
    if box is None:
        return 0.0
    crop = mask.crop(box)
    mirrored = ImageOps.mirror(crop)
    inter = ImageChops.multiply(crop, mirrored).histogram()[255]
    union = ImageChops.lighter(crop, mirrored).histogram()[255]
    return inter / union if union else 0.0


def mean_luma(path):
    image = Image.open(path).convert("RGBA")
    return ImageStat.Stat(image.convert("L"), mask=_solid(image)).mean[0]


def gate(folder, unit, color):
    """(score, failure) for a sprite on disk; higher scores are better and
    failure is None when the sprite passes."""
    cutout = folder / f"{unit}_{color}.png"
    if color == "white":
        iou = mirror_iou(cutout)
        return iou, None if iou >= SYMMETRY_MIN else f"mirror IoU {iou:.2f} < {SYMMETRY_MIN}"
    ratio = mean_luma(cutout) / mean_luma(folder / f"{unit}_white.png")
    return -ratio, None if ratio <= DARKNESS_MAX else f"darkness {ratio:.2f} > {DARKNESS_MAX}"


def set_aside(folder, unit, color, tag):
    """Move a sprite pair out of [folder] into out_bad/, returning its new paths."""
    dest = BAD / folder.name
    dest.mkdir(parents=True, exist_ok=True)
    moved = []
    for path in _paths(folder, unit, color):
        target = dest / path.name.replace(f"{unit}_{color}", f"{unit}_{color}_{tag}")
        shutil.move(str(path), target)
        moved.append(target)
    return moved


# -------------------------------------------------------------------- main --
def render_once(fleet, unit, color, attempt):
    slug = fleet[0]
    folder = OUT / slug
    cutout, raw = _paths(folder, unit, color)
    prefix = f"orbitron_fleets/{slug}_{unit}_{color}"
    # rerolls.json ({"fleet/unit": n}) moves a ship to a fresh seed after a
    # manual review rejects a render the gates passed, such as a symmetric
    # ship whose bow points down. Without it the rejected render is reused.
    rerolls_file = HERE / "rerolls.json"
    rerolls = json.loads(rerolls_file.read_text()) if rerolls_file.exists() else {}
    seed = (seed_for(slug, unit) + attempt * 7919
            + rerolls.get(f"{slug}/{unit}", 0) * 104729) % (1 << 32)
    if color == "white":
        graph = ship_graph(white_prompt(fleet, unit), seed, prefix)
    else:
        white_raw = folder / f"{unit}_white_rgb.png"
        if not white_raw.exists():
            raise RuntimeError(f"{slug}/{unit}: white render missing, cannot repaint")
        digest = hashlib.sha1(white_raw.read_bytes()).hexdigest()[:12]
        ref = upload(white_raw, f"orbitron_{slug}_{unit}_white_{digest}.png")
        graph = ship_graph(black_prompt(fleet, unit, attempt), seed, prefix, ref=ref)
    outputs = run(graph)
    raw.write_bytes(fetch(outputs, "14"))
    cutout.write_bytes(fetch(outputs, "31"))


def render(fleet, unit, color):
    slug = fleet[0]
    folder = OUT / slug
    folder.mkdir(parents=True, exist_ok=True)
    cutout, raw = _paths(folder, unit, color)
    stamp = time.strftime("%H%M%S")
    if cutout.exists() and raw.exists():
        _, failure = gate(folder, unit, color)
        if failure is None:
            return "skip"
        log(f"  on-disk sprite fails the gate ({failure}), re-rendering")
        set_aside(folder, unit, color, f"rejected{stamp}")
    if color == "white" and all(p.exists() for p in _paths(folder, unit, "black")):
        # A new white ship is about to be rendered, so a black repaint still
        # on disk belongs to a ship that no longer exists — one the gate just
        # rejected, or a white render moved aside by hand.
        set_aside(folder, unit, "black", f"orphaned{stamp}")

    t0 = time.time()
    tries = []
    for attempt in range(ATTEMPTS[color]):
        render_once(fleet, unit, color, attempt)
        score, failure = gate(folder, unit, color)
        if failure is None:
            note = f", attempt {attempt + 1}" if attempt else ""
            return f"{time.time() - t0:.0f}s{note}"
        log(f"  attempt {attempt + 1} fails the gate ({failure})")
        tries.append((score, set_aside(folder, unit, color, f"try{attempt}{stamp}")))

    score, (best_cutout, best_raw) = max(tries, key=lambda t: t[0])
    shutil.copy(best_cutout, cutout)
    shutil.copy(best_raw, raw)
    return f"{time.time() - t0:.0f}s, no attempt passed — kept the best (score {score:.2f}), REVIEW"


def audit(fleets, units):
    for fleet in fleets:
        folder = OUT / fleet[0]
        for unit in units:
            for color in ("white", "black"):
                if not (folder / f"{unit}_{color}.png").exists():
                    continue
                score, failure = gate(folder, unit, color)
                print(f"{fleet[0]:15} {unit:7} {color:5} {'FAIL ' + failure if failure else 'ok'}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fleets", default="all",
                        help="comma-separated fleet slugs, or 'all'")
    parser.add_argument("--units", default="all",
                        help="comma-separated unit types, or 'all'")
    parser.add_argument("--audit", action="store_true",
                        help="only report which sprites on disk fail a gate")
    args = parser.parse_args()

    fleets = FLEETS if args.fleets == "all" else [
        f for f in FLEETS if f[0] in args.fleets.split(",")]
    units = list(UNITS) if args.units == "all" else args.units.split(",")
    if not fleets:
        sys.exit(f"no fleet matches {args.fleets}")
    if args.audit:
        audit(fleets, units)
        return

    failures = []
    for fleet in fleets:
        for unit in units:
            for color in ("white", "black"):
                name = f"{fleet[0]}/{unit}_{color}"
                try:
                    log(f"{name}: {render(fleet, unit, color)}")
                except Exception as e:  # noqa: BLE001 - keep the batch going
                    log(f"{name}: FAILED {e}")
                    failures.append(name)
    log(f"done, {len(failures)} failed: {failures}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
