#!/usr/bin/env python3
"""Turn the raw renders into the game's audio assets.

  music/<unit>.ogg              the theme cut to whole phrases, looped seamlessly
  sfx/<element>_shot.ogg        as rendered (the service trims and normalises)
  sfx/<element>_explosion.ogg   with a long echo tail, faded out, peak at -1 dB

The Mac's ffmpeg has no libvorbis, so Vorbis encoding runs in the ai-audio
container on SPARK: WAV in on stdin, OGG out on stdout.

  python3 build_audio.py [--dest ../../assets/audio]
"""
import argparse
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from gen_audio import EXPLOSIONS, SHOTS, THEMES

HERE = Path(__file__).resolve().parent
RAW = HERE / "raw"
ASSETS = HERE.parents[1] / "assets" / "audio"
SPARK = ["ssh", "-o", "BatchMode=yes", "spark"]
QUALITY = 5

# Four repeats 0.3-2 s apart, each quieter, with 4 s of room for them.
ECHO = "apad=pad_dur=4,aecho=0.8:0.85:300|650|1200|2000:0.5|0.36|0.26|0.17"
ECHO_FADE_S = 3.0


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", *map(str, args)],
                   check=True)


def duration_s(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(path)], capture_output=True, text=True, check=True)
    return float(out.stdout)


def peak_db(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af",
                          "volumedetect", "-f", "null", "-"], capture_output=True, text=True)
    return float(re.search(r"max_volume: (-?[0-9.]+) dB", out.stderr).group(1))


def encode_vorbis(wav, dst):
    remote = (f"docker exec -i ai-audio ffmpeg -hide_banner -loglevel error -f wav -i pipe:0 "
              f"-c:a libvorbis -q:a {QUALITY} -f ogg pipe:1")
    with open(wav, "rb") as source, open(dst, "wb") as target:
        subprocess.run([*SPARK, remote], stdin=source, stdout=target, check=True)


def build_theme(unit, bpm, dst, tmp):
    wav = tmp / f"{unit}_loop.wav"
    subprocess.run(["python3", str(HERE / "make_loop.py"), str(RAW / f"{unit}_theme.ogg"),
                    str(wav), "--bpm", str(bpm)], check=True)
    encode_vorbis(wav, dst)


def build_explosion(element, dst, tmp):
    src = RAW / f"{element}_explosion.ogg"
    body = duration_s(src)
    echoed = tmp / f"{element}_echo.wav"
    ffmpeg("-i", src, "-af",
           f"{ECHO},afade=t=out:st={body + 1:.2f}:d={ECHO_FADE_S},"
           f"atrim=end={body + 1 + ECHO_FADE_S + 0.05:.2f}",
           "-ar", 44100, "-ac", 1, echoed)
    gain = -1 - peak_db(echoed)
    level = tmp / f"{element}_explosion.wav"
    ffmpeg("-i", echoed, "-af", f"volume={gain:.1f}dB", "-c:a", "pcm_s16le", level)
    encode_vorbis(level, dst)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dest", type=Path, default=ASSETS)
    args = parser.parse_args()
    music_dir = args.dest / "music"
    sfx_dir = args.dest / "sfx"
    music_dir.mkdir(parents=True, exist_ok=True)
    sfx_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for unit, (bpm, _) in THEMES.items():
            build_theme(unit, bpm, music_dir / f"{unit}.ogg", tmp)
        for element in SHOTS:
            shutil.copyfile(RAW / f"{element}_shot.ogg", sfx_dir / f"{element}_shot.ogg")
        for element in EXPLOSIONS:
            build_explosion(element, sfx_dir / f"{element}_explosion.ogg", tmp)

    for path in sorted(args.dest.rglob("*.ogg")):
        print(f"{path.relative_to(args.dest)}: {duration_s(path):.2f} s, "
              f"{path.stat().st_size / 1024:.0f} KB, peak {peak_db(path):.1f} dB")


if __name__ == "__main__":
    main()
