# Phase 5: Manévry — pohyb vpřed/vzad, gesta 3×3 a katalog manévrů

> Zadání pro implementaci. Rozhodnutí v tabulce „Uzavřená rozhodnutí“ jsou návrh
> a po schválení platí jako uzavřená. Postupuj po krocích 0→6, každý krok = samostatný
> commit, po každém `flutter analyze` bez varování a `flutter test --exclude-tags slow`
> zelené (dnes 222 testů). Větev z `main` (v0.7.0-alpha). Adresář `tools/fleet_art/`
> může být v pracovní kopii nesledovaný (pozůstatek větve `claude/fleet-art-tools`) —
> do commitů ho nepřidávat.

## Cíl

1. **Pohyb vpřed a vzad.** Tah prstem dopředu/dozadu dnes správně mění výšku (`altitude`),
   loď se ale posune jen o 8 % výšky arény. Nově loď cestuje po celé výšce své
   manévrovací plochy: při výšce 0 stojí u vlastního okraje, při výšce 1 těsně před
   dělicí čárou. Výška zůstává herní veličinou (pásmo zásahu), poloha vpřed/vzad je
   její zobrazení.
2. **Manévry na gesta.** Hráč pustí řídicí palec, na mřížce 3×3 (jako odemykací vzor
   Androidu) nakreslí gesto a loď převezme řízení: sama provede manévr (úhyb, looping,
   slalom, …) a během něj sama střílí. Manévry stojí energii, která se v bitvě dobíjí.
3. **Katalog manévrů.** Každá loď má 10+ manévrů (rodiny společné pro všechny lodě
   v lodní variantě + podpisové manévry). Hráč vlastní podmnožinu, do 4 aktivních slotů
   na loď si přiřazuje, které gesta v bitvě platí. Nové manévry se odemykají vítězstvími
   v realtime battle s danou lodí, kupují za kredity a část je vyhrazená balíčkům
   (in-app purchase — datový model ano, nákupní tok mimo rozsah).
4. **AI** umí manévry také (podle obtížnosti), **WiFi** soupeř je vidí.

Bez nové závislosti. Vše čisté Dart v `lib/core/`, UI ve `features/battle` a
`features/comcenter`.

---

## Uzavřená rozhodnutí

| # | Rozhodnutí | Volba |
|---|---|---|
| 1 | Řízení vpřed/vzad | **Relativní tah zůstává** (posun prstu → změna výšky), ale **1 : 1** — loď se posune přesně o tolik, o kolik se posunul prst. Absolutní poloha (loď pod palcem) by loď zakrývala a k dělicí čáře by se nedalo dosáhnout. |
| 2 | Kde se kreslí gesto | **Samostatná mřížka (`ManeuverPad`) v řádku ovládání** vedle panelu jednotky a štítu, ne přes arénu. Žádná dvojznačnost mezi řízením a gestem, v hot-seatu se otočí s ovládáním horního hráče. Alternativa (mřížka přes arénu s aktivací podržením) až kdyby pad nestačil. |
| 3 | Rozpoznávání | Pravidla Androidu: posloupnost **≥ 3 různých bodů**, přejetí přes nenavštívený bod ho vloží, **směr rozhoduje** (zrcadlový vzor = zrcadlový manévr, obrácený vzor = jiné gesto). Shoda jen **přesná** s aktivními manévry lodi. |
| 4 | Vzor patří manévru | Gesto je součástí definice manévru (jako tvar kouzla). Rodiny sdílejí vzor napříč loděmi, aby se svalová paměť přenášela; podpisové manévry mají vlastní tvar. Hráč vzory neupravuje. |
| 5 | Cena manévru | **Energie 0–100** na loď, start 50, dobíjí se 12/s. Basic 20–30, advanced 40–50, signature 60. Jedna páka na vyvážení. Během manévru se nedá spustit další. |
| 6 | Během manévru | Řízení hráče i síťové posuny se **ignorují** (engine `moveShip` vrací stav beze změny), štít jde aktivovat. Vlastní palba se pozastaví, střílí se jen podle plánu manévru (výjimka `Přetlak`, který řízení nechává). |
| 7 | Nezranitelnost | Jen krátká okna (≤ 0,5 s) u loopingu, výkrutu, průletu, spirály a skoku — střela v tu chvíli mine (bez záznamu dopadu). |
| 8 | Aktivní sloty | **4 na loď**, pevně. Rozšíření slotů mimo rozsah. Startovní sada: každá loď vlastní a má aktivní **Úskok** a **Výpad**. |
| 9 | Odemykání | Podmínka v katalogu: `starter` / `wins(n)` (vítězství v realtime battle s tou lodí, počítá se jen v single playeru, stejně jako kredity) / `credits(n)` / `pack(id)`. Vítězné odemčení proběhne automaticky po bitvě (toast ve výsledku). Vylepšení L2/L3 za kredity. |
| 10 | Balíčky (IAP) | Katalog zná `ManeuverPack {id, name, ids}` a `ManeuverStore.grant(packId)`. Reálný nákup (StoreKit / Play Billing) **mimo rozsah**; v debug buildu tlačítko „Odemknout balíček“ pro testování. |
| 11 | Hot-seat a WiFi | Obě strany létají se **startovní sadou** (stejně jako tam neplatí upgrady ani skiny). WiFi soupeř dostane `ManeuverStartedEvent` a spustí tentýž manévr u sebe; starší aplikace bez události vidí jen pohyb lodi z `ShipMovedEvent`, ne dávky střel. |
| 12 | AI | `AiProfile` dostane `maneuverSkill` a počet manévrů z katalogu lodi (Easy 2, Medium 4, Hard 6 vč. podpisového). Bez progresu, sada je pevná. |
| 13 | Zvuk manévru | Volitelné: jeden „whoosh“ při spuštění přes `BattleSoundCues`, vygenerovat `tools/battle_audio`. Když nebude čas, vynechat — dávky střel už zní samy. |

