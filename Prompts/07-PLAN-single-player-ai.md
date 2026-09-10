# Phase 4: Single Player — AI oponent (tahovka + realtime battle + progres flotily)

> Zadání pro implementaci. Všechna otevřená rozhodnutí jsou uzavřená (sekce
> „Uzavřená rozhodnutí“). Postupuj po krocích 0→6, každý krok = samostatný commit,
> po každém `flutter analyze` bez varování a `flutter test` zelené (dnes 108 testů).

## Cíl

Hráč hraje sám proti AI, která

1. tahá figurkami na šachovnici (tahová část),
2. při každém útoku (capture) sama řídí svou loď v realtime battle aréně
   (uhýbá střelám, míří, aktivuje štít),
3. má vlastní flotilu s progresem: vydělává kredity ze soubojů a upgraduje jednotky
   stejným systémem jako hráč, s uložením mezi spuštěními.

Bez serveru. Jediná nová závislost: `shared_preferences` (lokální uložení progresu).

---

## Uzavřená rozhodnutí

| # | Rozhodnutí | Volba |
|---|---|---|
| 1 | Počet obtížností | **3**: Easy / Medium / Hard. Žádné custom posuvníky. |
| 2 | Barva hráče | Volitelná v dialogu, **default bílá** (hráč táhne první). |
| 3 | Progres flotily AI | **Ano, symetrický s hráčem.** Každá obtížnost má **vlastní flotilu** (identity `ai-easy`, `ai-medium`, `ai-hard`), která si pamatuje kredity i upgrady. |
| 4 | Obtížnost vs. síla flotily | **Oddělené.** Obtížnost = dovednost (hloubka prohledávání, reflexy v aréně). Upgrady = progres, roste hraním. |
| 5 | Runaway ochrana | **Rubber band**: součet levelů AI ≤ součet levelů hráče + offset (Easy 0, Medium 1, Hard 2). Přebytečné kredity AI drží, neztrácí. |
| 6 | Uložení progresu | **`shared_preferences`**, JSON blob na klíč `fleet_progress.<identity>`. Identity hráče `player` (aplikace nemá auth). Supabase `user_upgrades` sync **mimo rozsah**. |
| 7 | Kredity hráče v single playeru | **Ano, hned.** Comcenter se sjednotí na sdílené providery, aby upgrady měly na souboj vliv. |
| 8 | Hard v isolate | Nejprve změřit. Isolate (`compute`) **jen pokud** medián tahu Hard v release na Androidu > 150 ms. |
| 9 | Integrace AI | Přes `GameMode.singlePlayer` v `GameStateNotifier`, **ne** přes `GameTransport` (battle AI potřebuje skutečný `BattleState`, ten přes transport nechodí). |
| 10 | Náhoda | Všechny náhodné složky berou `Random` zvenčí (seedovatelné testy). |

---

## Co v kódu už je a jak to AI využije

| Existující kód | Použití |
|---|---|
| `GameEngine.applyMove/resolveBattle` (`core/game_logic/engine/game_engine.dart`) — čisté `(GameState, akce) → GameState` | Základ prohledávání. Obě větve capture: `resolveBattle(applyMove(s, m, triggerBattle: true), m, winner)`. |
| `PieceValidator.getLegalMoves(board, pos, color)` — **bez** kontroly tahu (`MoveValidator.getLegalMoves` tah kontroluje) | Generátor tahů pro obě barvy, stejný trik jako `ThreatAnalyzer`. |
| `ThreatAnalyzer.getThreatenedPositions` | Složka „ohrožení“ v ohodnocení. |
| `VictoryChecker`, `state.isFinished`, `state.winner` | Terminální uzly. |
| `BoardState.powerFieldCount/findPieces/pieceAt` | Ohodnocení. |
| `BattleEngine.tick/moveShip/activateShield`, konstanty `hitHalfWidth = 0.07`, `shipEdgeMargin = 0.06` | Battle AI rozhoduje nad skutečným stavem, akce jdou stejnou cestou jako hráčovy. |
| `unitBaseStats`, `UpgradeEngine.statsFor/applyUpgrades/upgradeCost/resourcesFor` | Odhad šance v souboji, utrácení AI. |
| `UpgradeRepository` (Supabase) | Referenční JSON tvar upgradů (`{"pawn": 1, ...}`) — použít stejný. |
| `GameStateNotifier` (`_localColor`, `_localPendingBattleMove`, hot-seat větve `tryMove`/`resolveBattle`) | Nový režim se chová jako hot-seat s pevnou barvou hráče. |
| `BattleScreen`: `isHotSeat = localColor == null` | S `localColor != null` je hráč dole s ovládáním, AI nahoře jen `UnitCombatPanel`. **Beze změny UI.** |
| `GameBoard._canSelectPiece` + blokace tapu mimo `localColor` tah | S `localColor` nastaveným funguje pro single player beze změny. |

