# Laboratoř duelů — boj zblízka (plán 12, krok 1B; plán 14, krok 4)

Spuštění: `dart run tools/duel_lab.dart --world ground --duels 200` (a `--world space`
pro srovnání). Medium proti Medium, 200 duelů se semínkem na dvojici, limit 180 s; kdo
z pilotů rozhoduje v ticku první, se střídá. Buňka: podíl výher útočníka (odhad
`BattleOdds`), medián délky, podíl vzájemného zničení („draw“, počítá se jako půl výhry).

Tabulky jsou změřené po sloučení `main` (náhlá smrt) do enginu zblízka. Náhlá smrt platí
v obou světech stejně: `ArenaRules` (45 s, pak 15 s náběh), engine zatím jede vždy podle
vesmíru (`BattleEngine.arena`), protože bitva svůj svět nezná. Zóna zásahu roste jen
střelám, ne výpadům zblízka.

## Výsledek

- **Vesmír se nezměnil:** `space_duel_regression_test` přehrává 36 seedovaných duelů
  Medium proti Medium a 18 duelů vylepšených Hard pilotů, které trvají 51–72 s a projdou
  náhlou smrtí. Záznam vznikl na čistém `main` před sloučením a sedí na milisekundu i HP.
  Původních 36 duelů skončí do 45 s (nejdelší král proti králi 44,3 s), proto jejich
  záznam z větve platil beze změny.
- **Náhlá smrt tabulky skoro nemění:** medián nejdelšího zrcadla (král proti králi ve
  vesmíru) je 27 s, proti dřívějšímu měření se buňky pohnuly nejvýš o 1 bod (věž
  proti věži na zemi 54 %, kůň proti pěšci 96 %, král proti věži 81 %, král proti králi
  ve vesmíru 45 %).
- **Pozemní balance** (`WorldBalance.ground`; pěšec, kůň, věž, král zblízka): každá
  dvojice zblízka proti střelbě je do 10 bodů od téže dvojice ve vesmíru, v průměru 0.
  Žádný duel nedošel na limit. Zrcadla 47–57 %, mediány zrcadel 4,8–18,9 s.
- **Meze z plánu, které nedrží ani vesmír**, a proto je laboratoř hlásí jen pro srovnání:
  - zrcadla 45–55 %: vesmír má 45–56 %, dáma proti dámě 56 % v obou světech;
  - medián 8–25 s: platí jen pro zrcadla, dáma sestřelí pěšce za 4 s; i tak pěšec
    a střelec bojují kolem 5 s a král proti králi ve vesmíru 27 s;
  - „stejná váha“ 35–65 %: střelec poráží koně i ve vesmíru (81 %), dáma věž (90 %);
  - `|BattleOdds − simulace| ≤ 0,15`: vesmír 3 dvojice z 36, pozemní 6. Odchylky jsou
    u stejných dvojic (střelec proti koni a věži, dáma proti králi); je to vlastnost
    modelu bez pohybu, ne melee.
- **Vzájemné zničení:** pěšci zblízka se zničí navzájem ve 31 % duelů (ve vesmíru 3 %):
  dva stejné výpady dopadnou ve stejném ticku. Kůň proti koni 14 %, věž proti věži 3 %.
  Aréna dnes dá takový souboj útočníkovi. Olin rozhodl: při vzájemném zničení
  opustí desku obě figury. Zavádí se až v kroku 5 plánu 14 (boj zblízka ve hře).

Proti návrhu v plánu se změnila čísla: kůň nápřah 160 (z 200) a škoda 29 (z 26), věž
škoda 44 (ze 40), král škoda 46 (ze 45), interval 1500 (z 1600) a nápřah 280 (z 350),
pěšec škoda 13 (z 12).

## Pozemní svět