---

## Co v kódu už je a jak to využít

| Existující kód | Použití |
|---|---|
| `BattleEngine` (`core/game_logic/engine/battle_engine.dart`): `tick`, `moveShip(state, isAttacker, x, {altitude})`, `activateShield`, `_tickAttack` (střílí, když `nextAttackMs ≤ 0`), `_isHit` (pásma `hitHalfWidth 0.07`, `hitHalfAltitude 0.12`), `shipEdgeMargin 0.06`, `projectileSpeed` | Manévr se vyhodnocuje v `tick`: nastaví pózu lodi, střílí z plánu, blokuje `moveShip`. |
| `BattleUnit {piece, stats, currentHp, shieldState, nextAttackMs, xFraction, altitude}`, `Projectile {id, positionFraction, damage, fromAttacker, xFraction, altitude}`, `BattleState {…, impacts, elapsedMs}`, `Impact` | Přibude `BattleUnit.energy` a `BattleUnit.maneuver: ManeuverRun?`. Střely z manévru jsou obyčejné `Projectile` (dávka = víc střel, rozptyl = víc drah, nabitá = větší `damage`). |
| `BattleStateNotifier` (`features/battle/presentation/providers/battle_state_provider.dart`): 16 ms timer, `moveLocalShip({isAttacker, xFraction, altitudeDelta})` se sync throttlem 50 ms, `applyOpponentShipMove`, AI přes `BattleAiAction {targetX, targetAltitude, activateShield}`, posluchač `ShieldActivatedEvent`/`ShipMovedEvent` | Přibude `startLocalManeuver`, `applyOpponentManeuver`, AI akce `maneuver`. |
| `BattleScreen`: `_steerShip(dx, dy, …)` s `forward = inTopHalf ? dy : -dy`, `_altitudeDragFraction = 0.3`, `_pointerInTopHalf`; řádek `_PlayerBattleControls(unit, spriteAsset, label, onShield)` = `UnitCombatPanel` (80 px) + `ShieldButton` (80×80); horní hráč v hot-seatu v `RotatedBox(quarterTurns: 2)`; `BattleAudio.start/play/stop`, `_destruction` | Pad přijde do `_PlayerBattleControls`, otočí se s ním. Parametry `attackerSkin/defenderSkin` doplní `attackerManeuvers/defenderManeuvers`. |
| `BattleArenaPainter`: `shipY()` s `_shipMarginFraction 0.12` + `_altitudeLunge 0.08`, `_altitudeScale(alt) = 0.7 + 0.6·alt`, `_inShipFrame` (perspektiva `setEntry(3,2, 0.6/shipSize)` + `rotateY(-bank·_maxRoll)`, `_maxYaw`), `ShipBank`, `ExplosionFx`, `BattleElement`, `nowMs` | Krok 0 nahradí lunge mapováním na celou polovinu. Krok 3 přidá kanály postoje (roll/pitch/flip/boost), doznívající kopie a stopu gesta. |
| `BattleAi` (`core/ai/battle_ai.dart`): `_Spot`, `_chooseTarget`, `_dodge` (hledá bezpečné místo vedle dráhy / nad a pod výškou), `_shouldShield`, `AiProfile` | Manévr AI spustí tam, kde `_dodge` nenajde bezpečné místo, nebo když soupeř stojí v pásmu zásahu. |
| `GameEvent.fromJson` (`features/game/data/game_event.dart`), `ShipMovedEvent {color, xFraction, altitude}` s tolerantním čtením, `GameSession.sendShipMoved`, `GameStateNotifier.moveShip` | Stejný vzor pro `ManeuverStartedEvent`. |
| `FleetProgress {credits, profile, gamesPlayed, wins, skin}` s tolerantním `fromJson`, `FleetProgressNotifier {addCredits, upgrade, recordGame, setSkin, replace}`, `fleetProgressProvider(identity)`, `playerFleetIdentity` | Přibude `maneuvers` a `battleWins`; JSON zpětně kompatibilní (chybějící pole = startovní sada). |
| `GameStateNotifier.onBattleReward(winner, credits)` volané z `resolveBattle`, `AiOpponentController._onBattleReward`, `upgradesFor`, `skinFor` | Přibude `onBattleResolved(Piece winner)` vedle `onBattleReward`; controller z něj započítá vítězství hráčovy lodi a zveřejní `maneuversFor(color)`. |
| `GameScreen._openBattle` staví `BattleScreen(attackerColor, attackerSkin, defenderSkin)` | Doplní manévry obou stran. |
| `ComcenterScreen`: výběr flotily + mřížka `UpgradeCard`, čte `fleetProgressProvider(playerFleetIdentity)` | Přibude záložka Manévry. |
| `BattleSoundCues.between(prev, next)` diffuje střely a dopady | Dávky z manévru zní bez změny; volitelný cue `maneuverStarted`. |
| `test/core/ai/battle_ai_test.dart` (`fight`, `incomingShot`, `defend`), `battle_engine_test.dart`, `battle_arena_painter_test.dart` (offscreen `paint`) | Vzory pro nové testy. |

---

## Struktura nových souborů