### Odlišnosti od šachové AI (musí se promítnout do ohodnocení)

- **Capture je sázka.** Útok spouští souboj; prohraje-li útočník, **zmizí útočník** a obránce zůstane.
  Pěšec (40 HP, 8 dmg, rapidFire 400 ms) proti králi (180 HP, 35 dmg, 35 % obrana) téměř jistě zemře.
  `EV(capture) = p·hodnota(cíl) − (1−p)·hodnota(útočník)`.
- **Tři způsoby výhry.** 5/5 power fieldů na konci tahu; pěšec na soupeřově zadní řadě; král i královna sebráni.
- **Last Warrior.** Ztráta jedné královské figurky zmrzačí druhou na pohyb +1.
- **Lidský faktor v aréně.** Odhad `p` clampovat do `[0.1, 0.9]`.

---

## Struktura nových souborů

```
lib/core/ai/
├── ai_difficulty.dart          # enum AiDifficulty + AiProfile (parametry board + battle)
├── move_generator.dart         # MoveGenerator.generate(state, color) → List<Move>
├── battle_odds.dart            # BattleOdds.attackerWinProbability(...)
├── board_evaluator.dart        # BoardEvaluator.evaluate(state, pov, weights) → double
├── board_ai.dart               # abstract BoardAi + RandomAi, GreedyAi, SearchAi
├── battle_ai.dart              # BattleAi.decide(state, isAttacker, deltaMs) → BattleAiAction
└── fleet_progression.dart      # FleetProgression.spend(...) — politika utrácení + rubber band

lib/core/game_logic/models/
└── fleet_progress.dart         # FleetProgress {credits, profile, gamesPlayed, wins} + JSON

lib/core/game_logic/validators/
└── validator_registry.dart     # validatorFor(piece) — sdílené MoveValidator/ThreatAnalyzer/MoveGenerator

lib/features/progress/data/
└── fleet_progress_store.dart   # shared_preferences load/save

lib/features/progress/presentation/providers/
└── fleet_progress_provider.dart # fleetProgressProvider.family<FleetProgress, String identity>

lib/features/game/presentation/providers/
└── ai_opponent_controller.dart # napojení BoardAi na GameStateNotifier

test/core/ai/                   # move_generator, battle_odds, board_evaluator, board_ai, battle_ai, fleet_progression
test/features/progress/         # fleet_progress_store_test (in-memory SharedPreferences mock)
```

---

## Krok 0 — Režim single player, hratelné end-to-end s náhodnou AI

### `lib/core/ai/ai_difficulty.dart`
```dart
enum AiDifficulty { easy, medium, hard }

class AiProfile {
  // board
  final int searchDepth;          // 0 = greedy, 3 = alpha-beta
  final double evalNoise;         // šum přičtený ke skóre (Easy)
  final bool useThreatTerm;       // Easy = false
  final int timeBudgetMs;
  final int thinkDelayMs;         // UX prodleva před tahem
  // battle
  final int reactionMs;
  final double maxShipSpeed;      // podíl šířky arény za sekundu
  final double aimError;
  final double shieldSkill;       // 0–1
  final int dodgeWindowMs;
  final bool predictOpponent;
  // progression
  final int rubberBandOffset;     // Easy 0, Medium 1, Hard 2
  final String identity;          // 'ai-easy' …
  final String displayName;       // 'Orbitron AI · Hard'
  static AiProfile of(AiDifficulty d);
}
```

