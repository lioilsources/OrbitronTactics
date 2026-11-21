#!/usr/bin/env python3
"""Render the Retro Arcade music pack: an 8-bit take on every battle theme.

Unlike gen_audio.py this needs no audio service: pulse waves, a triangle
bass and noise drums are synthesized here with numpy, the way a 1980s
console sound chip would, and written straight to
assets/audio/music_retro/<unit>.ogg. Each theme keeps the tempo and the
mood of its unit's main theme and loops seamlessly: notes ringing past the
last bar wrap round to the first.

  python3 chiptune.py               # every theme
  python3 chiptune.py --only rook   # one theme
  python3 chiptune.py --wav         # also keep the WAVs in raw_retro/

Needs numpy and ffmpeg with libvorbis. A seed per theme makes every run
reproduce the same melodies.
"""
import argparse
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
OUT = HERE.parent.parent / "assets" / "audio" / "music_retro"
RAW = HERE / "raw_retro"
RATE = 44100
QUALITY = 5          # same Vorbis quality as build_audio.py
TARGET_LUFS = -16.0  # the main themes sit at -15 to -16.5

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
        "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10,
        "Bb": 10, "B": 11}
MINOR = [0, 2, 3, 5, 7, 8, 10]
HARMONIC = [0, 2, 3, 5, 7, 8, 11]


def midi(name, octave):
    return 12 * (octave + 1) + NOTE[name]


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


# ---------------------------------------------------------------- voices

def _blep(t, dt):
    """PolyBLEP: rounds off a step so it does not alias."""
    out = np.zeros_like(t)
    lo = t < dt
    x = t[lo] / dt[lo]
    out[lo] = x + x - x * x - 1
    hi = t > 1 - dt
    x = (t[hi] - 1) / dt[hi]
    out[hi] = x * x + x + x + 1
    return out


def pulse(freq, n, duty, vibrato=0.0, t0=0.0):
    """A band-limited pulse wave, centred on zero like the chip's output
    after its coupling capacitor."""
    t = (np.arange(n) / RATE) + t0
    f = freq * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 3, 0, 1))
    dt = f / RATE
    phase = np.cumsum(dt) % 1.0
    wave = np.where(phase < duty, 1.0, -1.0)
    wave += _blep(phase, dt)
    wave -= _blep((phase + 1 - duty) % 1.0, dt)
    return wave - (2 * duty - 1)


def triangle(freq, n):
    phase = (np.arange(n) * freq / RATE) % 1.0
    tri = 4 * np.abs(phase - 0.5) - 1
    return np.round(tri * 7.5) / 7.5  # the chip's 4-bit staircase


def envelope(n, attack=0.004, decay=0.08, sustain=0.6, release=0.03):
    env = np.full(n, sustain)
    a = min(n, int(attack * RATE))
    d = min(n - a, int(decay * RATE))
    r = min(n, int(release * RATE))
    env[:a] = np.linspace(0, 1, a, endpoint=False)
    env[a:a + d] = np.linspace(1, sustain, d, endpoint=False)
    if r:
        env[n - r:] *= np.linspace(1, 0, r)
    return env


class Noise:
    """The chip's noise channel: a 15-bit LFSR, fed at a chosen rate."""

    def __init__(self):
        reg = 1
        out = np.empty(32767)
        for i in range(32767):
            bit = (reg ^ (reg >> 1)) & 1
            reg = (reg >> 1) | (bit << 14)
            out[i] = 1.0 if reg & 1 else -1.0
        self.table = out

    def render(self, n, rate):
        idx = (np.arange(n) * rate / RATE).astype(int) % len(self.table)
        return self.table[idx]


NOISE = Noise()


def kick(n):
    t = np.arange(n) / RATE
    f = 140 * np.exp(-t * 28) + 42
    body = np.sin(2 * np.pi * np.cumsum(f) / RATE)
    return body * np.exp(-t * 11)


def snare(n):
    t = np.arange(n) / RATE
    tone = triangle(190, n) * np.exp(-t * 30) * 0.5
    return (NOISE.render(n, 18000) * np.exp(-t * 16) + tone) * 0.8


def hat(n, open_=False):
    t = np.arange(n) / RATE
    noise = NOISE.render(n, 44100)
    noise = np.diff(noise, prepend=0) * 0.5  # crude high-pass
    return noise * np.exp(-t * (14 if open_ else 60)) * 0.6