```
lib/core/maneuvers/
├── maneuver.dart              # Maneuver, ManeuverFamily, ManeuverTier, Unlock, Keyframe, Anchor, Attitude, FireCue, LevelBonus, Ease
├── maneuver_catalog.dart      # ManeuverCatalog.forShip(PieceType), byId(String), packs, starterIds(PieceType)
├── maneuver_pattern.dart      # Pattern: validace (≥3, různé, pravidlo mezilehlého bodu), mirror(), equals
└── pattern_recognizer.dart    # PatternRecognizer: body prstu v jednotkovém čtverci → List<int> (bez Flutteru)

lib/core/game_logic/models/
└── maneuver_run.dart          # ManeuverRun {id, level, startedMs, origin, enemyAtStart, firedCues}

lib/core/ai/
└── battle_ai.dart             # + BattleAiAction.maneuver, výběr manévru podle profilu

lib/features/battle/presentation/
├── widgets/arena_layout.dart  # ArenaLayout: shipY(altitude, atBottom, size), travelFraction — sdílí painter i vstup
├── widgets/maneuver_pad.dart  # 3×3 pad, stopa, energie, nápověda aktivních gest
├── widgets/pattern_glyph.dart # miniatura vzoru (pad, Comcenter, toast)
└── widgets/battle_arena_painter.dart  # + postoj lodi z manévru, doznívající kopie, stopa gesta

lib/features/comcenter/presentation/
├── screens/comcenter_screen.dart      # záložky Jednotky | Manévry
└── widgets/maneuver_card.dart

lib/features/game/data/game_event.dart # + ManeuverStartedEvent

test/core/maneuvers/            # maneuver_catalog_test, pattern_recognizer_test, maneuver_pose_test
test/core/game_logic/engine/    # battle_engine_test (+ manévry, energie)
test/features/battle/           # arena_layout_test, maneuver_pad_test, painter (+ pózy)
test/features/progress/         # fleet_progress_store_test (+ manévry, kompatibilita)
```

---

## Krok 0 — Pohyb vpřed a vzad po celé manévrovací ploše

### `lib/features/battle/presentation/widgets/arena_layout.dart`
```dart
/// Where a ship sits in its half of the arena for a given altitude: at its own
/// edge when lowest, just short of the divider when highest.
class ArenaLayout {
  static const double edgeMargin = 0.08;      // podíl výšky arény od vlastního okraje
  static const double frontMargin = 0.06;     // podíl výšky arény od dělicí čáry
  static double get travelFraction => 0.5 - edgeMargin - frontMargin;   // 0.36

  static double shipY(double altitude, {required bool atBottom, required Size arena}) {
    final travel = altitude * travelFraction * arena.height;
    return atBottom
        ? arena.height * (1 - edgeMargin) - travel
        : arena.height * edgeMargin + travel;
  }
}
```
- `BattleArenaPainter`: `shipY()` volá `ArenaLayout.shipY`, `_shipMarginFraction` a
  `_altitudeLunge` zrušit. Strop velikosti spritu `arena.height * _shipMarginFraction * 2.2`
  nahradit `arena.height * 0.2`. `_altitudeScale` 0,7–1,3 nechat (doladit okem — s viditelným
  posunem možná stačí 0,8–1,2).
- `BattleScreen._steerShip`: `altitudeDelta = forward / (constraints.maxHeight * ArenaLayout.travelFraction)`;
  `_altitudeDragFraction` zrušit. Loď se posune přesně o posun prstu.
- Střely a dopady už používají `attackerY/defenderY`, nic dalšího.
- Test `arena_layout_test`: výška 0 → okraj, 1 → před dělicí čárou, spodní i horní loď, monotónní.
- Rychlá kontrola okem: offscreen render (dočasný test jako v předchozích krocích) s loděmi
  na výškách 0 / 0,5 / 1.

---

## Krok 1 — Model manévru, katalog, rozpoznávání gesta (čisté Dart)

### `lib/core/maneuvers/maneuver.dart`
```dart
enum ManeuverFamily { sidestep, strike, retreat, slalom, loop, roll, feint, shadow, volley, dash, spiral, overdrive, signature }
enum ManeuverTier { starter, basic, advanced, signature, pack }
enum Anchor { origin, enemyAtStart, enemyLive }
enum Ease { linear, easeIn, easeOut, easeInOut }

sealed class Unlock { const Unlock(); }
class StarterUnlock extends Unlock { const StarterUnlock(); }
class WinsUnlock extends Unlock { final int wins; const WinsUnlock(this.wins); }
class CreditsUnlock extends Unlock { final int credits; const CreditsUnlock(this.credits); }
class PackUnlock extends Unlock { final String packId; const PackUnlock(this.packId); }

/// How the ship is drawn at a keyframe; the painter interpolates between them.
class Attitude {
  final double roll;   // otáčky kolem podélné osy, kumulativně (1.0 = celý výkrut)
  final double pitch;  // -1 příď dolů … 1 příď nahoru
  final double flip;   // 0 normálně … 1 vzhůru nohama (looping)
  final double boost;  // 0–1 plamen motoru
  const Attitude({this.roll = 0, this.pitch = 0, this.flip = 0, this.boost = 0});
}

class Keyframe {
  final double t;                 // 0–1 průběhu manévru
  final Anchor xAnchor; final double dx;
  final Anchor altAnchor; final double dAlt;
  final Ease ease;                // z předchozího keyframu do tohoto
  final Attitude attitude;
  const Keyframe({...});
}

class FireCue {
  final double t;
  final int shots;                // střel v jedné dávce
  final double spread;            // rozestup drah (x) při shots > 1, 0 = stejná dráha
  final double damage;            // násobek stats.damage
  const FireCue(this.t, {this.shots = 1, this.spread = 0, this.damage = 1});
}

class LevelBonus {                // L2 = levels[0], L3 = levels[1]
  final int energyCost; final int durationMs; final int extraShots; final int untouchableMs;
}

class Maneuver {
  final String id;                // 'knight.jump'
  final PieceType ship;
  final ManeuverFamily family;
  final ManeuverTier tier;
  final String name;              // 'Skok'
  final String description;
  final List<int> pattern;        // body 0–8
  final bool mirrorable;          // zrcadlený vzor spustí manévr s dx → −dx
  final int durationMs;
  final int energyCost;
  final List<Keyframe> path;      // prázdné u overdrive (keepsControl)
  final List<FireCue> fire;
  final (double, double)? untouchable;   // t od–do
  final bool shield;              // aktivuje štít na startu (pokud canActivate)
  final bool keepsControl;        // Přetlak: řízení zůstává hráči, mění se jen palba
  final double fireRateMultiplier;// 1 = beze změny (Přetlak 0.6)
  final Unlock unlock;
  final List<LevelBonus> levels;

  ManeuverPose poseAt(double t, ManeuverContext ctx);   // interpolace keyframů, anchory z ctx
  int costAt(int level); int durationAt(int level); (double, double)? untouchableAt(int level);
}
class ManeuverContext { final Spot origin; final Spot enemyAtStart; final Spot enemyLive; }
class ManeuverPose { final double x; final double altitude; final Attitude attitude; }
```
- `poseAt`: keyframy setříděné podle `t`, první implicitně `t=0` = origin s neutrálním postojem.
  Mezi keyframy `ease` na podílu úseku; `x = anchor.x + dx`, `alt = anchor.alt + dAlt`.
  Clampování dělá engine. Zrcadlení: `dx → −dx` a `spread` beze změny, `roll → −roll`.