| Parametr | Easy | Medium | Hard |
|---|---|---|---|
| searchDepth | 0 | 0 | 3 |
| evalNoise | 40 | 5 | 0 |
| useThreatTerm | ne | ano | ano |
| timeBudgetMs | — | — | 800 |
| thinkDelayMs | 500 | 400 | 300 |
| reactionMs | 400 | 220 | 100 |
| maxShipSpeed | 0.5 | 0.9 | 1.5 |
| aimError | 0.10 | 0.05 | 0.015 |
| shieldSkill | 0.4 | 0.7 | 0.95 |
| dodgeWindowMs | 250 | 400 | 600 |
| predictOpponent | ne | ne | ano |
| rubberBandOffset | 0 | 1 | 2 |

### `lib/features/game/presentation/providers/game_state_provider.dart`
- `GameMode.singlePlayer` do enumu.
- Nová pole: `AiProfile? _aiProfile; PlayerColor? _aiColor;` + gettery.
- `void startSinglePlayerGame({required AiProfile profile, PlayerColor humanColor = PlayerColor.white})`:
  `_detachSession()`, `_mode = singlePlayer`, `_localColor = humanColor`, `_aiColor = humanColor.opposite`,
  hráči: lokální `displayName` = jméno z lobby, AI = `profile.displayName`, `userId` = `profile.identity`.
  Default formace pro oba (stejně jako `startNewGame`). Sdílenou inicializaci vytáhnout do
  privátní `_buildDefaultGame(whitePlayer, blackPlayer)` a použít i v `startNewGame` a v
  top-level `gameStateProvider` (dnes 3× duplikováno).
- `tryMove`: větev pro `singlePlayer` = hot-seat větev + podmínka `piece.color == _localColor`.
  Společný kód „aplikuj tah, capture → pending + `triggerBattle: true`“ vytáhnout do `_applyLocalMove(Move)`.
- `bool applyAiMove(Move move)`: ověří `_mode == singlePlayer && state.currentTurn == _aiColor && phase == playing`,
  ověří legalitu přes `MoveValidator.createMove` (obrana proti chybě v AI), pak `_applyLocalMove`.
- `void restartCurrentMode()`: `singlePlayer` → `startSinglePlayerGame` se stejným profilem a barvou;
  jinak `startNewGame()`. **Nahradit** obě volání `startNewGame()` v `game_screen.dart`
  (tlačítko refresh v AppBar a `onNewGame` v `_GameOverOverlay`).
- `resolveBattle` hot-seat větev: beze změny logiky, ale odměnu **nezahazovat**: přidat
  `void Function(PlayerColor winner, int credits)? onBattleReward;` a volat ho.

### `lib/features/game/presentation/providers/ai_opponent_controller.dart`
```dart
class AiOpponentController {
  AiOpponentController(this._ref, this._ai, this._profile);
  int _generation = 0; Timer? _pending; bool _thinking = false;
  void attach();   // ref.listen(gameStateProvider) → _maybeSchedule()
  void dispose();  // cancel timer, generation++
}
```
- `_maybeSchedule()`: pokud `mode == singlePlayer && phase == playing && currentTurn == aiColor && !_thinking`
  → `_thinking = true; gen = ++_generation;` → `Timer(thinkDelayMs)` → `ai.chooseMove(state, aiColor)`
  (v kroku 3 případně isolate) → pokud `gen == _generation` a stav pořád stejný (`moveCount` shodný)
  → `notifier.applyAiMove(move)`; vždy `_thinking = false`.
- Podmínka je **reaktivní na každou změnu stavu**: pokryje tah hráče, konec souboje (ať útočil kdokoli),
  restart hry. Nepsat procedurální „po tahu hráče zavolej AI“.
- Provider `aiOpponentProvider = Provider.autoDispose<AiOpponentController?>` — vrací `null` mimo single player;
  `GameScreen` ho ve `build` čte (`ref.watch`), aby žil po dobu obrazovky.

### `lib/core/ai/board_ai.dart` (v1)
```dart
abstract class BoardAi { Move chooseMove(GameState state, PlayerColor color); }
class RandomAi implements BoardAi { RandomAi(Random r); }  // náhodný legální tah (MoveGenerator z kroku 1 — v kroku 0 dočasně přes MoveValidator.getLegalMoves)
```

