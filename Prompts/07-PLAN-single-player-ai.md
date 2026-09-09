# Phase 4: Single Player — AI oponent (tahovka + realtime battle)

## Kontext

Hra dnes umí tři režimy: hot-seat (jeden telefon, dva hráči), online multiplayer přes
Supabase (bez battle arény) a lokální WiFi (s realtime battle arénou). Chybí režim pro
jednoho hráče. Cíl této fáze: **hráč hraje sám proti AI**, která

1. tahá figurkami na šachovnici (tahová část), a
2. při každém útoku (capture) sama řídí svou loď v realtime battle aréně
   (uhýbá střelám, míří, aktivuje štít).

Bez serveru, bez nových závislostí — vše běží v procesu aplikace v čistém Dartu.

---

## Co už máme (a co z toho AI využije)

| Existující kód | Použití pro AI |
|---|---|
| `GameEngine.applyMove/resolveBattle` — čisté funkce `(GameState, akce) → GameState` | Základ pro prohledávání tahů (minimax). Stav je immutable, takže „co kdyby“ tahy nic nerozbijí. |
| `PieceValidator.getLegalMoves(board, pos, color)` — bez kontroly tahu | Generátor tahů pro **obě** barvy (stejný trik už používá `ThreatAnalyzer`). |
| `ThreatAnalyzer.getThreatenedPositions` | Vstup do ohodnocovací funkce (kolik mých figurek je v ohrožení). |
| `VictoryChecker` + `state.isFinished` | Terminální uzly prohledávání (výhra/prohra = ±∞). |
| `BoardState.powerFieldCount`, `findPieces` | Ohodnocení power fieldů, materiálu, infiltrace. |
| `BattleEngine.tick/moveShip/activateShield` — čisté | Battle AI se rozhoduje nad skutečným `BattleState` a její akce jdou stejnou cestou jako akce hráče. |
| `unitBaseStats` + `UpgradeEngine.statsFor` | Odhad šance na výhru v souboji (pěšec vs. král = téměř jistá smrt pěšce). |
| `GameStateNotifier` (`GameMode`, `localColor`, `_localPendingBattleMove`) | Nový `GameMode.singlePlayer` se chová jako hot-seat s pevnou barvou hráče. |
| `BattleScreen` — layout „síťový“ když `localColor != null` | Hráč dole s ovládáním, AI nahoře jen s panelem. **Bez změny UI.** |

### Důležité odlišnosti od šachové AI

- **Capture není jistý.** Útok spouští souboj; když útočník prohraje, **zmizí útočník**.
  Slabá figurka (pěšec: 40 HP, 8 dmg) útočící na krále (180 HP, 35 dmg, 35 % obrana)
  téměř jistě zemře. AI proto musí capture hodnotit jako sázku:
  `EV = p·hodnota(cíl) − (1−p)·hodnota(útočník)`, kde `p` je odhad šance na výhru.
- **Tři způsoby výhry.** Nejen materiál: obsazení všech 5 power fieldů na konci tahu,
  pěšec na soupeřově zadní řadě (infiltrace), sebrání krále i královny.
  Ohodnocení musí tyto hrozby vidět dopředu (pěšec 1 krok od zadní řady = kritické).
- **Last Warrior.** Ztráta jedné královské figurky zmrzačí druhou (pohyb +1). Hodnota
  krále/královny je proto vyšší než součet jejich „bojových“ statistik.
- **Lidský faktor v souboji.** Hráč uhýbá a štítuje; AI na Hard taky. Odhad `p` proto
  nikdy nedávat do extrémů (clamp do ~[0.1, 0.9]).

---

## Architektonická rozhodnutí

1. **AI je čistý Dart v `lib/core/ai/`** — bez Flutter závislostí, plně testovatelná
   `flutter test`, stejný princip jako `core/game_logic`.
2. **Integrace přes `GameMode.singlePlayer` v `GameStateNotifier`** (ne přes
   `GameTransport`). Důvod: battle AI potřebuje vidět skutečný `BattleState`
   (projektily, pozice lodí), který přes transport nechodí — přes síť se posílají jen
   vstupy. Transport-peer varianta („bot jako druhý `GameSession`“) by musela souboj
   simulovat podruhé. Notifier už má vše potřebné: `_localColor`, `_localPendingBattleMove`,
   hot-seat větev `tryMove`/`resolveBattle`.