- `ManeuverCatalog.forShip(type)` vrací setříděný seznam (starter → signature). `byId`.
  `packs`: zatím jeden balíček `ace` (podpisové manévry všech lodí + Spirála), definice
  níže. `starterIds(type)` = Úskok + Výpad.
- Zásada: **žádný Flutter import** v `lib/core/maneuvers/` (testovatelné, sdílené s AI).

### `lib/core/maneuvers/maneuver_pattern.dart`
- Mřížka `0 1 2 / 3 4 5 / 6 7 8`. Dvojice se středovým bodem: (0,2)→1, (3,5)→4, (6,8)→7,
  (0,6)→3, (1,7)→4, (2,8)→5, (0,8)→4, (2,6)→4.
- `Pattern.isValid(dots)`: délka ≥ 3, bez opakování, každý úsek buď nemá mezilehlý bod, nebo
  je ten bod už navštívený (jinak by ho Android vložil — takový vzor by nešel nakreslit).
- `Pattern.mirror(dots)`: sloupec `c → 2 − c`.
- Test katalogu: každý manévr má validní vzor; v rámci lodi jsou vzory (včetně zrcadel
  u `mirrorable`) **navzájem různé**; startovní sada existuje pro každý typ; součet
  manévrů na loď ≥ 10; `poseAt(0)` = origin, `poseAt(1)` odpovídá poslednímu keyframu.

### `lib/core/maneuvers/pattern_recognizer.dart`
```dart
class PatternRecognizer {
  PatternRecognizer({this.hitRadius = 0.18});   // podíl strany padu
  final List<int> dots = [];
  void start(Offset p) / void move(Offset p);   // Offset z dart:ui je dovolený (bez Flutteru)
  List<int> end();                              // [] když < 3
}
```
- Body mřížky na `(0.2, 0.5, 0.8)`. Bod se přidá, když se prst dostane do `hitRadius`
  a bod ještě v posloupnosti není; před přidáním se vloží nenavštívený mezilehlý bod.
- Testy: rovná čára 3→4→5; přejetí 0→2 vloží 1; diagonála 0→8 vloží 4; návrat na
  navštívený bod nic nepřidá; kraťasy (< 3) vrací `[]`; třes prstu v okolí bodu nezdvojí.

### Rodiny manévrů (vzor, účinek, animace)

Pohled spodního hráče, „dopředu“ = nahoru na padu. `dx` v podílech šířky arény,
`dAlt` v podílech výšky 0–1. Časy a ceny jsou základ lodní varianty (viz tabulka lodí).

| Rodina | Vzor | Trvání / energie | Dráha a palba | Postoj a efekt |
|---|---|---|---|---|
| **Úskok** (sidestep) | `3→4→5` vpravo, zrcadlo `5→4→3` vlevo | 500 ms / 25 | `dx +0.22` easeOut, výška → `enemyAtStart` (navázání na výšku soupeře). Bez palby, L3 +1 střela na konci. | Ostrý náklon do pohybu (`roll 0.25` a zpět). |
| **Výpad** (strike) | `7→4→1` | 900 ms / 35 | Výška → `enemyLive` (t .4), střely t .4 a .65, návrat na `origin` výšku (t 1). | `pitch 1 → −1`, `boost 1`. |
| **Ústup** (retreat) | `1→4→7` | 700 ms / 20 | Výška → 0.1, `dx` ±0.15 od dráhy soupeře; `shield: true`. Bez palby. | `pitch −1`, štítová bublina. |
| **Slalom** | Z `0→1→2→4→6→7→8`, zrcadlo S | 1600 ms / 45 | `dx −0.2, +0.2, −0.2, 0` (4 půlvlny), výška → `enemyAtStart`; střela každých 200 ms, `damage 0.8`. | Střídavý `roll ±0.3`, yaw z `ShipBank`, doznívající kopie. |
| **Looping** | O `1→2→5→8→7→6→3→0` | 1800 ms / 50 | Výška `origin → 1.0` (t .35) → `0.0` (t .7) → `origin`; x drží; `untouchable (.25, .55)`; střely t .75 ×2 (vybrání dole). | `pitch 1`, `flip 0 → 1 → 0` (nahoře vzhůru nohama, průchod „hranou“), `pitch −1`, `boost`. |
| **Výkrut** (roll) | kosočtverec `1→5→7→3` vpravo, `1→3→7→5` vlevo | 700 ms / 30 | `dx ±0.18`, výška drží; `untouchable (.15, .65)`. Bez palby, L3 +1 střela. | `roll 1.0` (celá otáčka kolem podélné osy), stín se přesune. |
| **Finta** (feint) | V `0→7→2` (naznačí vlevo, jde vpravo), zrcadlo `2→7→0` | 800 ms / 30 | `dx −0.08` (t .3) → `+0.22` (t 1), výška → `enemyAtStart`; střela t .9. | Náklon se přetočí. |
| **Stín** (shadow) | „7“ `0→1→2→4→6` | 2000 ms / 45 | x i výška `enemyLive` (přilepí se na soupeře, uhýbá s ním); střela každých 300 ms. Soupeře zachrání jen štít. | Yaw ve směru sledování, cíl. kroužek nad soupeřem. |
| **Salva** (volley) | T `0→1→2→4→7` | 900 ms / 40 | Drží; 4 střely t .2/.4/.6/.8. Věž: 2 × `damage 1.5`; střelec: 1 × `damage 2.5` v t .7 s nabíjením. | Zpětný ráz (`dAlt −0.02` skok při každé střele), záblesk. |
| **Průlet** (dash) | diagonála `0→4→8` vpravo, `2→4→6` vlevo | 1000 ms / 40 | x → protější strana (`origin` zrcadlené kolem 0.5, clamp), výška → `enemyLive`; střely t .3/.5/.7; `untouchable (.2, .5)`. | Tvrdý `roll 0.4`, `boost 1`, 3 doznívající kopie. |
| **Spirála** (corkscrew) | `4→1→2→5→8→7→6→3` | 1500 ms / 50 | Výška `origin → 1.0 → origin`, x sinus ±0.15 (2 vlny); `roll 2.0`; `untouchable (.3, .7)`; střely t .5, .9. | Vývrtka, stín opisuje sinus. |
| **Přetlak** (overdrive) | blesk `2→3→4→5→6` | 3000 ms / 35 | `keepsControl`, `fireRateMultiplier 0.6`, bez dráhy. | `boost 1` po celou dobu, plamen motoru dvojnásobný. |