### `lib/features/game/presentation/screens/lobby_screen.dart`
- Nové tlačítko **„Single Player“** (ikona `Icons.smart_toy`) nad řádkem Create/Local.
- Dialog `_SinglePlayerDialog`: SegmentedButton obtížnost (default Medium), SegmentedButton barva
  (default White), tlačítko Start. Výsledek → `startSinglePlayerGame(...)` → `push(GameScreen)`.
- Poslední volbu obtížnosti/barvy držet v `StateProvider` (bez persistence).

### `lib/features/game/presentation/widgets/board/game_board.dart` — animace tahu soupeře
Dnes se `_currentMoveAnim` nastavuje jen v `_handleTap`; tah AI (i vzdálený tah v multiplayeru) skočí bez animace.
- Přidat `ref.listen(gameStateProvider, (prev, next) { … })`: pokud `next.moveHistory.length > prev.moveHistory.length`
  a poslední tah **nebyl** spuštěn lokálně (privátní flag `_locallyAnimated` nastavený v `_handleTap`, po animaci reset),
  nastavit `_currentMoveAnim` / `_currentCaptureAnim` ze `moveHistory.last` a spustit controllery.
- Pozor: u capture v single playeru se do `moveHistory` tah zapíše až po souboji (`resolveBattle`), stav před tím
  jen přejde do `phase == battle`. Animaci tahu AI s capture spustit při přechodu do `battle` z `pendingBattleMove`
  (přehraje se „nájezd“ a pak se otevře aréna), po `resolveBattle` už neanimovat znovu (porovnávat `moveCount`).

### `lib/features/game/presentation/screens/game_screen.dart`
- `_PlayerInfoBar` AI hráče: místo pulzujícího „TURN“ zobrazit „THINKING…“ (čte `aiOpponentProvider?.isThinking`
  přes `ValueNotifier<bool>`).
- Leave tlačítko zůstává jen pro multiplayer.

**Akceptace kroku 0:** z lobby odehraju celou partii proti náhodné AI na obou barvách, včetně soubojů
(AI loď zatím stojí), overlay „New Game“ startuje znovu single player, tahy AI se animují,
během tahu AI nejde tapnout na figurky.

---

## Krok 1 — Generátor tahů, sdílený registr validátorů, odhad šance v souboji

### `lib/core/game_logic/validators/validator_registry.dart`
`PieceValidator validatorFor(Piece piece)` — přesunout mapu + Last Warrior větev z `MoveValidator`
a `ThreatAnalyzer` sem; oba na něj přepnout. Žádná změna chování (testy validátorů to hlídají).

### `lib/core/ai/move_generator.dart`
```dart
class MoveGenerator {
  /// Všechny legální tahy [color] bez ohledu na state.currentTurn. Captures napřed.
  static List<Move> generate(GameState state, PlayerColor color);
}
```
Iteruje `board.findPieces(color: color)`, `validatorFor(piece).getLegalMoves(board, pos, color)`;
`Move` sestaví stejně jako `MoveValidator.createMove` (včetně `isSnipe`: střelec, ne Last Warrior,
stejný sloupec, |Δrow| == 3). Vrací `[]` pokud `state.isFinished`.

### `lib/core/ai/battle_odds.dart`
```dart
class BattleOdds {
  /// P(útočník vyhraje), clamp [0.1, 0.9].
  static double attackerWinProbability(Piece attacker, Piece defender,
      UpgradeProfile attackerUpgrades, UpgradeProfile defenderUpgrades);
  /// Čas do zabití cíle v ms, obě lodě stojí (deterministické).
  static int timeToKillMs(UnitStats shooter, UnitStats target);
}
```
- `netDamage = dmg − round(dmg · target.defenseRating)` (přesně jako `BattleEngine._applyHit`),
  `shots = ceil(target.maxHp / netDamage)`, `TTK = shots · shooter.attackIntervalMs + travelMs(shooter.weaponType)`.