3. **Spouštěč tahu AI je reaktivní, ne procedurální.** Po každé změně stavu:
   `phase == playing && currentTurn == aiColor && !thinking` → spustit výpočet.
   Tím se správně pokryjí všechny cesty: po tahu hráče, po souboji (ať útočil kdokoli),
   po restartu hry.
4. **Výpočet mimo UI vlákno.** Easy/Medium jsou milisekundy (synchronně). Hard
   (hloubka 3) běží v `compute()` isolate — `GameState` je Freezed + JSON, takže se
   dá poslat. Ochrana proti závodu: generation counter, výsledek se zahodí, pokud
   mezitím začala nová hra.
5. **Battle AI má fyzická omezení.** Hráč táhne prstem okamžitě; AI má maximální
   rychlost lodi, reakční zpoždění a chybu míření podle obtížnosti. Jinak by na Hard
   nešla porazit (perfektní dodge v každém ticku).
6. **Deterministika pro testy.** Všechny náhodné složky (Easy výběr, jitter, šance na
   štít) berou `Random` zvenčí (seed).
7. **Obtížnost = profil, ne if/else v kódu.** Jedna třída `AiDifficulty` s parametry pro
   šachovnici i souboj.

---

## Nová struktura

```
lib/core/ai/
├── ai_difficulty.dart          # enum + profily parametrů (board + battle)
├── move_generator.dart         # všechny legální tahy barvy → List<Move>
├── battle_odds.dart            # p(útočník vyhraje) ze statistik jednotek
├── board_evaluator.dart        # GameState → skóre z pohledu barvy
├── board_ai.dart               # výběr tahu: random / greedy / alpha-beta + expectimax
└── battle_ai.dart              # BattleState → akce lodi (cílové x, štít)

lib/features/game/presentation/providers/
└── ai_opponent_controller.dart # napojení board_ai na GameStateNotifier (timer, isolate)

test/core/ai/
├── move_generator_test.dart
├── battle_odds_test.dart
├── board_evaluator_test.dart
├── board_ai_test.dart
└── battle_ai_test.dart
```

---

## Implementační kroky

### Krok 0 — Plumbing režimu (hratelné end-to-end s náhodnou AI)

**`game_state_provider.dart`**
- `GameMode.singlePlayer` do enumu.
- `startSinglePlayerGame({required AiDifficulty difficulty, PlayerColor humanColor = white})`:
  stejná inicializace jako `startNewGame()`, navíc `_mode = singlePlayer`,
  `_localColor = humanColor`, `_aiColor = humanColor.opposite`, jméno AI hráče
  („Orbitron AI · Hard“).
- `tryMove`: nová větev pro `singlePlayer` — jako hot-seat, ale odmítne tah figurkou
  jiné barvy než `_localColor` (obrana proti tapu během tahu AI).
- `applyAiMove(Move)`: interní; capture → `_localPendingBattleMove` + `triggerBattle: true`,
  jinak `applyMove`. Stejná logika jako hráčova větev, sdílet do privátní metody.
- `resolveBattle` — hot-seat větev už funguje beze změny (`_session == null`).
- `restartCurrentMode()`: tlačítko „New Game“ v `game_screen.dart` a overlay po konci hry
  dnes volají `startNewGame()` = vždy hot-seat. Musí respektovat aktuální režim.

**`ai_opponent_controller.dart`** (nový)
- Poslouchá `gameStateProvider`; při splnění podmínky z rozhodnutí 3 naplánuje tah:
  `Future.delayed(thinkDelay)` (UX: 300–800 ms, ať AI „nepřemýšlí“ nulově) → `BoardAi.chooseMove`
  → `notifier.applyAiMove`.
- Zruší se při `dispose`, při novém startu hry a když `phase != playing`.
- Provider `aiOpponentProvider` – vytváří se jen v `singlePlayer` režimu.

**`lobby_screen.dart`**
- Tlačítko **„Single Player“** → dialog: obtížnost (Easy / Medium / Hard) + barva
  (White = táhnu první / Black). Potom `startSinglePlayerGame` + push `GameScreen`.

**`board_ai.dart` (v1)** – `RandomAi`: náhodný legální tah. Slouží k ověření celé smyčky
včetně souboje, ještě bez chytrosti.