def tom(n, freq):
    t = np.arange(n) / RATE
    f = freq * (1 + 0.6 * np.exp(-t * 20))
    square = np.sign(np.sin(2 * np.pi * np.cumsum(f) / RATE))
    return square * np.exp(-t * 9) * 0.7


# ---------------------------------------------------------------- score

class Theme:
    def __init__(self, unit, bpm, bars, root, octave, scale, chords, seed,
                 lead_duty, arp_duty, bass_style, drum_style, lead_rhythm,
                 arp_rate=16, swing=0.0):
        self.unit, self.bpm, self.bars = unit, bpm, bars
        self.root = midi(root, octave)
        self.scale, self.chords, self.seed = scale, chords, seed
        self.lead_duty, self.arp_duty = lead_duty, arp_duty
        self.bass_style, self.drum_style = bass_style, drum_style
        self.lead_rhythm, self.arp_rate, self.swing = lead_rhythm, arp_rate, swing

    @property
    def beat(self):
        return 60.0 / self.bpm

    @property
    def length(self):
        return int(round(self.bars * 4 * self.beat * RATE))


def degree(theme, d):
    """Scale degree d (0-based, may exceed 6) as a midi note offset."""
    octave, step = divmod(d, 7)
    return 12 * octave + theme.scale[step]


def chord_tones(theme, chord):
    return [degree(theme, chord + k) for k in (0, 2, 4)]


class Mix:
    def __init__(self, theme):
        self.theme = theme
        tail = int(2.0 * RATE)
        self.left = np.zeros(theme.length + tail)
        self.right = np.zeros(theme.length + tail)

    def add(self, start_s, signal, gain=1.0, pan=0.0, echo=0.0):
        start = int(round(start_s * RATE))
        for delay_s, fade in ([(0, 1.0)] + ([(self.theme.beat * 0.75, echo),
                                             (self.theme.beat * 1.5, echo * 0.5)]
                                            if echo else [])):
            s = start + int(delay_s * RATE)
            e = min(len(self.left), s + len(signal))
            if s >= len(self.left):
                continue
            chunk = signal[:e - s] * gain * fade
            # An echo answers from the other side.
            p = pan if delay_s == 0 else -pan
            self.left[s:e] += chunk * (1 - p) * 0.5 ** 0.5 * 1.2
            self.right[s:e] += chunk * (1 + p) * 0.5 ** 0.5 * 1.2

    def looped(self):
        n = self.theme.length
        left, right = self.left[:n].copy(), self.right[:n].copy()
        left[:len(self.left) - n] += self.left[n:]
        right[:len(self.right) - n] += self.right[n:]
        return np.stack([left, right], axis=1)


def write_drums(theme, mix):
    beat = theme.beat
    style = theme.drum_style
    for bar in range(theme.bars):
        t0 = bar * 4 * beat
        fill = bar % 4 == 3
        for step in range(16):
            t = t0 + step * beat / 4
            if theme.swing and step % 2:
                t += theme.swing * beat / 4
            k = s = h = False
            if style == "drive":      # four on the floor, backbeat, 16th hats
                k = step % 4 == 0
                s = step in (4, 12)
                h = True
            elif style == "gallop":   # da-da-dum
                k = step in (0, 3, 6, 8, 11, 14)
                s = step in (4, 12)
                h = step % 2 == 0
            elif style == "halftime":
                k = step in (0, 10)
                s = step == 8
                h = step % 2 == 0
            elif style == "siege":    # slow and heavy
                k = step in (0, 3, 8, 11)
                s = step in (4, 12)
                h = step % 4 == 2
            elif style == "march":
                k = step in (0, 8)
                s = step in (4, 12) or (fill and step in (13, 14, 15))
                h = step % 2 == 0
            if fill and step >= 12 and style != "march":
                s = s or step % 2 == 0
            if k:
                mix.add(t, kick(int(0.35 * RATE)), 0.9)
            if s:
                mix.add(t, snare(int(0.25 * RATE)), 0.5)
            if h:
                mix.add(t, hat(int(0.08 * RATE), open_=step % 8 == 6), 0.14,
                        pan=0.45)
        if style in ("siege", "march") and fill:
            for i, f in enumerate((180, 140, 110, 85)):
                mix.add(t0 + (3 + i * 0.25) * beat, tom(int(0.3 * RATE), f), 0.45)