- `p = sigmoid(k · (TTK_def − TTK_att) / ((TTK_def + TTK_att)/2))`, `k = 3`, clamp.
- Vyžaduje zveřejnit rychlost projektilu: `BattleEngine.projectileSpeed(WeaponType)` (dnes privátní
  `_projectileSpeed` klíčovaná stringem — přepsat na `Map<WeaponType, double>`).

**Akceptace:** testy `move_generator_test` (shoda s `MoveValidator.getLegalMoves` pro figurku na tahu;
generuje i pro barvu mimo tah; `capturedPiece` a `isSnipe` správně), `battle_odds_test`
(pěšec→král < 0.2, král→pěšec > 0.8, stejné jednotky = 0.5, pořadí shodné se simulací
`BattleEngine.tick` s oběma loděmi v klidu pro všech 36 dvojic typů).

---

## Krok 2 — Ohodnocení pozice, Easy a Medium

### `lib/core/ai/board_evaluator.dart`
```dart
class EvalWeights { material, powerField, powerFieldReach, infiltration, threat, mobility, royal; const … ; static const standard; }
class BoardEvaluator {
  static const double win = 1e6;
  static double evaluate(GameState s, PlayerColor pov, {EvalWeights w = EvalWeights.standard,
      UpgradeProfile? povUpgrades, UpgradeProfile? oppUpgrades});
  static double pieceValue(Piece p, UpgradeProfile up); // bojová síla × role
}
```
Složky (kladné = dobré pro `pov`):

| Složka | Výpočet | Startovní váha |
|---|---|---|
| Terminál | `isFinished`: `winner == pov ? +win : −win` | — |
| Materiál | Σ `pieceValue` mé − soupeřovy. `pieceValue = (maxHp · dmg / attackIntervalMs / (1 − defense)) ^ 0.5 · roleMult`; role: pěšec 1.0 (+ infiltrace zvlášť), jezdec/střelec 1.0, věž 1.1, královna 1.6, král 1.8, Last Warrior 0.6 | 1.0 |
| Power fieldy | `powerFieldCount(pov) − powerFieldCount(opp)`; 4/5 navíc bonus ×2 | 30 |
| Dosah PF | za každý volný/soupeřův PF, na který mám tah: +1; soupeř: −1 | 8 |
| Infiltrace | pro každý pěšec `(7 − dist_k_zadní_řadě)²`, pěšec na předposlední řadě, na který soupeř nemá tah: +200 | 3 |
| Ohrožení | Σ přes ohrožené figurky (`ThreatAnalyzer` obě strany): `−p(útočník vyhraje) · pieceValue`; pro soupeře +; jen když `useThreatTerm` | 0.8 |
| Mobilita | `MoveGenerator.generate(pov).length − opp` | 0.5 |
| Královské | `!hasKing` / `!hasQueen`: −150 každé; navíc Last Warrior už je v materiálu | 1.0 |

**Symetrie** (test): pozice zrcadlená přes střed desky (řádek `7−r`, sloupec `7−c`) s prohozenými barvami
a prohozeným `currentTurn` dává `evaluate(pov: white) == −evaluate(mirror, pov: black)` (tolerance 1e-9).

### `lib/core/ai/board_ai.dart` (v2)
```dart
class GreedyAi implements BoardAi {
  GreedyAi({required AiProfile profile, required Random random,
            required UpgradeProfile ownUpgrades, required UpgradeProfile oppUpgrades});
  // pro každý tah: tichý → evaluate(applyMove); capture →
  //   p·evaluate(resolveBattle(applyMove(s,m,triggerBattle:true), m, me))
  // + (1−p)·evaluate(resolveBattle(…, m, opp));  + random·evalNoise; argmax
}
```
`Easy` = `GreedyAi` s `evalNoise 40`, `useThreatTerm false`. `Medium` = `GreedyAi` s `evalNoise 5`.
Tie-break náhodný (stejné skóre → náhodný z nejlepších), ať AI nehraje pořád stejně.

