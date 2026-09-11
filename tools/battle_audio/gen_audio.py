#!/usr/bin/env python3
"""Generate the battle music and SFX on the SPARK audio service.

One battle theme per attacking unit type, and per element a pistol-like
shot and an echoing explosion. Raw renders go to raw/<name>.ogg with a
.json sidecar (prompt, seed, duration, loudness). A render already there is
skipped: delete it to re-roll, and bump SEED_SALT for fresh seeds.

  python3 gen_audio.py                          # everything missing
  python3 gen_audio.py --only rook_theme,ice_shot
"""
import argparse
import json
import os
import time
import urllib.request
from pathlib import Path

API = os.environ.get("AUDIO_API", "http://192.168.88.66:8093")
HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
SEED_SALT = 0

# Re-rolls per asset, mixed into that asset's seed only: bump one when a
# render comes out unusable, delete raw/<name>.ogg and run again.
REROLLS = {
    # Near-silent renders that post-processing trimmed to nothing, on two
    # seeds; the prompt is reworded too.
    "electric_shot": 2,
}

MUSIC_TAGS = ("space battle arena video game music, [instrumental], seamless loop, "
              "no fade in, no fade out")
# The user's own reference, nearly verbatim: it steers MOSS better than
# acoustic wording.
PISTOL = ("a single pistol gunshot, exactly like firing a handgun, sharp loud crack, "
          "instant attack, hard snap, short decay")
ECHO = ("followed by a long echo that keeps reverberating and rolling away for a long "
        "time, like a blast echoing through a canyon")

# Attacking unit type -> (BPM, style). The BPM also cuts the loop into bars.
THEMES = {
    "pawn": (150, "fast light synthwave, punchy electronic drums, driving arpeggiated "
                  "synth bass, nimble, scrappy, energetic"),
    "knight": (140, "heroic galloping rhythm, pounding toms, bold brass stabs, fast string "
                    "ostinato, adventurous cavalry charge"),
    "bishop": (110, "tense cinematic electronic, sharp plucked synths, pulsing bass, dark "
                    "choir pads, precise, mysterious"),
    "rook": (90, "heavy industrial, slow massive drums, distorted bass, metallic hits, "
                 "grinding, powerful, fortress under siege"),
    "queen": (140, "epic orchestral, soaring fast strings, powerful choir, brass fanfares, "
                   "elegant, fierce"),
    "king": (120, "majestic dark orchestral hybrid, pounding timpani and taiko drums, heavy "
                  "brass fanfare, deep synth bass, cathedral organ, imposing and relentless"),
}
SHOTS = {
    "kinetic": f"{PISTOL}, dry, no music",
    "fire": f"{PISTOL}, with a short fiery flame whoosh, no music",
    "water": f"{PISTOL}, with a short watery splash, no music",
    "ice": f"{PISTOL}, with a short icy crystalline crackle, no music",
    # "with a short electric zap" rendered near-silence on two seeds.
    "electric": "a loud electric discharge crack like a pistol gunshot, exactly like firing a "
                "handgun, sharp loud bang with crackling sparks, instant attack, hard snap, "
                "short decay, no music",
}
EXPLOSIONS = {
    "kinetic": f"a huge explosion blast, loud deep boom with flying metal debris, {ECHO}, no music",
    "fire": f"a huge fiery explosion, loud deep boom and roaring flames, {ECHO}, no music",
    "water": f"a huge water explosion, deep boom bursting into a massive splash and falling "
             f"spray, {ECHO}, no music",
    "ice": f"a huge ice explosion, deep boom shattering ice into cracking crystal shards, "
           f"{ECHO}, no music",
    "electric": f"a huge electric explosion, a thunderclap with crackling lightning arcs, "
                f"{ECHO}, no music",
}


def seed_for(name):
    """Stable seed per asset, so a re-run reproduces the same render."""
    key = f"{name}/{SEED_SALT}"
    if REROLLS.get(name):
        key += f"/reroll{REROLLS[name]}"
    h = 2166136261
    for ch in key:
        h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return h


def jobs():
    for unit, (bpm, style) in THEMES.items():
        yield f"{unit}_theme", "music", {
            "prompt": f"{style}, {MUSIC_TAGS}", "duration_s": 40, "instrumental": True,
            "bpm": bpm, "loop": True, "format": "ogg", "variations": 1}
    for element, prompt in SHOTS.items():
        yield f"{element}_shot", "sfx", {
            "prompt": prompt, "duration_s": 1.2, "mono": True, "format": "ogg", "variations": 1}
    for element, prompt in EXPLOSIONS.items():
        yield f"{element}_explosion", "sfx", {
            "prompt": prompt, "duration_s": 6, "mono": True, "format": "ogg", "variations": 1}


def call(path, body=None, timeout=60):
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"} if data else {}
    request = urllib.request.Request(API + path, data=data, headers=headers)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", default="", help="comma-separated asset names")
    args = parser.parse_args()
    only = set(filter(None, args.only.split(",")))
    RAW.mkdir(exist_ok=True)

    # The service queues jobs itself: submit everything, then collect.
    pending = {}
    for name, kind, body in jobs():
        if only and name not in only:
            continue
        if (RAW / f"{name}.ogg").exists():
            print(f"{name}: skip", flush=True)
            continue
        body["seed"] = seed_for(name)
        job = call(f"/v1/audio/{kind}", body)
        pending[name] = (job["job_id"], body)
        print(f"{name}: queued {job['job_id'][:8]}", flush=True)

    failed = []
    while pending:
        time.sleep(10)
        for name, (job_id, body) in list(pending.items()):
            try:
                status = call(f"/v1/audio/jobs/{job_id}")
            except Exception as error:  # noqa: BLE001 - transient network hiccup
                print(f"{name}: poll failed ({error})", flush=True)
                continue
            if status["status"] in ("queued", "running"):
                continue
            del pending[name]
            outputs = status.get("outputs") or []
            if status["status"] != "done" or not outputs:
                print(f"{name}: {status['status']} {status.get('error')!r}", flush=True)
                failed.append(name)
                continue
            output = outputs[0]
            url = output["url"] if output["url"].startswith("http") else API + output["url"]
            with urllib.request.urlopen(url, timeout=120) as response:
                (RAW / f"{name}.ogg").write_bytes(response.read())
            (RAW / f"{name}.json").write_text(json.dumps({
                "prompt": body["prompt"], "seed": output.get("seed"),
                "duration_s": output.get("duration"), "lufs": output.get("loudness_lufs"),
            }, indent=2))
            print(f"{name}: {output.get('duration')} s, {output.get('loudness_lufs')} LUFS",
                  flush=True)
    print(f"done, failed: {failed or 'none'}")


if __name__ == "__main__":
    main()
