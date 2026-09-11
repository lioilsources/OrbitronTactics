# Battle audio

Generates the battle's music and sound effects in `assets/audio/`: a theme per attacking unit type, and per element a pistol-like shot and an explosion with a long echo. Rendering runs on the AiStack audio service on SPARK (ACE-Step 1.5 for music, MOSS-SoundEffect v2 for effects).

| File | What it does |
|------|--------------|
| `gen_audio.py` | Prompts, seeds and re-rolls; renders every missing asset into `raw/` with a JSON sidecar |
| `build_audio.py` | Loops the themes, adds the echo to explosions, encodes Vorbis and writes `assets/audio/` |
| `make_loop.py` | Cuts a generated track into whole phrases and joins the loop's ends |

## Requirements

- Python 3 and ffmpeg on the Mac. Homebrew's ffmpeg has no libvorbis, so the final encoding runs in the `ai-audio` container on SPARK.
- `ssh spark` and the audio service at `http://192.168.88.66:8093` (`AUDIO_API` overrides it).

## Workflow

```bash
cd tools/battle_audio
python3 gen_audio.py      # renders whatever raw/ is missing
python3 build_audio.py    # writes assets/audio/music and assets/audio/sfx
```

Listen before committing. To re-roll one asset, bump its count in `REROLLS`, delete `raw/<name>.ogg` and run both scripts again; every other asset keeps its seed. A changed prompt also needs its raw render deleted.

## Sound design

- **Music:** the attacker's type picks the theme; `THEMES` holds each style and BPM. ACE-Step builds its tracks in 4-bar phrases, and `make_loop.py` keeps whole phrases from bar 1, so the seam falls where the music repeats anyway. The service's own loop leaves a soft head that dropped the level by about 6 dB at every pass.
- **Shots:** the reference "like firing a pistol" goes into the prompt nearly verbatim; the element adds a short flavour.
- **Explosions:** MOSS cuts effects hard at `duration_s`, so the long echo is added here (`aecho`, four repeats 0.3–2 s apart, then a 3 s fade). In the game an impact plays only its first 450 ms; a destroyed ship gets the whole tail.

## Gotchas

- `variations` above 1 returns practically identical audio; different renders need different seeds.
- A render that post-processing trims to nothing fails with `ffprobe nevrátil délku`. Re-roll it; if the same prompt fails again, reword it.
- The first music job after the container starts spends about 8 minutes loading weights; the first effect compiles for about a minute.