**Akceptace:** `board_evaluator_test` (symetrie; 4/5 PF > 2/5; pěšec na řadě 6 > na řadě 1; ztráta krále
horší než ztráta věže), `board_ai_test` (Greedy najde výhru na 1 tah pro všechny 3 podmínky;
Medium **neobětuje** pěšce na krále, když je k dispozici tichý tah; 200 partií Random×Random a
50 Medium×Medium: žádný nelegální tah, každá skončí do 300 tahů nebo je ukončena limitem bez výjimky).

---

## Krok 3 — Hard: alpha-beta s expectimax uzly

### `SearchAi` v `board_ai.dart`
- Negamax + alpha-beta, hloubka `searchDepth = 3`, iterativní prohlubování 1→2→3 s `timeBudgetMs`;
  vrátí nejlepší tah z poslední **dokončené** hloubky.
- Capture tah = **chance node**: hodnota = `p·search(větev útočník vyhrál) + (1−p)·search(větev obránce vyhrál)`.
  Alpha-beta přes chance node: ořezávat jen konzervativně (obě větve prohledat, bez ořezu uvnitř);
  stačí pro hloubku 3.
- Move ordering: captures podle `p · pieceValue(cíl)` sestupně, pak tahy na power field, pak zbytek.
- Quiescence: po dosažení hloubky 0 ještě jen capture tahy s `p ≥ 0.6`, max +2 ply.
- Terminál: `isFinished` → `±win` s korekcí na hloubku (`win − ply`), ať preferuje rychlejší výhru.

### Výkon
- Odhad: větvení ~35, hloubka 3 ≈ 40k listů; `BoardState.movePiece` kopíruje 8×8.
- **Změřit** v release na Androidu (medián z 20 tahů z otevřené pozice). Pokud > 150 ms:
  přesunout `chooseMove` do `compute()` (`GameState` je Freezed s JSON; `AiProfile`/upgrady poslat jako mapy),
  `AiOpponentController` výsledek ignoruje při změně `_generation`.
- Až kdyby ani to nestačilo (> 800 ms): inkrementální materiál z `Move` místo celé desky. Transpoziční tabulka ne.

**Akceptace:** Hard najde mat-in-2 (pěšec dva kroky od zadní řady, soupeř ho neumí zastavit; Greedy ho nevidí),
Hard neobětuje figurku bez kompenzace, `Hard vs Medium` self-play (20 partií, seed) ≥ 70 % výher Hard
(test s `@Tags(['slow'])`, mimo default `flutter test` přes `--exclude-tags slow` v CI).

---

## Krok 4 — Battle AI (realtime aréna)

### `lib/core/ai/battle_ai.dart`
```dart
class BattleAiAction { final double? targetX; final bool activateShield; }
class BattleAi {
  BattleAi({required AiProfile profile, required Random random});
  BattleAiAction decide(BattleState state, {required bool isAttacker, required int deltaMs});
}
```
Interní stav: `_sinceDecisionMs`, `_targetX`, historie posledních 3 pozic soupeře (predikce na Hard).

Každý tick:
1. `_sinceDecisionMs += deltaMs`; pokud `< reactionMs` → jen dojíždět k `_targetX` (krok 4), jinak nové rozhodnutí:
2. **Hrozby**: projektily s `fromAttacker != isAttacker`; pro každý `hits = |p.xFraction − myX| ≤ hitHalfWidth`,
   `etaMs = (1 − p.positionFraction) / projectileSpeed(soupeřova zbraň)`.
3. **Cíl**: `aim = soupeřX` (Hard: `soupeřX + v·(travelMs)` z historie). Pokud na `aim` dopadne střela s
   `etaMs < dodgeWindowMs`, posunout o `±(hitHalfWidth + 0.03)` na stranu s menším počtem střel;
   respektovat `[shipEdgeMargin, 1 − shipEdgeMargin]`. Úhyb má přednost před mířením.
   Přičíst `aimError · (random·2 − 1)`. Uložit `_targetX`.
4. **Pohyb**: `step = maxShipSpeed · deltaMs / 1000`; `newX = myX + clamp(_targetX − myX, −step, step)`;
   vrátit `targetX: newX` (jen když se liší od `myX`).