### Lodě: varianty a podpisové manévry

Každá loď má rodiny výše ve své variantě (globální násobky) a 1 podpisový manévr.
Rodiny, které lodi nesedí, vypadnou; i tak má každá ≥ 10.

| Loď | Varianta rodin | Vypadá | Podpisový manévr |
|---|---|---|---|
| **Pěšec** (kinetic) | trvání ×0.8, energie −5, `damage` střel 0.8 ale +1 střela v každé dávce | — | **Dvojkrok** `8→5→2→1`: dva rychlé skoky vpřed (`dAlt +0.25` ×2, 1200 ms), po každém dávka 3 střel. 50 en. |
| **Kůň** (water) | `untouchable` +100 ms, Slalom ×0.9 | Looping (kůň ho má) | **Skok** `0→3→6→7`, zrcadlo `2→5→8→7`: vyskočí (`dAlt +0.5` za 300 ms, `untouchable (.1, .6)`), dopadne o jednu dráhu vedle (`dx ±0.22`) na výšku soupeře (`enemyLive`) a vystřelí 2×. 1000 ms, 45 en. Šachový skok L. |
| **Střelec** (fire) | trvání ×1.2, Salva = nabitá střela | — | **Ostřelovač** `0→4→8→5→2`: 1200 ms stojí a nabíjí (zranitelný — riziko), v t .85 jedna střela `damage 3.0`, dvojnásobná velikost projektilu. 55 en. |
| **Věž** (ice) | trvání ×1.3, Úskok = **Rošáda** (`dx ±0.4`, dlouhý skok stranou), Výpad = **Válec** (pomalý postup vpřed s palbou každých 350 ms), Salva 2 × 1.5 | Looping, Spirála | **Hradba** U `0→3→6→7→8→5→2`: štít se zapne i na cooldownu a drží celý manévr (1500 ms), 3 těžké střely `damage 1.5`. 60 en. |
| **Dáma** (electric) | beze změny, Průlet + Stín zesílené (střely `damage 1.2`) | — | **Královský tanec** oblouk `6→3→0→1→2→5→8`: přejede celou šířku (`x 0.1 → 0.9` nebo naopak podle strany) na výšce soupeře, 6 střel, `untouchable` v rychlých úsecích (.15,.3) a (.6,.75). 1800 ms, 60 en. |
| **Král** (electric) | trvání ×1.3, energie +5, Ústup se štítem trvá 1000 ms | Looping, Spirála | **Koruna** M `6→3→0→4→2→5→8`: drží pozici se štítem, dvakrát (t .4, .8) vystřelí ze všech baterií — 3 střely v drahách `x −0.16, x, x +0.16` (`shots 3, spread 0.16`). 1600 ms, 60 en. |

Looping a Spirálu neumí jen těžké lodě (věž, král); akrobatické je mají všechny.
Názvy v UI jsou anglicky jako zbytek aplikace (Sidestep, Strike, Retreat, Slalom,
Loop, Barrel Roll, Feint, Shadow, Volley, Dash, Corkscrew, Overdrive; podpisové
Double Step, Leap, Sniper Shot, Bulwark, Royal Waltz, Crown; věž má Castle místo
Úskoku a Steamroller místo Výpadu, střelec Charged Shot místo Salvy).

Vzory podpisových manévrů nekolidují s rodinami (Skok = L vs. Ústup = svislice;
Ostřelovač = diagonála + hák vs. Průlet = holá diagonála; Koruna M vs. Slalom Z).
Test katalogu to hlídá.

### Odemykání a ceny (návrh, doladit)

| Tier | Manévry | Podmínka | Vylepšení L2 / L3 |
|---|---|---|---|
| starter | Úskok, Výpad | od začátku | 150 / 300 cr |
| basic | Ústup, Výkrut, Finta, Salva | `wins(2)` / `wins(3)` / `wins(4)` / `wins(5)` nebo 150 cr | 200 / 400 cr |
| advanced | Slalom, Průlet, Stín, Přetlak | `wins(7)` / `wins(9)` / `wins(11)` / `wins(13)` nebo 400 cr | 300 / 600 cr |
| signature | Looping, podpisový | `wins(16)` / `wins(20)` nebo 900 cr | 450 / 900 cr |
| pack | Spirála | balíček `ace` | 450 / 900 cr |

`LevelBonus`: L2 `energyCost −5, durationMs −10 %`; L3 navíc `extraShots +1` (kde se
střílí) nebo `untouchableMs +100` (kde se nestřílí).

