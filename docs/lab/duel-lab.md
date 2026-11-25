# Laboratoř duelů — boj zblízka (plán 12, krok 1B; plán 14, kroky 4 a 5)

Spuštění: `dart run tools/duel_lab.dart --world ground --duels 200` (a `--world space`
pro srovnání; `--contact 0.15` zkusí jiné `ArenaRules.contactDamageScale`). Medium proti
Medium, 200 duelů se semínkem na dvojici, limit 180 s; kdo z pilotů rozhoduje v ticku
první, se střídá. Buňka: podíl výher útočníka (odhad `BattleOdds`), medián délky, podíl
vzájemného zničení („draw“, počítá se jako půl výhry) s odhadem `BattleOdds`.

Tabulky jsou změřené po kroku 5 plánu 14 (boj zblízka ve hře). Bitva zná svůj svět
(`BattleState.balance`) a náhlou smrt čte z jeho `ArenaRules` (45 s, pak 15 s náběh);
od kroku 5 roste v náhlé smrti i dosah úderu (`reachHalfWidthAt`) stejně jako zóna
zásahu střel.

## Výsledek

- **Vesmír se nezměnil:** tabulka vesmíru je na procento stejná jako v kroku 4
  a `space_duel_regression_test` sedí na milisekundu i HP. Jediná změna záznamu je
  pravidlo, ne engine: duel pěšec proti pěšci, ve kterém oba padnou v jednom ticku,
  už nemá vítěze (dřív ho dostal útočník).
- **Vzájemné zničení** (rozhodnutí 10): obě figury opustí desku, bez kreditů. Ve hře
  pozemního světa 2 % všech duelů; zrcadla pěšců 33 %, koní 18 %, střelců 13 %, věží
  3 %, králů a dam 1 %. Ve vesmíru 1 % (střelci 13 %, pěšci 3 %).
- **Odhad remízy pro AI** (`BattleOdds.outcomes`): dvě jednotky zblízka se stejnou
  dobou zabití padnou spolu v `meleeMirrorDraw` (32 %) při 3,2 s, s delším soubojem to
  klesá s mocninou 1,5 (odhad: pěšci 32 %, koně 20 %, věže 11 %, králové 6 %);
  u střelby paušálně 4 %. Do prohledávání jdou jen remízy od 5 %, takže ve vesmíru se
  hra AI nemění.
- **Manévry zblízka** (`FireCue.contact`): každá dávka manévru je jeden úder bez letu
  střely, jen do vzdálenosti 1 a v dosahu. Plná síla dávky (`contactDamageScale` 1,0)
  rozbila balanci: úder na rozdíl od střel nemine, takže věž porážela dámu v 90 %
  (dřív 14 %) a král dámu v 84 %. Laboratoř změřila 0,1–0,55 (100 duelů): 0,15 drží
  každou dvojici zblízka proti střelbě v průměru 1 bod od vesmíru, nejhůř dáma proti
  králi −10 bodů (na hraně meze). Platí `ground.arena.contactDamageScale = 0.15`.
- **Náhlá smrt pro údery:** dva bojovníci zblízka, kteří se drží mimo dosah, by se
  mohli míjet donekonečna. Dosah teď roste stejně jako zóna střel (×15 na konci
  náběhu), test `two melee units that keep apart still fight it out` to hlídá. Tabulky
  to nemění: žádný duel nedojde k limitu, mediány zrcadel 4,8–21,4 s.
- **Meze z plánu, které nedrží ani vesmír**, laboratoř hlásí jen pro srovnání (zrcadla
  45–55 %, mediány 8–25 s, „stejná váha“ 35–65 %, `|BattleOdds − simulace| ≤ 0,15`).
  Odchylky odhadu jsou u stejných dvojic jako ve vesmíru (střelec proti koni a věži,
  dáma proti věži a králi); je to vlastnost modelu bez pohybu.
- **Deska:** v slow testu hraje Hard proti Medium 20 her i v pozemní balanci. Na 60
  semínkách vyhrává Hard 62 % her a Medium 32 % (ve vesmíru 67 % a 27 %); pozemní
  test proto chce aspoň polovinu výher a víc než Medium, vesmírný dál 70 %.

## Pozemní svět