5. **Štít**: `shieldState.canActivate` a existuje hrozba s `hits` a
   (`|_targetX − myX| / maxShipSpeed · 1000 > etaMs` **nebo** `p.damage_net ≥ currentHp`)
   → `activateShield = random.nextDouble() < shieldSkill`. Rozhodnutí o štítu se dělá **každý tick**
   (ne jen po `reactionMs`), jinak Hard štít nestihne.

### `lib/features/battle/presentation/providers/battle_state_provider.dart`
- `startBattle({required initial, required attackerColor, BattleAi? ai, bool aiIsAttacker = false})`.
- V `_onTick` po `BattleEngine.tick`: `if (ai != null) { final a = ai.decide(next, isAttacker: aiIsAttacker, deltaMs: d); if (a.targetX != null) next = BattleEngine.moveShip(next, aiIsAttacker, a.targetX!); if (a.activateShield) next = BattleEngine.activateShield(next, aiIsAttacker); }`
  — **přímo na engine**, ne přes `moveLocalShip/activateLocalShield` (ty posílají na transport a throttlují).
- `stopBattle` nuluje `ai`.

### `lib/features/game/presentation/screens/game_screen.dart`
V `ref.listen`, kde se volá `startBattle`: v `singlePlayer` předat `BattleAi(profile, random)` a
`aiIsAttacker = attackerColor == notifier.aiColor`. Upgrady: `upgradeProfileProvider(color)` — viz krok 5.

`BattleScreen` beze změn. `GameStateNotifier.activateShield/moveShip` jsou `_session?.` → no-op.

**Akceptace:** `battle_ai_test` (Hard z klidu uhne jediné střele, která by ho zasáhla; při `maxShipSpeed 0.2`
a střele v 0.9 uhnout nestihne a při `shieldSkill 1.0` aktivuje štít; Hard porazí stojícího soupeře se stejnou
jednotkou; `Easy vs Hard` stejná jednotka, 50 seedovaných simulací přes `BattleEngine.tick` po 16 ms → Hard
vyhraje > 80 %). Ručně: souboj pěšec vs. pěšec na Easy se dá vyhrát, na Hard je těsný.

---

## Krok 5 — Progres flotily (hráč i AI), Comcenter, uložení

### `lib/core/game_logic/models/fleet_progress.dart`
```dart
class FleetProgress {
  final int credits; final UpgradeProfile profile; final int gamesPlayed; final int wins;
  const FleetProgress({this.credits = 0, this.profile = const UpgradeProfile(), this.gamesPlayed = 0, this.wins = 0});
  FleetProgress copyWith(...); Map<String, dynamic> toJson(); factory FleetProgress.fromJson(Map<String, dynamic>);
  int get totalLevels => profile.levels.values.fold(0, (a, b) => a + b);
}
```
`UpgradeProfile` dostane `toJson/fromJson` (klíče `type.name`, stejný tvar jako `UpgradeRepository`).
Plain class, bez Freezed (netřeba build_runner).

### `lib/core/ai/fleet_progression.dart`
```dart
class FleetProgression {
  /// Utratí kredity AI za upgrady. Vrací nový FleetProgress. Nikdy nepřekročí rubber band.
  static FleetProgress spend(FleetProgress ai, FleetProgress player, AiProfile profile,
      {required Map<PieceType, int> battlesFoughtByType, required Random random});
}
```
Politika: opakovat, dokud existuje kandidát: `type` s `level < 3`, `upgradeCost(level) ≤ credits`,
a `ai.totalLevels + 1 ≤ player.totalLevels + rubberBandOffset`. Výběr: nejvyšší `battlesFoughtByType`,
tie → nejlevnější, tie → náhodný. Hard navíc: královna/král mají prioritu, pokud padly v této hře.

### `lib/features/progress/data/fleet_progress_store.dart`
```dart
class FleetProgressStore {
  FleetProgressStore(SharedPreferences prefs);
  FleetProgress load(String identity);                    // klíč 'fleet_progress.<identity>', chybí → FleetProgress()
  Future<void> save(String identity, FleetProgress p);
}
```
Závislost: `shared_preferences: ^2.3.0` do `pubspec.yaml`. Testy přes `SharedPreferences.setMockInitialValues`.