def write_bass(theme, mix):
    beat = theme.beat
    per_bar = len(theme.chords)
    for bar in range(theme.bars):
        chord = theme.chords[bar % per_bar]
        root = theme.root - 12 + degree(theme, chord)
        while root > theme.root - 5:
            root -= 12
        t0 = bar * 4 * beat
        if theme.bass_style == "octaves":     # 8ths jumping the octave
            notes = [(i * beat / 2, root + (12 if i % 2 else 0), beat / 2)
                     for i in range(8)]
        elif theme.bass_style == "gallop":
            notes = []
            for b in range(4):
                for off, ln in ((0, 0.5), (0.5, 0.25), (0.75, 0.25)):
                    notes.append(((b + off) * beat, root, ln * beat))
        elif theme.bass_style == "pulse":     # quarter notes, fifth on 3
            notes = [(b * beat, root + (7 if b == 2 else 0), beat * 0.9)
                     for b in range(4)]
        elif theme.bass_style == "heavy":     # long roots with a push
            notes = [(0, root, beat * 1.5), (1.5 * beat, root, beat * 0.5),
                     (2 * beat, root, beat * 1.5), (3.5 * beat, root + 7, beat * 0.5)]
        else:                                  # "walk"
            notes = [(b * beat, root + [0, 7, 12, 7][b], beat * 0.95)
                     for b in range(4)]
        for start, note, length in notes:
            n = int(length * RATE)
            sig = triangle(hz(note), n) * envelope(n, decay=0.02, sustain=0.9,
                                                    release=0.01)
            mix.add(t0 + start, sig, 0.55)


def write_arp(theme, mix):
    beat = theme.beat
    step = beat * 4 / theme.arp_rate
    per_bar = len(theme.chords)
    for bar in range(theme.bars):
        tones = chord_tones(theme, theme.chords[bar % per_bar])
        pattern = tones + [tones[0] + 12]
        t0 = bar * 4 * beat
        for i in range(theme.arp_rate):
            note = theme.root + pattern[i % len(pattern)]
            n = int(step * RATE * 0.95)
            sig = pulse(hz(note), n, theme.arp_duty) * envelope(
                n, decay=0.05, sustain=0.35, release=0.01)
            mix.add(t0 + i * step, sig, 0.11, pan=0.6)


def melody(theme):
    """A 4-bar motif, varied, contrasted and brought back: A A' B A."""
    rng = np.random.default_rng(theme.seed)
    per_bar = len(theme.chords)
    rhythms = theme.lead_rhythm

    def phrase(first_bar, variant):
        notes = []
        last = 7  # the octave above the root
        for b in range(4):
            bar = first_bar + b
            chord = theme.chords[bar % per_bar]
            rhythm = rhythms[(b + variant) % len(rhythms)]
            pos = 0.0
            for i, ln in enumerate(rhythm):
                if ln < 0:      # a rest
                    pos += -ln
                    continue
                tones = [chord + k for k in (0, 2, 4, 7)]
                if i == 0 or rng.random() < 0.6:
                    # Chord tones near the last note, on the strong beats.
                    d = min(tones, key=lambda x: abs(x - last) + rng.random() * 2.5)
                else:
                    d = last + rng.choice([-1, 1, -2, 2])
                d = int(np.clip(d, 2, 12))
                notes.append((bar * 4 + pos, d, ln))
                last = d
                pos += ln
        return notes

    a = phrase(0, 0)
    a2 = [(t + 16, d + (1 if i == len(a) - 1 else 0), ln)
          for i, (t, d, ln) in enumerate(a)]
    b = phrase(8, 1)
    out = a + a2 + b + [(t + 12 * 4 - 0, d, ln) for (t, d, ln) in a]
    return [(t, d, ln) for (t, d, ln) in out if t < theme.bars * 4]


def write_lead(theme, mix):
    beat = theme.beat
    for t, d, ln in melody(theme):
        note = theme.root + degree(theme, d)
        n = int(ln * beat * RATE * 0.92)
        sig = pulse(hz(note), n, theme.lead_duty, vibrato=0.006) * envelope(
            n, attack=0.003, decay=0.12, sustain=0.7, release=0.04)
        mix.add(t * beat, sig, 0.2, pan=-0.4, echo=0.35)