---

## Krok 2 — Engine: energie, běh manévru, palba z plánu

### `lib/core/game_logic/models/maneuver_run.dart`
```dart
class ManeuverRun {
  final String id; final int level; final int startedMs;
  final Spot origin; final Spot enemyAtStart;
  final Set<int> firedCues;     // indexy FireCue, které už vystřelily
}
```
`Spot` = `({double x, double altitude})` — vytáhnout z `battle_ai.dart` (`_Spot`) do
`core/game_logic/models/spot.dart` a sdílet.

### `BattleUnit`
`+ double energy` (default 50), `+ ManeuverRun? maneuver`; `copyWith` s možností
`maneuver: null` (použít sentinel nebo `clearManeuver: true`).

### `BattleEngine`
- `static const maxEnergy = 100.0; energyPerSecond = 12.0;`
- `startManeuver(state, isAttacker, Maneuver m, {int level = 1, bool force = false})`:
  odmítne, když `isFinished`, `unit.maneuver != null`, nebo `energy < m.costAt(level)`
  (bez `force`; `force` používá síť). Odečte energii, uloží `ManeuverRun` s `origin` =
  aktuální póza, `enemyAtStart` = póza soupeře, `startedMs = elapsedMs`. `m.shield` →
  `activateShield`; u Hradby/Koruny štít i na cooldownu (`ShieldState` reset) — přidat
  parametr `ignoreCooldown` do `activateShield`.
- `tick`: energie `+ energyPerSecond·dt/1000` clamp; pro jednotku s během:
  `t = (elapsedMs − startedMs) / durationAt(level)`; `pose = catalog.byId(id).poseAt(t, ctx)`;
  `x/altitude` clamp (`shipEdgeMargin`, 0–1); pro každý `FireCue` s `cue.t ≤ t` a ne ve
  `firedCues` → vystřelit `shots` střel v drahách `x + spread·(i − (shots−1)/2)`,
  `damage = round(stats.damage · cue.damage)`, výška = aktuální; `nextAttackMs` se
  během manévru **nedekrementuje** (palba jen z plánu), u `keepsControl` naopak běží
  s `attackIntervalMs · fireRateMultiplier`. `t ≥ 1` → `maneuver = null`,
  `nextAttackMs = min(nextAttackMs, 200)`.
- `_isHit`: vrací `false`, když je cíl v `untouchableAt(level)` okně (střela mine, bez `Impact`).
- `moveShip`: když má jednotka běh a manévr nemá `keepsControl`, vrátí `state` beze změny.
- Katalog do enginu: `BattleEngine` je `const _()` se statickými metodami — `ManeuverCatalog`
  je statický, import z `core/maneuvers` je v pořádku (obojí čisté Dart).

### Testy (`battle_engine_test.dart`)
- Energie roste 12/s, strop 100; start odečte cenu; nedostatek energie nic nespustí;
  druhý start během běhu nic nespustí; `force` obejde energii.
- Úskok: po 500 ms je `x = origin + 0.22` (clamp u kraje), výška = soupeřova ze startu.
- Salva: přesně 4 střely v čase, `damage` podle násobku; Koruna: 3 dráhy s rozestupem.
- Looping: v `untouchable` okně střela mine bez dopadu, mimo okno zasáhne.
- `moveShip` během manévru ignorován, po skončení funguje; `nextAttackMs` po konci ≤ 200.
- Stín: x/výška sledují soupeře, který se během běhu hýbe.
- `BattleOdds` beze změny (stojící lodě manévry nepoužívají) — test „favourite wins“ zůstává.

---

## Krok 3 — Bitevní UI: pad, stopa, energie, animace

### `lib/features/battle/presentation/widgets/maneuver_pad.dart`
```dart
class ManeuverPad extends StatefulWidget {
  final List<(Maneuver, int level)> maneuvers;   // aktivní sloty
  final double energy;                           // 0–100
  final Color accent;                            // barva elementu lodi
  final bool enabled;                            // false během manévru
  final void Function(Maneuver, {required bool mirrored}) onManeuver;
  final VoidCallback onNoMatch;
}
```
- Čtverec 120 px, 3×3 bodů, `Listener` (ne GestureDetector — stejné důvody jako v aréně).
  Stopa mezi body v barvě elementu, aktuální úsek k prstu. `PatternRecognizer` v jednotkovém
  čtverci. Na `end()`: hledej mezi `maneuvers` přesnou shodu `pattern` nebo, u
  `mirrorable`, `Pattern.mirror(pattern)` → `onManeuver(m, mirrored:)`; jinak `onNoMatch`
  (pad se otřese a blikne červeně 250 ms). Nedostatek energie: stopa zešedne, hláška „energie“.
- Pod padem **energie**: tenký pruh s ryskami na cenách aktivních manévrů. Vedle padu
  sloupec 4 miniatur `PatternGlyph` (název + cena), zašedlé, když na ně energie nestačí —
  hráč se gesta učí přímo v bitvě.
- Řádek `_PlayerBattleControls`: `[UnitCombatPanel 80] [ManeuverPad + energie] [nápověda] [štít 80]`,
  horizontální padding zmenšit z 32 na 16, mezery 8. Na 360 px šířky se vejde (80+120+~60+80).
  Kdyby ne: nápovědu skrýt pod 380 px. Aréna přijde o ~45 px výšky.
- Hot-seat: horní hráč má pad v `RotatedBox` — „dopředu“ na padu = od něj, správně.
  WiFi: soupeřův řádek zůstává jen `UnitCombatPanel`.

### `BattleScreen`
- Parametry `attackerManeuvers`, `defenderManeuvers: List<(Maneuver, int)>` (default
  startovní sada z katalogu). `GameScreen._openBattle` je naplní: single player z
  `ai.maneuversFor(color)` (krok 5), jinak startovní sada.