### `lib/features/progress/presentation/providers/fleet_progress_provider.dart`
- `fleetProgressStoreProvider` (`SharedPreferences.getInstance()` v `main()` před `runApp`, předat přes override).
- `fleetProgressProvider = StateNotifierProvider.family<FleetProgressNotifier, FleetProgress, String>` —
  `load` v konstruktoru, každá změna → `save`.
- Identity: hráč `'player'`, AI `profile.identity`.

### Tok kreditů v single playeru
1. Start hry: `upgradeProfileProvider(humanColor) = player.profile`, `upgradeProfileProvider(aiColor) = ai.profile`
   (nastavit v `startSinglePlayerGame` přes controller, ne v enginu).
2. `GameStateNotifier.onBattleReward(winner, credits)` → `fleetProgressProvider(identity vítěze).addCredits(credits)`;
   controller počítá `battlesFoughtByType` pro AI.
3. Konec hry (`phase == finished`, jednou — hlídat `gameId`): `gamesPlayed++`, vítěz `wins++`;
   AI: `FleetProgression.spend(...)` → uložit.
4. Hot-seat, WiFi a online zůstávají beze změny (odměna se tam dál ignoruje — mimo rozsah).

### Comcenter
`comcenter_screen.dart` má privátní `_upgradeProfileProvider`/`_creditsProvider` nezávislé na aréně.
Přepnout na `fleetProgressProvider('player')`: kredity i upgrady hráče z jednoho místa, `_upgrade` volá
`notifier.upgrade(type)`. `upgradeProfileProvider`/`playerCreditsProvider` v `battle_state_provider.dart`
zůstávají jako per-color pohled na aktuální partii (plní se v bodě 1).

### UI
- Dialog Single Player: u každé obtížnosti řádek „flotila: Σ levelů, kredity, bilance W/L“ z `fleetProgressProvider(identity)`.
- Game over overlay v single playeru: „+N cr“ pro hráče.

**Akceptace:** `fleet_progression_test` (nepřekročí rubber band; s offsetem 0 a hráčem na 0 neutratí nic;
utrácí za nejvíc bojující typ; nikdy nad level 3; kredity neztrácí), `fleet_progress_store_test`
(round-trip JSON, chybějící klíč → default). Ručně: po restartu appky flotily drží stav; Comcenter upgrade
hráče se projeví v aréně (vyšší HP jednotky).

---

## Krok 6 — Dokumentace a úklid

- `README.md`: režim Single Player, obtížnosti, progres flotily. `CHANGELOG.md` záznam. `CLAUDE.md`: `lib/core/ai/`
  a `lib/features/progress/` do architektury, `shared_preferences` do sekce závislostí.
- `flutter analyze` čisté, `flutter test` zelené, `flutter test --tags slow` projde lokálně.

---

## Vyvážení (ruční, po kroku 5)

- 10 partií na každé obtížnosti s flotilami na 0. Easy má prohrávat s běžným hráčem, Medium být vyrovnaný,
  Hard nepříjemný, ne neporazitelný.
- Páky: `maxShipSpeed`, `shieldSkill` (aréna); váha `threat`, `evalNoise`, hloubka (deska); `rubberBandOffset`.
- Hard: medián času na tah v release < 1 s na slabším Androidu; jinak snížit `timeBudgetMs`.

## Odhad

| Krok | Odhad |
|---|---|
| 0 režim, lobby, controller, RandomAi, animace tahu soupeře | 1 den |
| 1 generátor, registr validátorů, battle odds | 0.5 dne |
| 2 evaluator, Easy/Medium | 1 den |
| 3 Hard search, měření, případně isolate | 1–1.5 dne |
| 4 battle AI | 1 den |
| 5 progres flotily, store, Comcenter | 1 den |
| 6 dokumentace | 0.25 dne |

## Mimo rozsah (nezačínat, jen vědět)

- `GameEngine.resolveBattle` po výhře obránce neaktualizuje `hasKing/hasQueen` ani Last Warrior pro odstraněného
  útočníka a nekontroluje výhru. Existující mezera, AI ji zdědí; samostatná oprava později.
- Sync progresu do Supabase `user_upgrades`; auth; vlastní formace AI; kredity v hot-seat/WiFi/online.