| attacker \ defender | pawn* | rook* | knight* | bishop | queen | king* |
|---|---|---|---|---|---|---|
| pawn* |  47% (50%) 6.3 s draw 31% |   0% (10%) 7.5 s |   3% (10%) 6.5 s |   2% (10%) 3.9 s |   0% (10%) 7.6 s |   0% (10%) 5.0 s |
| rook* |  99% (90%) 8.0 s |  54% (50%) 12.6 s draw 3% |  93% (83%) 8.0 s |  61% (85%) 9.2 s draw 1% |  14% (26%) 13.9 s |  19% (17%) 15.2 s |
| knight* |  96% (90%) 6.9 s |   9% (17%) 8.2 s |  49% (50%) 8.1 s draw 14% |  24% (60%) 6.3 s |   4% (12%) 8.2 s |   0% (10%) 6.9 s |
| bishop |  99% (90%) 3.8 s |  38% (15%) 8.4 s |  83% (40%) 6.5 s |  48% (50%) 4.8 s draw 13% |   8% (10%) 6.7 s |  10% (10%) 9.6 s |
| queen | 100% (90%) 7.3 s |  89% (74%) 14.0 s |  96% (88%) 8.2 s |  96% (90%) 6.7 s |  56% (50%) 12.7 s draw 1% |  75% (53%) 18.0 s |
| king* | 100% (90%) 4.9 s |  81% (83%) 14.6 s | 100% (90%) 7.1 s |  89% (90%) 10.6 s |  26% (47%) 18.6 s |  57% (50%) 18.9 s draw 1% |

- FAIL mirror pairings 45–55 %:  47%,  54%,  49%,  48%,  56%,  57%
- FAIL melee vs ranged of the same weight 35–65 %:  24%,  83%,  14%,  89%,  26%,  75%
- FAIL mirror medians 8–25 s: from 4.8 to 18.9 s
- OK   melee vs ranged within 10 points of space: melee side 0 points on average, worst queen→king -7 points
- OK   at the limit at most 2 %: 0%
- FAIL |BattleOdds − simulation| ≤ 0.15: 6 of 36 pairings over, largest gap 0.43

## Vesmír (srovnání)

| attacker \ defender | pawn | rook | knight | bishop | queen | king |
|---|---|---|---|---|---|---|
| pawn |  50% (50%) 5.5 s draw 3% |   3% (10%) 7.9 s |   8% (10%) 6.1 s |   1% (13%) 3.8 s |   0% (10%) 3.9 s |   1% (10%) 8.4 s |
| rook |  98% (90%) 7.7 s |  55% (50%) 15.5 s draw 1% |  86% (80%) 11.3 s draw 1% |  59% (78%) 9.1 s |  13% (13%) 12.4 s |  21% (19%) 21.0 s |
| knight |  95% (90%) 6.1 s |  10% (20%) 11.0 s |  55% (50%) 10.9 s draw 1% |  20% (53%) 6.1 s |   1% (10%) 8.7 s |   2% (10%) 12.8 s |
| bishop |  97% (87%) 3.8 s |  35% (22%) 8.4 s draw 1% |  81% (47%) 5.6 s draw 1% |  48% (50%) 4.8 s draw 13% |   8% (10%) 6.7 s |  15% (10%) 12.4 s |
| queen | 100% (90%) 4.1 s |  90% (87%) 12.9 s |  99% (90%) 9.3 s |  96% (90%) 6.7 s |  56% (50%) 12.7 s draw 1% |  68% (62%) 18.2 s |
| king | 100% (90%) 8.2 s |  86% (81%) 20.0 s |  98% (90%) 13.0 s |  91% (90%) 12.0 s |  28% (38%) 18.0 s |  45% (50%) 27.1 s |

- FAIL mirror pairings 45–55 %:  50%,  55%,  55%,  48%,  56%,  45%
- FAIL mirror medians 8–25 s: from 4.8 to 27.1 s
- OK   at the limit at most 2 %: 0%
- FAIL |BattleOdds − simulation| ≤ 0.15: 3 of 36 pairings over, largest gap 0.34