- `onManeuver` → `battleStateProvider.notifier.startLocalManeuver(isAttacker:, maneuver:, level:, mirrored:)`.
  Zrcadlení: předat enginu manévr už zrcadlený (`Maneuver.mirrored()` vrátí kopii s
  převrácenými `dx`, `roll`, `id + '#m'` jen pro běh; katalog ho nezná — `ManeuverRun`
  proto nese i `mirrored: bool` a engine zrcadlí při `poseAt`). Zvol druhé: `ManeuverRun.mirrored`.
- Toast v `_BattleHeader`: název manévru velkými písmeny v barvě elementu, 900 ms.
- Řízení během manévru: `_steerShip` volá dál (engine ignoruje); po skončení se x
  vrátí pod palec při dalším pohybu — přijatelné.

### `BattleArenaPainter`
- Póza lodi: když `unit.maneuver != null`, `pose = catalog.byId(run.id).poseAt(t, ctx)`
  (stejný výpočet jako engine — vytáhnout do `ManeuverRun.poseIn(state, isAttacker)`
  v core, aby painter i engine volaly totéž). Painter použije `pose.attitude`:
  - `roll` → `rotateY(roll · 2π)` v `_inShipFrame` (přičte se k náklonu z `ShipBank`);
  - `pitch` → `rotateX(pitch · 0.5)` + stín se posune dopředu/dozadu podle znaménka;
  - `flip` → `rotateX(flip · π)` — loď projde „hranou“ (zúží se na čáru) a ukáže spodek
    (sprite zrcadlený svisle, ztmavený o 30 %);
  - `boost` → plamen motoru: kruh za zádí `radius · (1 + boost)`, barva elementu.
- **Doznívající kopie** během manévru: painter si (mimo `BattleState`, v `_BattleScreenState`)
  drží posledních 6 póz po 50 ms a kreslí sprite s alfou 0.35 → 0.05.
- **Nezranitelnost**: pulzující obrys v barvě elementu (`stroke 2`, alfa 0.4–0.8).
- **Stopa gesta**: po spuštění se nad lodí na 600 ms vykreslí nakreslený vzor (3×3, čáry
  v barvě elementu, roztažený na 0.5 velikosti lodi, alfa doznívá).
- Střely: velikost projektilu škálovat `damage / shooter.stats.damage` (nabitá střela
  střelce je 2×, dávky pěšce 0.8×).

### Testy
- `maneuver_pad_test` (widget): nakreslený vzor 3→4→5 spustí Úskok; zrcadlo spustí
  `mirrored: true`; neznámý vzor → `onNoMatch`; `enabled: false` nic.
- `battle_arena_painter_test`: stav s běžícím Loopingem v t 0.2/0.5/0.8 a Výkrutem se
  vykreslí (`returnsNormally`), s i bez spritu.
- Offscreen render (dočasný test) šesti fází loopingu a výkrutu → poslat uživateli.

---

## Krok 4 — Síť a AI

### `ManeuverStartedEvent`
```dart
class ManeuverStartedEvent extends GameEvent {
  final PlayerColor color; final String maneuverId; final int level; final bool mirrored;
  final double originX, originAltitude, enemyX, enemyAltitude;
  // JSON 'maneuver_started'; fromJson toleruje chybějící mirrored/level
}
```
- `GameSession.sendManeuverStarted(...)`, `GameStateNotifier.startManeuver(...)` (jen
  přeposílá jako `moveShip`), `BattleStateNotifier`: posluchač událostí volá
  `applyOpponentManeuver` → `BattleEngine.startManeuver(force: true)` s dodaným
  `origin/enemyAtStart` (přidat volitelné parametry). Po dobu běhu se `ShipMovedEvent`
  pro tu loď ignoruje (engine to dělá sám).
- Vysílající strana posílá `ShipMovedEvent` dál i během manévru (z pózy enginu) kvůli
  starším klientům.
- Test: round-trip JSON, tolerantní čtení.

### `BattleAi`
- `AiProfile`: `+ double maneuverSkill` (Easy 0.2, Medium 0.5, Hard 0.85),
  `+ int maneuverCount` (2 / 4 / 6). Sada = prvních N z `ManeuverCatalog.forShip(type)`
  (starter → signature), level 1.
- `BattleAiAction`: `+ Maneuver? maneuver, bool mirrored`.
- Rozhodnutí (jen v okamžiku steering decision, tj. každých `reactionMs`, a jen když
  `me.maneuver == null` a energie stačí):
  1. **Únik**: `_dodge` nenašel bezpečné místo, nebo lethal střela a štít na cooldownu →
     s pravděpodobností `maneuverSkill` spusť nejlevnější vlastněný z rodin
     `roll, loop, dash, sidestep` (v tomto pořadí preferencí), zrcadleně směrem od střely.
  2. **Útok**: soupeř posledních `2·reactionMs` v pásmu zásahu (x i výška) →
     s pravděpodobností `maneuverSkill · 0.4` spusť `volley`, `strike`, `shadow` nebo
     podpisový (náhodně mezi vlastněnými).
  3. Jinak nic.
- `BattleStateNotifier._onTick` aplikuje `action.maneuver` přes `startManeuver`.
- Testy: Hard se sadou 6 použije v 50 seedovaných bitvách proti Easy alespoň jeden
  manévr; slow self-play zůstává zelený; „a ship too slow to dodge raises its shield“
  beze změny (jednotka bez energie nebo `maneuverCount 0` v tom testu).

---

## Krok 5 — Progres, odemykání, Comcenter

