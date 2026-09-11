#!/usr/bin/env python3
"""Cut a bar-aligned seamless loop out of a generated music track.

Keeps whole phrases from bar 1 to the last phrase boundary and joins the
loop's end to its start with a short crossfade (temp files, not
asplit+acrossfade, which silently drops the fade). Generated tracks repeat
in phrases, so cutting on phrase boundaries keeps the seam musical.

  python3 make_loop.py in.ogg out.ogg --bpm 120 [--beats-per-bar 4]
"""
import argparse, re, subprocess, tempfile
from pathlib import Path

WINDOW_S = 0.5
XFADE_S = 0.12

def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True)

def rms_windows(path, sample_rate=44100):
    n = int(sample_rate * WINDOW_S)
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af",
         f"aresample={sample_rate},asetnsamples={n},astats=metadata=1:reset=1,"
         "ametadata=print:key=lavfi.astats.Overall.RMS_level", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    levels = []
    for m in re.finditer(r"RMS_level=(-?[0-9.]+|-inf)", out):
        v = m.group(1)
        levels.append(-120.0 if v == "-inf" else float(v))
    return levels

def codec_args(dst):
    """Encoder for the output's extension; OGG needs an ffmpeg with libvorbis."""
    return {
        ".wav": ["-c:a", "pcm_s16le"],
        ".m4a": ["-c:a", "aac", "-b:a", "192k"],
    }.get(dst.suffix, ["-c:a", "libvorbis", "-q:a", "6"])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("dst", type=Path)
    ap.add_argument("--bpm", type=float, required=True)
    ap.add_argument("--beats-per-bar", type=int, default=4)
    ap.add_argument("--phrase-bars", type=int, default=4)
    args = ap.parse_args()

    bar_s = 60.0 / args.bpm * args.beats_per_bar
    levels = rms_windows(args.src)
    duration = len(levels) * WINDOW_S
    # Whole phrases from bar 1: bar 0 carries the service's loop crossfade
    # and the model's soft entry. The loop ends on the last phrase boundary
    # that still leaves audio for the seam crossfade.
    phrase = args.phrase_bars
    last_bar = int((duration - XFADE_S) // bar_s)
    phrases = (last_bar - 1) // phrase
    if phrases < 1:
        raise SystemExit(f"track too short for one {phrase}-bar phrase")
    best = (1, 1 + phrases * phrase)
    loud = max(levels)
    t0, t1 = best[0] * bar_s, best[1] * bar_s
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        cut = lambda name, ss, t: run("ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
                                       "-ss", f"{ss}", "-t", f"{t}", "-i", str(args.src),
                                       "-ar", "44100", "-ac", "2", str(tmp / name))
        cut("head.wav", t0, XFADE_S)
        cut("post.wav", t1, XFADE_S)
        cut("mid.wav", t0 + XFADE_S, t1 - t0 - XFADE_S)
        run("ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
            "-i", str(tmp / "head.wav"), "-i", str(tmp / "post.wav"), "-filter_complex",
            f"[0]afade=t=in:d={XFADE_S}[a];[1]afade=t=out:d={XFADE_S}[b];"
            "[a][b]amix=inputs=2:normalize=0", str(tmp / "seam.wav"))
        # The concat filter, not the demuxer: amix leaves the seam in float
        # samples and the demuxer refuses to join it to the s16 cut.
        run("ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
            "-i", str(tmp / "seam.wav"), "-i", str(tmp / "mid.wav"), "-filter_complex",
            "[0][1]concat=n=2:v=0:a=1", *codec_args(args.dst), str(args.dst))
    print(f"{args.src.name}: loud {loud:.1f} dB, bars {best[0]}..{best[1]} "
          f"({t0:.2f}-{t1:.2f} s of {duration:.1f} s) -> {args.dst.name}")

if __name__ == "__main__":
    main()