**`game_board.dart`** — animace tahu soupeře. Dnes se animace (`_currentMoveAnim`)
spouští jen v `_handleTap`, takže tah AI (a mimochodem i vzdálený tah v multiplayeru)
„skočí“. Přidat `ref.listen(gameStateProvider)`: když přibyl tah do `moveHistory`
a nebyl spuštěn lokálně, přehrát stejnou animaci. Vylepší i multiplayer.

*Výstup kroku 0:* hráč odehraje celou partii proti náhodné AI včetně soubojů
(AI loď zatím stojí na místě).

### Krok 1 — Generátor tahů a odhad šancí v souboji

**`move_generator.dart`**
```dart
class MoveGenerator {
  /// Všechny legální tahy [color] bez ohledu na currentTurn.
  static List<Move> generate(GameState state, PlayerColor color);
}
```
Iteruje `board.findPieces(color)`, pro každou volá `PieceValidator` (mapa validátorů
+ Last Warrior jako v `ThreatAnalyzer`; vytáhnout sdílený `validatorFor(piece)` do
`core/game_logic/validators/`, ať existuje jednou). `Move` skládá jako
`MoveValidator.createMove` (včetně `isSnipe`). Řazení: captures napřed (pro alpha-beta).

**`battle_odds.dart`**
```dart
class BattleOdds {
  /// Pravděpodobnost, že útočník vyhraje souboj, 0.1–0.9.
  static double attackerWinProbability(Piece attacker, Piece defender,
      UpgradeProfile attackerUpgrades, UpgradeProfile defenderUpgrades);
}
```
Model: čas do zabití `TTK = ceil(HP_cíl / čistý_dmg) · interval` pro obě strany, kde
`čistý_dmg = dmg − round(dmg · defense)` (přesně jako `BattleEngine._applyHit`).
`p = sigmoid(k · (TTK_obránce − TTK_útočníka) / průměr)` s clampem. Volitelně ověřit
kalibraci proti skutečné simulaci `BattleEngine.tick` s oběma loděmi v klidu
(deterministický výsledek) — test.

### Krok 2 — Ohodnocovací funkce + Easy/Medium

**`board_evaluator.dart`** — `evaluate(GameState, PlayerColor pov) → double`
(kladné = dobré pro `pov`). Složky s váhami v `AiDifficulty`:

| Složka | Jak | Poznámka |
|---|---|---|
| Materiál | součet hodnot figurek | hodnota = bojová síla (HP·DPS·obrana) × role; král/královna extra bonus (Last Warrior riziko) |
| Power fieldy | `powerFieldCount` mě − soupeř; 5/5 = terminál | + bonus za figurku 1 tah od volného fieldu |
| Infiltrace | pro každý pěšec: `(7 − vzdálenost k zadní řadě)^2` | pěšec na předposlední řadě bez obránce ≈ výhra |
| Ohrožení | pro každou ohroženou figurku: `−p(útočník vyhraje)·hodnota` | přes `ThreatAnalyzer` + `BattleOdds`, oběma směry |
| Mobilita | počet tahů mě − soupeř (malá váha) | přes `MoveGenerator` |
| Královské figurky | `hasKing/hasQueen`, `isLastWarrior` penalizace | |

Vlastnost pro test: **symetrie** — zrcadlená pozice s prohozenými barvami dává
`evaluate(...,white) == −evaluate(...,black)`.

**`board_ai.dart` (v2)**
- `GreedyAi` (Medium): pro každý tah spočítá očekávané skóre. Tichý tah → `evaluate`
  po `applyMove`. Capture → `p·evaluate(útočník vyhrál) + (1−p)·evaluate(obránce vyhrál)`.
  Oba výsledky dá `GameEngine.resolveBattle(applyMove(state, m, triggerBattle: true), m, winner)`
  — žádný nový kód v enginu.
- `Easy`: Greedy s velkým šumem (`score + random·noise`) a bez složky „ohrožení“
  (dělá chyby, nechává figurky napospas).

### Krok 3 — Hard: alpha-beta s expectimax uzly

- Hloubka 3 (AI → hráč → AI), capture uzly jako **chance node** se dvěma větvemi
  vážený `p`/`1−p`. Po hloubce 3 volitelně jen capture tahy do hloubky 4 (quiescence),
  ať se nekončí uprostřed výměny.