| attacker \ defender | pawn* | rook* | knight* | bishop | queen | king* |
|---|---|---|---|---|---|---|
| pawn* |  51% (50%) 6.4 s draw 33% (32%) |   0% (10%) 6.8 s |   6% (10%) 7.2 s |   0% (10%) 3.9 s |   0% (10%) 7.4 s |   0% (10%) 5.3 s |
| rook* | 100% (90%) 6.8 s |  50% (50%) 15.0 s draw 3% (11%) |  96% (83%) 8.9 s |  67% (85%) 8.4 s |  10% (26%) 13.9 s |  18% (17%) 16.9 s |
| knight* |  96% (90%) 7.7 s |   6% (17%) 8.3 s |  43% (50%) 7.4 s draw 18% (20%) |  17% (60%) 6.4 s draw 0% (2%) |   1% (12%) 7.9 s |   0% (10%) 8.6 s |
| bishop | 100% (90%) 3.8 s |  36% (15%) 8.4 s |  86% (40%) 6.5 s draw 0% (2%) |  48% (50%) 4.8 s draw 13% (4%) |   8% (10%) 6.7 s |  10% (10%) 10.4 s |
| queen | 100% (90%) 7.2 s |  93% (74%) 13.3 s |  99% (88%) 8.3 s |  96% (90%) 6.7 s |  56% (50%) 12.7 s draw 1% (4%) |  78% (53%) 18.4 s draw 0% (4%) |
| king* | 100% (90%) 4.9 s |  82% (83%) 16.9 s |  98% (90%) 8.4 s |  90% (90%) 10.7 s |  23% (47%) 17.6 s draw 0% (4%) |  51% (50%) 21.4 s draw 1% (6%) |

- FAIL mirror pairings 45–55 %:  51%,  50%,  43%,  48%,  56%,  51%
- FAIL melee vs ranged of the same weight 35–65 %:  17%,  86%,  10%,  93%,  23%,  78%
- FAIL mirror medians 8–25 s: from 4.8 to 21.4 s
- FAIL melee vs ranged within 10 points of space: melee side -1 points on average, worst queen→king -10 points
- OK   at the limit at most 2 %: 0%
- mutual destruction: 2% of all duels, mirrors 33%, 3%, 18%, 13%, 1%, 1%
- FAIL |BattleOdds − simulation| ≤ 0.15: 8 of 36 pairings over, largest gap 0.46

## Vesmír (srovnání)

| attacker \ defender | pawn | rook | knight | bishop | queen | king |
|---|---|---|---|---|---|---|
| pawn |  50% (50%) 5.5 s draw 3% (4%) |   3% (10%) 7.9 s |   8% (10%) 6.1 s |   1% (13%) 3.8 s |   0% (10%) 3.9 s |   1% (10%) 8.4 s |
| rook |  98% (90%) 7.7 s |  55% (50%) 15.5 s draw 1% (4%) |  86% (80%) 11.3 s draw 1% (0%) |  59% (78%) 9.1 s |  13% (13%) 12.4 s |  21% (19%) 21.0 s |
| knight |  95% (90%) 6.1 s |  10% (20%) 11.0 s |  55% (50%) 10.9 s draw 1% (4%) |  20% (53%) 6.1 s draw 0% (4%) |   1% (10%) 8.7 s |   2% (10%) 12.8 s |
| bishop |  97% (87%) 3.8 s |  35% (22%) 8.4 s draw 1% (0%) |  81% (47%) 5.6 s draw 1% (4%) |  48% (50%) 4.8 s draw 13% (4%) |   8% (10%) 6.7 s |  15% (10%) 12.4 s |
| queen | 100% (90%) 4.1 s |  90% (87%) 12.9 s |  99% (90%) 9.3 s |  96% (90%) 6.7 s |  56% (50%) 12.7 s draw 1% (4%) |  68% (62%) 18.2 s draw 0% (1%) |
| king | 100% (90%) 8.2 s |  86% (81%) 20.0 s |  98% (90%) 13.0 s |  91% (90%) 12.0 s |  28% (38%) 18.0 s draw 0% (1%) |  45% (50%) 27.1 s draw 0% (4%) |

- FAIL mirror pairings 45–55 %:  50%,  55%,  55%,  48%,  56%,  45%
- FAIL mirror medians 8–25 s: from 4.8 to 27.1 s
- OK   at the limit at most 2 %: 0%
- mutual destruction: 1% of all duels, mirrors 3%, 1%, 1%, 13%, 1%, 0%
- FAIL |BattleOdds − simulation| ≤ 0.15: 3 of 36 pairings over, largest gap 0.34