THEMES = [
    # Fast and scrappy, like the pawn's synthwave.
    Theme("pawn", 150, 16, "E", 4, MINOR, [0, 5, 2, 6], 11,
          lead_duty=0.25, arp_duty=0.125, bass_style="octaves", drum_style="drive",
          lead_rhythm=[[1, 0.5, 0.5, 1, 1], [0.5, 0.5, 1, 0.5, 0.5, 1],
                       [1.5, 0.5, 2], [0.5, 0.5, 0.5, 0.5, 2]]),
    # A cavalry charge.
    Theme("knight", 140, 16, "D", 4, MINOR, [0, 5, 6, 0, 0, 5, 2, 6], 23,
          lead_duty=0.5, arp_duty=0.25, bass_style="gallop", drum_style="gallop",
          lead_rhythm=[[1.5, 0.5, 1, 1], [0.75, 0.25, 1, 0.75, 0.25, 1],
                       [2, 1, 1], [1, 1, 2]]),
    # Precise and mysterious, half time.
    Theme("bishop", 110, 12, "A", 4, HARMONIC, [0, 5, 3, 4], 37,
          lead_duty=0.125, arp_duty=0.5, bass_style="pulse", drum_style="halftime",
          lead_rhythm=[[-1, 1, 0.5, 1.5], [2, -0.5, 0.5, 1], [1, 1, 1, 1],
                       [3, -1]], arp_rate=8),
    # A fortress under siege.
    Theme("rook", 90, 8, "C", 4, MINOR, [0, 5, 6, 0], 41,
          lead_duty=0.125, arp_duty=0.25, bass_style="heavy", drum_style="siege",
          lead_rhythm=[[2, 1, 1], [1.5, 0.5, 2], [1, 1, 2], [4]], arp_rate=8),
    # Soaring and fierce.
    Theme("queen", 140, 16, "B", 3, MINOR, [0, 5, 2, 6], 53,
          lead_duty=0.25, arp_duty=0.125, bass_style="octaves", drum_style="drive",
          lead_rhythm=[[2, 1, 1], [1, 1, 2], [3, 1], [1, 0.5, 0.5, 2]],
          arp_rate=16),
    # Majestic and relentless, ending each line on the dominant.
    Theme("king", 120, 16, "G", 3, HARMONIC, [0, 5, 3, 4], 67,
          lead_duty=0.25, arp_duty=0.5, bass_style="walk", drum_style="march",
          lead_rhythm=[[1.5, 0.5, 2], [1, 1, 1, 1], [2, 2], [1, 0.5, 0.5, 2]],
          arp_rate=8),
]


def output_filter(audio):
    """The console's output stage: no DC or rumble below ~30 Hz, highs
    rolling off from 9 kHz. Filtered in the frequency domain over the whole
    loop, which is circular, so the seam stays seamless."""
    spectrum = np.fft.rfft(audio, axis=0)
    freqs = np.fft.rfftfreq(len(audio), 1 / RATE)
    high_pass = 1 / (1 + (30 / np.maximum(freqs, 1e-3)) ** 4)
    low_pass = 1 / (1 + (freqs / 9000) ** 4)
    gain = (high_pass * low_pass)[:, None]
    return np.fft.irfft(spectrum * gain, n=len(audio), axis=0)


def render(theme):
    mix = Mix(theme)
    write_drums(theme, mix)
    write_bass(theme, mix)
    write_arp(theme, mix)
    write_lead(theme, mix)
    audio = output_filter(mix.looped())
    return audio / max(1e-9, np.abs(audio).max()) * 0.9


def loudness(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
                          "-af", "ebur128", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    lines = [l for l in out.splitlines() if l.strip().startswith("I:")]
    return float(lines[-1].split()[1])


def write_wav(path, audio):
    pcm = (np.clip(audio, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def build(theme, keep_wav):
    audio = render(theme)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / f"{theme.unit}.wav"
        write_wav(wav, audio)
        gain = 10 ** ((TARGET_LUFS - loudness(wav)) / 20)
        audio = audio * gain
        peak = np.abs(audio).max()
        if peak > 0.98:  # never clip to reach the target
            audio *= 0.98 / peak
        write_wav(wav, audio)
        if keep_wav:
            RAW.mkdir(exist_ok=True)
            write_wav(RAW / wav.name, audio)
        OUT.mkdir(parents=True, exist_ok=True)
        dst = OUT / f"{theme.unit}.ogg"
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                        "-i", str(wav), "-c:a", "libvorbis", "-q:a", str(QUALITY),
                        str(dst)], check=True)
    print(f"{dst.relative_to(HERE.parent.parent)}  {len(audio) / RATE:.2f} s  "
          f"{loudness(dst):.1f} LUFS")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--only", help="comma-separated units")
    parser.add_argument("--wav", action="store_true", help="keep WAVs in raw_retro/")
    args = parser.parse_args()
    wanted = set(args.only.split(",")) if args.only else None
    for theme in THEMES:
        if wanted is None or theme.unit in wanted:
            build(theme, args.wav)


if __name__ == "__main__":
    main()