- Move ordering: captures s vysokým `p` a vysokou hodnotou cíle napřed → lepší ořez.
- Rozpočet: větvení ~35, hloubka 3 ≈ 40k listů, `BoardState.movePiece` kopíruje
  8×8 → odhad 100–400 ms v release. Proto isolate (`compute`) + časový limit
  (`AiDifficulty.timeBudgetMs`, iterativní prohlubování 1→2→3, vrátí nejlepší z poslední
  dokončené hloubky).
- Malé zrychlení, pokud bude třeba: `evaluate` inkrementálně počítat materiál z `Move`
  místo přes celou desku; Zobrist/transposition table až když by to nestačilo.

### Krok 4 — Battle AI (realtime aréna)

**Předpoklad v enginu:** zveřejnit rychlost projektilu — `BattleEngine.projectileSpeed(WeaponType)`
(dnes privátní mapa `_projectileSpeed`). Jinak AI neumí spočítat čas dopadu.

**`battle_ai.dart`**
```dart
class BattleAi {
  BattleAi(this.profile, this.random);
  /// Volá se každý tick; vrací akci pro loď na straně [isAttacker].
  BattleAiAction decide(BattleState state, bool isAttacker, int deltaMs);
}
class BattleAiAction { final double? targetX; final bool activateShield; }
```
Rozhodovací smyčka (spouští se každých `reactionMs`, mezi tím jen dojíždí k cíli):

1. **Hrozby**: příchozí projektily (`fromAttacker != isAttacker`), pro každý
   `zasáhne = |p.x − mojeX| ≤ hitHalfWidth`, `ETA = (1 − p.positionFraction) / speed`.
2. **Míření**: cílové x = x soupeře (moje střely letí v mém pruhu a trefí, když je
   soupeř do ±0.07). Hard predikuje pohyb soupeře z posledních pozic.
3. **Úhyb**: pokud v cílovém x dopadne střela dřív než za `dodgeWindowMs`, posunout cíl
   o `±(hitHalfWidth + margin)` na stranu s méně střelami, respektovat `shipEdgeMargin`.
   Úhyb má přednost před mířením.
4. **Pohyb**: k cíli rychlostí max `maxShipSpeed` (podíl arény/s) — tady vzniká férovost.
5. **Štít**: `shieldState.canActivate` a (nejde stihnout uhnout: `vzdálenost/rychlost > ETA`
   nebo `dmg ≥ zbývající HP`) → aktivovat s pravděpodobností `shieldSkill`.
6. **Šum**: k cílovému x přičíst `aimError · random`.

| Parametr | Easy | Medium | Hard |
|---|---|---|---|
| `reactionMs` | 400 | 220 | 100 |
| `maxShipSpeed` (aréna/s) | 0.5 | 0.9 | 1.5 |
| `aimError` | 0.10 | 0.05 | 0.015 |
| `shieldSkill` | 0.4 | 0.7 | 0.95 |
| `dodgeWindowMs` | 250 | 400 | 600 |
| predikce pohybu soupeře | ne | ne | ano |

Hodnoty jsou startovní — doladit hraním (viz „Vyvážení“).

**`battle_state_provider.dart`**
- `startBattle(..., BattleAi? ai, bool aiIsAttacker)`.
- V `_onTick` po `BattleEngine.tick`: `final a = ai.decide(next, aiIsAttacker, deltaMs)`;
  `targetX != null → BattleEngine.moveShip`, `activateShield → BattleEngine.activateShield`.
  Přímo na engine, **ne** přes `moveLocalShip` (ta posílá na transport a throttluje).
- `game_screen.dart`, místo kde se volá `startBattle`: v `singlePlayer` režimu předat
  `BattleAi` z profilu obtížnosti a `aiIsAttacker = attackerColor == aiColor`.

`BattleScreen` beze změn: `localColor != null` → hráč dole s ovládáním, AI nahoře jen
`UnitCombatPanel`. `activateShield()`/`moveShip()` v notifieru jsou `_session?.` → no-op.

### Krok 5 — Polish a progrese

- **Indikátor „AI přemýšlí“** v `_PlayerInfoBar` (místo pulzujícího TURN).
- **Upgrady AI podle obtížnosti**: `upgradeProfileProvider(aiColor)` nastavit např.
  Hard = level 1 na všech jednotkách. Levné, citelné.