### `FleetProgress`
```dart
class ShipManeuvers {
  final Set<String> owned; final List<String> active;   // active ⊆ owned, ≤ 4
  final Map<String, int> levels;                        // 1–3, chybí = 1
}
// FleetProgress: + Map<PieceType, ShipManeuvers> maneuvers, + Map<PieceType, int> battleWins
// JSON: "maneuvers": {"knight": {"owned": [...], "active": [...], "levels": {"knight.jump": 2}}},
//       "battleWins": {"knight": 3}; chybějící typ = startovní sada, level 1.
```
- `maneuversFor(type)` vrací `List<(Maneuver, int)>` aktivních; `ownsManeuver(id)`.
- Notifier: `recordBattleWin(type)` (zvýší `battleWins`, **automaticky přidá do owned**
  každý manévr lodi s `WinsUnlock.wins ≤ battleWins` a vrátí seznam nově odemčených),
  `buyManeuver(id)` (`CreditsUnlock`, odečte kredity), `grantPack(packId)`,
  `setActive(type, ids)` (validace ⊆ owned, ≤ 4), `upgradeManeuver(id)` (kredity podle tieru).
- `fleet_progress_store_test`: round-trip, starší JSON bez `maneuvers` načte startovní
  sadu, `setActive` odmítne nevlastněný, `recordBattleWin` odemkne po prahu jen jednou.

### Tok vítězství
- `GameStateNotifier.onBattleResolved: void Function(Piece winner)?` volaný vedle
  `onBattleReward` z `resolveBattle` (hot-seat/single) a z `BattleResolvedEvent` (WiFi
  ne — progres jen single player, stejně jako kredity).
- `AiOpponentController`: v single playeru, když vítěz je lidská barva →
  `fleetProgressProvider(playerFleetIdentity).notifier.recordBattleWin(winner.type)`;
  nově odemčené uložit do `lastUnlocked` (ValueNotifier), `BattleScreen` výsledkový overlay
  ukáže „Nový manévr: Skok“ s `PatternGlyph`. `maneuversFor(color)`: hráč z progresu,
  AI z profilu.

### Comcenter
- `TabBar`: **Jednotky** (dnešní obsah) | **Manévry**.
- Manévry: chipy 6 typů lodí (sprite hráčovy flotily jako ikona), pod nimi řádek
  **Aktivní 0/4** — 4 sloty s `PatternGlyph`, tap = odebrat; katalog jako seznam
  `ManeuverCard`: glyph (48 px), název, rodina, tier badge, popis, energie, level pipsy,
  tlačítko podle stavu:
  - vlastněný neaktivní → **Aktivovat** (když je volný slot, jinak disabled + „Uvolni slot“);
  - aktivní → **Odebrat**;
  - `wins(n)` → „Odemkne se po n výhrách s [loď]“ + progress `x/n` a vedle **Koupit N cr**;
  - `credits(n)` → **Koupit N cr** (disabled bez kreditů);
  - `pack(id)` → „Balíček Ace“ (disabled; v `kDebugMode` tlačítko **Odemknout balíček**);
  - vlastněný a L < 3 → sekundární **Vylepšit N cr** s popisem bonusu.
- `PatternGlyph`: `CustomPaint` 3×3, čáry vzoru, šipka na konci pro směr, barva elementu.
- Widget test: Comcenter Manévry ukáže 4 sloty a katalog ≥ 10 karet pro pěšce; Aktivovat
  přesune manévr do slotu a uloží.

### `ManeuverStore` (rozhraní pro IAP)
```dart
abstract class ManeuverStore {
  Future<List<ManeuverPack>> packs();
  Future<bool> purchase(String packId);   // debug: vždy true → grantPack
}
```
`DebugManeuverStore` v `main.dart` přes provider; reálná implementace mimo rozsah.

---

## Krok 6 — Dokumentace a úklid

- `README.md`: sekce Battle o manévrech (pad, energie, sloty, odemykání). `CHANGELOG.md`.
  `CLAUDE.md`: `lib/core/maneuvers/` do architektury, odstavec do „Battle Arena“
  (energie, `ManeuverRun`, pad, `ManeuverStartedEvent`, progres `maneuvers/battleWins`),
  `ArenaLayout`.
- Volitelně zvuk: `tools/battle_audio` dostane `maneuver_whoosh`, `BattleSoundCues`
  `maneuverStarted`, `BattleAudio` přehraje.
- `flutter analyze` čisté, `flutter test --exclude-tags slow` zelené, `--tags slow` projde.

---

## Vyvážení (ruční, po kroku 5)

- Energie 12/s a ceny: hráč má spustit manévr zhruba každých 3–5 s, ne řetězit dva
  podpisové za sebou. Páky: `energyPerSecond`, `energyCost`, start 50.
- Nezranitelná okna nesmí být delší než čas letu nejrychlejší střely (sniper 250 ms
  přes arénu) × 2; jinak looping = volný únik.
- AI: Hard s manévry nesmí prodloužit bitvy nad dnešek (viz `single-player-ai-open-issues`);
  když ano, snížit `maneuverSkill` útočné větve.
- Pad: hit radius 0.18 vs. 0.22 podle toho, jak často se při rychlém tahu přeskočí bod.
- Hodnoty `ArenaLayout` a `_altitudeScale` doladit okem po kroku 0 (poslat render).

## Odhad

| Krok | Odhad |
|---|---|
| 0 pohyb po ploše | 0.25 dne |
| 1 model, katalog (6 lodí × 12), recognizer, testy | 1 den |
| 2 engine, energie, palba, testy | 1 den |
| 3 pad, stopa, energie, animace lodí, renders | 1.5 dne |
| 4 síť, AI | 0.75 dne |
| 5 progres, odemykání, Comcenter, store rozhraní | 1.25 dne |
| 6 dokumentace, zvuk volitelně | 0.25 dne |

## Mimo rozsah (nezačínat, jen vědět)

- Nákupní tok IAP (`in_app_purchase`, ověření účtenek), obnova nákupů.
- Rozšíření slotů, vlastní vzory hráče, řetězení manévrů (kombo z kombo).
- Manévry v hot-seat/WiFi podle progresu; sync progresu do Supabase.
- `GameEngine.resolveBattle` po výhře obránce neaktualizuje `hasKing/hasQueen` — stará
  mezera (viz plán 07), manévry ji nemění.
