# Frakce: figurky jako dva skin packy

Plán: [`Prompts/13-PLAN-frakce.md`](../../Prompts/13-PLAN-frakce.md). Místo bílých a černých figurek dvě frakce.
Stranu poznáš podle barvy a motivu, typ figurky podle siluety.

| Soubor | Co dělá |
|---|---|
| `styles.yaml` | stylové presety, siluetové věty, rám, šablona promptu, cílové výšky |
| `factions.yaml` | packy: strany, DNA, podstavec, lem, seed, SUBJECT věty |
| `picks.yaml` | vybraný kandidát pro každou figurku |
| `gen_pieces.py` | skládá prompty a generuje přes ComfyUI: Qwen-Image, pro srovnání `--model dev` (FLUX.1-dev); výřez RMBG-2.0 |
| `postprocess.py` | ořez, odstranění postav navíc, výška podle typu, zarovnání dolů, obrys, export 512/256/128 a `manifest.json` |
| `sheets.py` | archy kandidátů, siluetový test, deska v barvě, šedotónu a pro barvoslepé, `metrics.json` |

Postup jednoho packu:

```bash
cd tools/faction_art
export COMFY_URL=http://127.0.0.1:8188 CF_ID=local CF_SECRET=local   # tunel na ComfyUI
python3 gen_pieces.py heaven_hell --print           # jen prompty
python3 gen_pieces.py heaven_hell --lineup          # sestavový náhled, ladění stylu
python3 gen_pieces.py heaven_hell                   # 2 strany × 6 figurek × 4 kandidáti
python3 sheets.py heaven_hell --candidates          # archy k výběru, pak picks.yaml
python3 postprocess.py heaven_hell
python3 sheets.py heaven_hell                       # akceptační testy
# FLUX-dev pro srovnání: --model dev u gen_pieces, postprocess i sheets
```

Výstupy jdou do `out/<pack>/`, ta složka je v `.gitignore`. Do appky se kopírují jen hotové figurky z `out/<pack>/final/`.

Model: Qwen-Image (Apache 2.0) podle rozhodnutí Olina. FLUX.1-dev je nekomerční a slouží jen ke srovnání (`python3 sheets.py <pack> --compare`).