- **Kredity pro hráče**: `GameEngine.resolveBattle` vrací odměnu, kterou dnes všichni
  zahazují (`final (newState, _)`). V single playeru ji připsat do
  `playerCreditsProvider(humanColor)` → Comcenter dostane smysl i offline.
  (Comcenter má vlastní privátní providery `_upgradeProfileProvider`/`_creditsProvider`
  — sjednotit s těmi v `battle_state_provider.dart`, jinak upgrady nemají na souboj vliv.)
- README / CHANGELOG / CLAUDE.md: nový režim a `lib/core/ai/` v architektuře.

---

## Testy

| Test | Ověřuje |
|---|---|
| `move_generator_test` | pro každou figurku shoda s `MoveValidator.getLegalMoves`; generuje pro barvu mimo tah; capture flag a `isSnipe` |
| `battle_odds_test` | pěšec→král < 0.2; král→pěšec > 0.8; symetrie identických jednotek = 0.5; shoda pořadí s reálnou simulací `BattleEngine.tick` (obě lodě stojí) |
| `board_evaluator_test` | symetrie barev; 4/5 power fieldů > 2/5; pěšec na 6. řadě > pěšec na 2. řadě; ztráta krále výrazně horší než ztráta věže |
| `board_ai_test` | Greedy i Hard najdou výhru na 1 tah (infiltrace / 5. power field / eliminace); Hard neobětuje pěšce na krále; Hard vidí mat-in-2 (pěšec tah od zadní řady, který Greedy nechá); 200 náhodných partií Random×Random → žádný nelegální tah, hra vždy skončí (limit tahů) |
| `battle_ai_test` | Hard uhne jediné střele z klidu; s omezenou rychlostí neuhne, když je pozdě, a použije štít; Hard porazí stojícího soupeře se stejnou jednotkou; Easy vs Hard se stejnou jednotkou → Hard vyhraje > 80 % z 50 simulací (seedováno) |
| `game_state_provider_test` | `singlePlayer`: tah cizí barvou odmítne; po tahu hráče je `currentTurn == aiColor`; capture AI nastaví `pendingBattleMove` a fázi `battle` |
| self-play (volitelně, `@Tags(['slow'])`) | Hard vs Easy > 70 % — hlídá regresi „obtížnost nic nedělá“ |

Existující testy (108) musí zůstat zelené; `flutter analyze` bez varování.

---

## Vyvážení (po implementaci, ruční)

- 10 partií na každé obtížnosti; Easy má prohrávat s běžným hráčem, Hard má být
  nepříjemný, ne neporazitelný.
- Hlavní páky: `maxShipSpeed` a `shieldSkill` v souboji; váha „ohrožení“ a hloubka
  na šachovnici.
- Sledovat čas na tah Hard v release na slabším Androidu (cíl < 1 s).

---

## Pořadí a odhad

| Krok | Obsah | Odhad |
|---|---|---|
| 0 | režim, lobby, controller, random AI, animace tahu soupeře | 1 den |
| 1 | generátor tahů, battle odds + testy | 0.5 dne |
| 2 | evaluator, Easy/Medium + testy | 1 den |
| 3 | Hard alpha-beta/expectimax, isolate, time budget | 1–1.5 dne |
| 4 | battle AI + napojení do provideru + testy | 1 den |
| 5 | polish, kredity, upgrady AI, dokumentace | 0.5 dne |

Po kroku 0 je hra hratelná, každý další krok je samostatně mergovatelný.

---

## Rozhodnutí k potvrzení

1. **Obtížnosti tři** (Easy/Medium/Hard) — stačí, nebo chceš i „Custom“ s posuvníky?
2. **Barva hráče volitelná** v dialogu (default bílá). OK?
3. **Kredity a upgrady v single playeru** (krok 5) — chceš to teď, nebo až s persistencí
   do Supabase `user_upgrades`?
4. **Hard v isolate** — pokud bude měření ukazovat < 150 ms, isolate vynechám a ušetřím
   složitost.

## Mimo rozsah (poznámky do budoucna)

- Po výhře obránce v souboji engine neaktualizuje `hasKing/hasQueen` ani Last Warrior
  pro odstraněného útočníka a nekontroluje výhru — existující mezera v `resolveBattle`,
  AI ji jen zdědí. Stojí za samostatnou opravu.
- Formace: AI zatím hraje default formaci; vlastní formace AI až s fází formací pro hráče.
- Otevírací knihovna / učení z partií — ne.
