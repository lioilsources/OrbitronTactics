# Phase 8: Světy, boj zblízka a tvar desky — zadání pro Opus

> Tři tratě, které na sobě nezávisí: **A** jiný svět než vesmír (dvě strany z jednoho
> lore), **B** boj zblízka a úprava manévrů, **C** jiná deska než 8×8. Nejdřív tři levné
> pokusy bez UI (krok 1), podle jejich výsledků rozhodne Olin a teprve pak se staví.
> Fakta o kódu jsou ověřená k 15/11/2026 na `main` (v0.8.0-alpha). Tabulka „Návrh
> rozhodnutí“ je návrh; po schválení platí jako uzavřená. Plány 09–11 jsou na větvi
> `claude/plan-monetizace`, proto číslo 12.

## O co jde

1. **Svět.** Dnes proti sobě stojí vesmírné flotily. Chceme umět postavit proti sobě dvě
   strany z jednoho světa (lidé a orkové, Řím a Egypt, golemové, bájná zvířata, lodě)
   tak, aby to FLUX uměl nakreslit stejnou cestou jako dnešní flotily.
2. **Boj zblízka.** Ne každá postava střílí. Aréna potřebuje úder nablízko a manévry
   („komba“) musí dávat smysl i pro jednotku s mečem.
3. **Deska.** Co stojí jiná velikost, jiný tvar a hexagon, a kde je strop.

Shrnutí odpovědí, na kterých plán stojí:

- **Svět je z 90 % obsah.** Engine, manévry, postup i síť jsou na tématu nezávislé; živly
  střel (kinetic, water, fire, ice, electric) jsou fantasy už dnes. Cenu určuje jediná
  věc: **z jakého pohledu jde jednotka nakreslit**. Co vypadá dobře přesně shora (lodě,
  letci, draci, hmyz), projde dnešní arénou beze změny. Postavy (vojáci, golemové)
  potřebují pohled z boku, a tedy novou kresbu arény.
- **Boj zblízka jde postavit na dnešní pravidlo zásahu** (dráha + pásmo). Nová je jen
  vzdálenost: úder je výpad, který trvá tím déle, čím dál od sebe jednotky stojí.
- **Obdélníkové desky a mapy s překážkami nemění pravidla vůbec**, jen konstanty.
  Hexagon mění směry: posuvné figury a pěšec sednou, kůň a „snipe“ střelce se musí
  navrhnout znovu. Na telefonu je strop 10 sloupců.

## Výchozí stav (ověřeno v kódu)

| Oblast | Co je v kódu | Co z toho plyne |
|---|---|---|
| Sprity | `assets/fleets/<slug>/<unit>_<white\|black>.png`, 10 flotil × 6 × 2, 256 px, shora, příď nahoře; `FleetSkin` je enum. Generátor `tools/fleet_art/` je jen na větvi `claude/fleet-art-tools`, v `main` není | Frakce = flotila, model souborů se nemění. Generátor je potřeba dostat do `main` a zobecnit. |
| Pohled arény | `BattleArenaPainter` otáčí horní loď o 180° a naklání sprity (`ShipBank`, roll, pitch, flip); `ArenaLayout` mapuje výšku na polohu ve vlastní polovině | Funguje jen pro kresbu přesně shora, kde není znát gravitace. Postava z boku otočená vzhůru nohama vypadá špatně. |
| Zásah | `BattleEngine._isHit`: dráha `hitHalfWidth` 0,07 a pásmo `hitHalfAltitude` 0,12. Střela letí pevný čas podle `WeaponType` (250–700 ms) bez ohledu na polohu lodí | Vzdálenost dnes ve hře není. Melee ji zavádí. |
| Palba | `_tickAttack`: každá jednotka střílí sama na časovač; hráč jen řídí, zvedá štít a kreslí gesta | Úder zblízka má být také automatický, jinak se ovládání rozdvojí. |
| Živly | `BattleElement`: pěšec kinetic, kůň water, střelec fire, věž ice, dáma a král electric | Stačí paleta a názvy na svět. |
| Manévry | 12 rodin + podpisový, `Keyframe` s kotvami, `FireCue`, nedotknutelné okno, `ManeuverRun`; kresba přes `Attitude` (roll, pitch, flip, boost) | Slovník je letecký. Rodiny a gesta zůstanou; mění se názvy, kresba a u melee druh zásahu. |
| Staty | `unitBaseStats` je globální konstanta; `BattleOdds.timeToKillMs` z ní počítá šance pro šachovou AI a `BoardEvaluator` hodnotu figur | Staty musí být na svět a `BattleOdds` musí umět melee, jinak AI na desce hraje naslepo. |
| Pilot AI | `BattleAi`: `_incoming`, `_dodge`, `_shouldShield`, `_chooseManeuver` | Soupeřův úder jde převést na „střelu s časem do dopadu“; zbytek zůstane. |
| Síť | Každé zařízení tiká vlastní engine; kdo dřív dohraje, pošle `BattleResolvedEvent`. `GameEvent.fromJson` na neznámý typ **vyhazuje** `ArgumentError` | Nový svět a nová událost = vyšší verze protokolu; starší klient se nesmí připojit. |
| Deska | Osmička natvrdo: `Position.isOnBoard` a `mirrored`, smyčky v `BoardState`, `PlayerColorX.backRank`/`infiltrationRank`, `VictoryChecker`, `FormationValidator` (řady 0–1 a 6–7, 16 figur), `GameEngine.defaultFormation`, `PowerFieldGenerator.variants`, AI (`1 << (row * 8 + col)`, `(7 − distance)²`), `GameBoard` a oba malíři desky | Jádro potřebuje `BoardGeometry`. 64bitové masky AI stačí jen do 64 polí. |
| Pohyb figur | Dosahy jsou omezené (nejvýš 4), žádný neomezený posuv. Kůň má výjimky (věž před ním, vzad jen nízké L), střelec „snipe“ o 3 vpřed se skokem | Větší deska mobilitu nerozbije, jen hru prodlouží. Hex potřebuje nové pravidlo pro koně a snipe. |
| Figury na desce | `PieceRenderer` kreslí šachové znaky Unicode v kolečku | Svět se na desce neprojeví, dokud nebudou žetony ze spritů. |
| Self-play | `test/core/ai/self_play.dart` hraje AI proti AI a bitvy losuje podle `BattleOdds` | Hotový základ laboratoře variant desky. |
| Větve | `claude/plan-monetizace` (1.0: nákupy, zámky flotil, čeština přes ARB, rodiny `phantom` a `strafe`) není v `main` | Texty UI patří do ARB, který je až tam. UI stavět až po sloučení 1.0. |

## Návrh rozhodnutí

| # | Rozhodnutí | Návrh |
|---|---|---|
| 1 | Kde svět žije | Ve stejné aplikaci jako obsahový balíček (`GameWorld`). Vesmír zůstává světem č. 1 a výchozím. Sesterská aplikace ze stejného repa až tehdy, když se nějaký svět osvědčí. |
| 2 | Frakce a pravidla | Výtvarně různé, pravidlově shodné: stejných šest rolí a stejné staty na obou stranách. Zrcadlový zápas (obě strany tatáž frakce) řeší světlá a tmavá varianta — dnešní `white`/`black`. Frakční schopnosti mimo rozsah. |
| 3 | Zápas = jeden svět | Obě strany jsou z jednoho světa. Svět určuje pohled arény, způsob pohybu, staty a pravidla arény a je součástí založení hry (protokol). |
| 4 | Lore | Vlastní, mytologie a historie. Žánrové archetypy (orkové, elfové, draci) ano; jména, postavy a vzhled cizích světů ne. |
| 5 | První světy | **Golemové** (vlajkový: z boku, boj zblízka) a **Nebeské letky** bájných zvířat (levný: shora, beze změny enginu). O pořadí rozhodnou listy z kroku 1A. |
| 6 | Pohled arény | `topDown` (dnes) a nový `side`: duel zleva doprava, sprite z profilu, soupeř vodorovně převrácený. Aréna zůstává na výšku, telefon se neotáčí. Engine se nemění; mění se `ArenaLayout`, malíř a vstup. |
| 7 | Úder zblízka | „Výpad“: spustí se sám, když je soupeř zaměřený; nápřah (jde zrušit úhybem) → výpad (nedotknutelný) → návrat (zranitelný). Štít úder zablokuje a útočníka zdrží. |
| 8 | Pravidlo zásahu | Jedno pro všechno: dráha + pásmo jako dnes. Nové je jen to, že vzdálenost určuje čas výpadu a — kde to svět zapne — i střely. |
| 9 | Komba | Rodiny, gesta a id manévrů zůstávají. Mění se názvy a kresba podle způsobu pohybu; u jednotky zblízka jsou „výstřely“ manévru kontaktní údery; zásah vrací energii a zvedá násobič. |
| 10 | Postup hráče | Společný všem světům: stejná id manévrů, stejné úrovně a kredity. |
| 11 | Deska | Obecná `BoardGeometry`. Dodat obdélníky 6×6 až 10×12 a mapy s překážkami. Hex jen když laboratoř ukáže vyvážená pravidla. Klasika 8×8 zůstává výchozí a chová se přesně jako dnes. |
| 12 | Nové typy figur | Ne. Každý nový typ znamená sprity pro všechny frakce, staty, živel a katalog manévrů. |
| 13 | Časový limit bitvy | „Sudden death“ zavést s tratí B (po 45 s rostou zóny zásahu). Pro vesmír zapnout jen s výslovným souhlasem — viz bod 6 tabulky slabých míst v plánu 11. |

## Světy — kandidáti

Dvě cenové třídy podle pohledu. „A“, „B“ jsou tratě, které svět potřebuje.

| Svět | Strany z jednoho lore | Pohled | Boj | Cena a riziko |
|---|---|---|---|---|
| **Golemové — figurky ožívají** | Cechy podle materiálu: mramor a obsidián, železo a křišťál, láva a led, dřevo a kost | z boku | hlavně zblízka; střelec a dáma na dálku | A + B + boční aréna. Pro FLUX nejjistější postavy: žádné obličeje ani prsty, materiál je „design language“ stejně jako u flotil. Role jsou šachové figury doslova (věž = kráčející věž). |
| **Nebeské letky** (bájná zvířata) | Draci a gryfové; dál fénixové, wyverny, pegasové s jezdci, čarodějnice | shora | jen na dálku (dech, blesky, pera) | Jen A. Engine beze změny, looping i výkrut sedí, souměrnost drží. Nejlevnější fantasy. |
| **Lodní bitvy — Actium** | Římské loďstvo a loďstvo Kleopatry; dál Kartágo, Řekové, piráti | shora | balisty a řecký oheň + **taran** jako úder zblízka | A + část B. „Příď nahoře“ pipeline už umí. Manévry přeznačit (obrat místo loopingu). |
| **Římská a egyptská armáda** | Legie a faraonovo vojsko, s mýty (Anubisovi válečníci, sfingy, orli legií) | z boku | zblízka i na dálku | A + B + boční aréna. Pro FLUX nejtěžší: lidské postavy, zbraně, šest konzistentních hodností. Až po golemech. |
| **Hmyzí války** | Mravenci a termiti, vosy a včely | shora | kusadla + kyselina | Jen A (B volitelně). Pohled shora je pro hmyz přirozený; termiti mají krále i královnu. |
| **Hlubina** | Útes a propast: krakeni, rejnoci, krabi, ďasové | shora | zblízka i na dálku | Jen A (B volitelně). |

Role napříč světy (popis pro prompt, staty zůstávají):

| Role | Vesmír (dnes) | Golemové | Nebeské letky | Actium |
|---|---|---|---|---|
| pěšec | lehká stíhačka | hliněný panáček | dráče | liburna |
| kůň | interceptor | kamenný kůň | wyverna | rychlá biréma |
| střelec | sniper s railgunem | obelisk s runami | dlouhokrký plivač blesků | loď s balistou na ose |
| věž | obrněný gunship | kráčející věž | obrněný želví drak | těžká quinqueréma s věží |
| dáma | bitevní křižník | korunovaná socha-čarodějka | štíhlý dlouhý drak | vlajková galéra |
| král | dreadnought | korunovaný kolos | prastarý drak | královská loď |

## Pravidla práce

- Každý krok samostatný commit; po každém `flutter analyze` bez nálezů a
  `flutter test --exclude-tags slow` zelené. Jedna trať = jeden PR (A má dva: model světů
  a boční aréna). PR texty česky, commity anglicky.
- **Krok 1 jde dělat hned z `main`** (čisté Dart a nástroje, žádné texty UI). PR z něj
  otevři až po sloučení 1.0 a rebase. **Kroky 2–4 až po sloučení `claude/plan-monetizace`**:
  texty patří do `lib/l10n/app_en.arb` i `app_cs.arb`, obsah katalogu do `content_cs.dart`.
- Nepouštěj `dart format` na celé soubory (repo není formátované aktuálním formátovačem).
- `lib/core/` zůstává bez Flutteru a deterministické. Laditelná čísla mají jediný zdroj:
  `WorldBalance` (staty a pravidla arény), `BoardSpec` (deska).
- Identifikátory v kódu nepřejmenovávej (`FleetSkin`, `ship`, `fleet`): svět mění jen
  texty v UI. Přejmenování by rozbilo uložený postup a větev 1.0.
- Grafika běží na SPARKu jen přes frontu: `sparkctl status`, `sparkctl catalog`, dávka
  přes `sparkctl exec … -- python3 tools/fleet_art/gen_fleets.py …` (skill `spark-job`).
  Nejdřív jeden kus, ukázat, pak sada.
- Rozpracovaný výběr flotil pro obě strany (Local Game, WiFi `FleetChosenEvent`,
  `FleetPicker`) v `main` není. Před tratí A zjisti, kde je, a stav na něm.

## Krok 0 — otázky na Olina

Jednou zprávou na začátku. Krok 1 na odpovědi nečeká, kromě bodu 3.

1. Svět ve stejné aplikaci (návrh), nebo rovnou sesterská aplikace?
2. Stavět kroky 2–4 až po vydání 1.0 (návrh)?
3. Pilot grafiky se čtyřmi světy z tvého seznamu — bájná zvířata, golemové, římská
   a egyptská armáda, lodní bitvy — nebo jiný výběr?
4. Úder zblízka automaticky při zaměření (návrh), nebo vlastním tlačítkem?
5. Hot-seat v bočním pohledu: oba hráči u spodní hrany vedle sebe (návrh). Dnešní sezení
   proti sobě by jednomu z nich kreslilo postavy vzhůru nohama.

---

## Krok 1 — tři pokusy bez UI

Každý končí tabulkou nebo listem pro Olina. Po kroku 1 **stůj a počkej na rozhodnutí**:
který svět, jaké ovládání úderu, které desky.

### 1A — pilot grafiky

- Dostaň `tools/fleet_art/` do `main` (PR z `claude/fleet-art-tools`).
- **Jeden kus napřed:** věž golemů z boku. Ukázat, teprve pak sada.
- **Sada:** čtyři světy z bodu 3 kroku 0, každý 2 frakce × 2 role (pěšec a král, tedy
  nejmenší a největší) = 16 světlých renderů, k tomu 4 tmavé přemalby přes FLUX Kontext.
  Olinovo zadání světa dej do promptu téměř doslova.
- **Shora** (bájná zvířata, lodě): dnešní šablona `white_prompt`, mění se jen role
  a věta o směru („hlava/příď u HORNÍHO okraje, ocas/záď u DOLNÍHO“). Brána zrcadlové
  IoU ≥ 0,90 zůstává.
- **Z boku** (golemové, armády): nová šablona — malovaná stolní figurka na kulatém
  podstavci, přísný profil, čelem doprava, celá postava, rovnoměrné světlo, plochý šedý
  podklad. Styl figurky je záměr: statická póza pak působí jako herní kámen, ne jako
  chybějící animace. Brány: jedna figura (největší souvislá oblast ≥ 97 % neprůhledných
  pixelů), celá v záběru (okraj ≥ 3 % na každé straně), tmavá varianta ≤ 0,60 jasu
  světlé. Souměrnost se nekontroluje. Směr pohledu brána nepozná: kontrola okem
  a množina `FACING_LEFT`, kterou export převrátí (obdoba `BOW_DOWN`). Výšku podle
  hodnosti nastavuje export (pěšec 0,6 … král 1,0), ne FLUX.
- **Žeton na desku** z téhož renderu: výřez 96 px (shora celý sprite, z boku horních 60 %).
- **Výstup:** kontaktní list každého světa na pozadí arény a tytéž kusy ve 40 px na poli
  desky. Hotovo = Olin z listů vybral svět.

### 1B — boj zblízka nanečisto (čisté Dart)

Model „výpad“. Vzdálenost `r = (1 − altitude útočníka) + (1 − altitude cíle)`: 0 = oba
u dělicí čáry, 2 = oba u vlastních okrajů.

1. **Spuštění** v `_tickAttack` u jednotky se stylem `melee`: `nextAttackMs ≤ 0`, neletí
   manévr a cíl je v zóně (`|Δx| ≤ arcHalfWidth`, `|Δaltitude| ≤ hitHalfAltitude`).
2. **Nápřah** `windupMs`: jednotku jde řídit. Opustí-li zaměření, úder se ruší
   (`nextAttackMs = 300`) — finta. Soupeř vidí, kam úder míří.
3. **Výpad** `max(80, dashMsPerRange × r)`: bez řízení, nedotknutelná.
4. **Kontakt:** cíl je pořád v zóně a není nedotknutelný → `_applyHit`. Štít → blok:
   žádná škoda, útočník dostane `staggerMs` navíc. Obojí zapiš do `impacts`.
5. **Návrat** `recoverMs`: bez řízení, zranitelná.

Logická poloha jednotky (`xFraction`, `altitude`) zůstává celou dobu doma; výpad je jen
kresba (`StrikeRun.lungeAt(ms)` 0–1). Pravidlo zásahu střel se tím nemění.

```dart
// lib/core/game_logic/models/unit_stats.dart
enum AttackStyle { ranged, melee }
class MeleeProfile {
  final int windupMs, dashMsPerRange, recoverMs, staggerMs;
  final double arcHalfWidth;
}
// UnitStats: + AttackStyle attack (default ranged), + MeleeProfile? melee

// lib/core/game_logic/models/strike_run.dart
class StrikeRun { final int startedMs, windupMs, dashMs, recoverMs; final Spot target; }
// BattleUnit: + StrikeRun? strike

// lib/core/worlds/world_balance.dart
class ArenaRules {
  final double rangeTravelScale;   // 1.0 = střela letí pevný čas (vesmír); 0.5 = nablízko polovinu
  final int? suddenDeathAfterMs;   // null = bez limitu (vesmír dnes)
  final double energyPerHit;       // krok 3
}
class WorldBalance { final Map<PieceType, UnitStats> units; final ArenaRules arena; }
// WorldBalance.space = dnešní unitBaseStats, beze změny čísel
```

Výchozí čísla pozemní balance (doladit simulací; střelec a dáma zůstávají na dálku jako dnes):

| Jednotka | HP | Škoda | Interval | Nápřah | Výpad na r = 1 | Návrat | Oblouk |
|---|---|---|---|---|---|---|---|
| pěšec | 45 | 12 | 700 | 180 | 220 | 200 | 0,09 |
| kůň | 80 | 26 | 1000 | 200 | 180 | 250 | 0,09 |
| věž | 130 | 40 | 1500 | 350 | 300 | 400 | 0,12 |
| král | 180 | 45 | 1600 | 350 | 280 | 400 | 0,12 |

- `BattleEngine.createBattle` bere `WorldBalance`. `BattleOdds` a `BoardEvaluator` čtou
  staty ze stejné balance (klíč cache rozšiř o svět). Melee v `timeToKillMs`:
  `zásahy × max(interval, nápřah + výpad(r=1) + návrat) + nápřah + výpad(r=1)`.
- `BattleAi`: soupeřův úder v nápřahu nebo výpadu převeď na hrozbu s časem do dopadu
  a pusť do `_dodge` a `_shouldShield`; jednotka zblízka se drží vysoko (blízko čáry).
  Fintu AI zatím neumí.
- `tools/duel_lab.dart` (vzor `fight` v `test/core/ai/battle_ai_test.dart`): pro danou
  balanci matice 6×6 — podíl výher útočníka, medián délky, podíl duelů na limitu 180 s
  a vedle toho odhad `BattleOdds`. Medium proti Medium, 200 duelů se semínkem na dvojici.
- **Hotovo, když:** vesmírná balance dává se stejnými semínky stejné výsledky jako před
  změnou (regresní test). Pozemní: zrcadlové dvojice 45–55 %, melee proti střelbě stejné
  váhy 35–65 %, medián 8–25 s, na limitu nejvýš 2 % duelů, `|BattleOdds − simulace| ≤ 0,15`.
  Když to čísly nejde, napiš proč a co navrhuješ místo toho; nelaď donekonečna.

### 1C — geometrie desky a laboratoř variant (čisté Dart)

```dart
// lib/core/game_logic/board/board_geometry.dart
abstract class BoardGeometry {
  int get rows; int get cols;
  bool contains(Position p);                        // na desce a není překážka
  List<Direction> get straight;                     // čtverec 4, hex 6 (přes hrany)
  List<Direction> get diagonal;                     // čtverec 4, hex 6 (přes vrcholy)
  Position step(Position from, Direction d);
  List<Direction> sideways(PlayerColor c);          // pěšec bez braní
  List<Direction> backward(PlayerColor c);          // pěšec bez braní
  List<Direction> forwardCapture(PlayerColor c);    // pěšec s braním
  Iterable<KnightJump> knightJumps(PlayerColor c);  // cíl, druh, pole blokující věže
  Position? snipeTarget(Position from, PlayerColor c);
  int backRank(PlayerColor c);
  bool isInfiltration(Position p, PlayerColor c);
  Position mirror(Position p);
  int indexOf(Position p);                          // pro masky AI
}
class SquareGeometry / HexGeometry (pointy-top, řady vodorovně, offset souřadnice)
class BoardSpec { id, geometrie, rows, cols, blocked, formationRows, army, powerFields }
```

- `BoardState` nese `spec` (v JSON nové pole; chybí-li, je to `classic8` — stará data
  i starší protějšek se čtou dál). `Position.isOnBoard`, `mirrored`, `backRank`
  a `infiltrationRank` nahraď dotazy na geometrii. Validátory přepiš ze dvojic
  `(dRow, dCol)` na směry geometrie; `Move.isSnipe` nastavuje validátor.
- AI: `_bit` přes `indexOf`; pro desky nad 64 polí `CellSet` ze dvou intů (do 128 polí).
  Člen infiltrace `(7 − distance)²` škáluj počtem řad.
- Mocenská pole pro nové desky generuj souměrně (polovina + zrcadlo + střed) a ohlídej
  testem. Osm dnešních variant klasiky neměň, i když všechny souměrné nejsou.
- `tools/variant_lab.dart` nad `self_play.dart`: pro každou variantu 200 her Medium
  proti Medium: výhry bílého, průměr tahů, průměr braní (= počet bitev), rozdělení
  způsobů výhry, podíl her nedohraných do 300 tahů.
- **Hotovo, když:** `classic8` projde všemi dnešními testy beze změny očekávání
  a laboratoř vypíše tabulku pro varianty níže.

| Varianta | Deska | Armáda | Pole moci | Proč ji zkoušet |
|---|---|---|---|---|
| `classic8` | 8×8 | 16 | 5 | základ pro srovnání |
| `skirmish6` | 6×6 | 12: 6 pěšců, 2 věže, kůň, střelec, dáma, král | 3 | krátká hra na mobil |
| `tall8x10` | 8 sloupců × 10 řad | 16 | 5 | delší nástup, stejná šířka |
| `grand10` | 10×10 | 16 a zvlášť 20 (10 pěšců, +kůň, +střelec) | 5 | strop šířky telefonu |
| `rocks8` | 8×8 se 4 souměrnými překážkami | 16 | 5 | tvar desky bez nových pravidel |
| `hex8` | hex 8×8, pravidla níže | 16 | 5 | jestli hex stojí za UI |

Pravidla hexu v0. Hex stojí na špičce (pointy-top), řady jsou vodorovné. Světové strany
jsou z pohledu hráče, vpřed je sever: sousedé přes hranu jsou V, Z, SV, SZ, JV, JZ; přes
vrchol S, J a čtyři šikmé.

| Figura | Dnes na čtverci | Hex v0 |
|---|---|---|
| pěšec | do stran a vzad bez braní, šikmo vpřed s braním, rovně vpřed ne | V/Z bez braní, SV/SZ s braním, JV/JZ bez braní. Rovně vpřed na tomhle hexu soused není, pravidlo sedí bez úprav. |
| věž | ≤ 4 rovně | ≤ 3 přes hrany (6 směrů) |
| střelec | ≤ 3 šikmo; snipe přesně 3 vpřed se skokem | ≤ 2 přes vrcholy; snipe přesně 2 kroky přes vrchol rovně vpřed (o 4 řady). Srovnej s variantou „3 přes hranu šikmo vpřed“. |
| kůň | L; vzad jen nízké L; vysoké L vpřed blokuje věž před koněm | 12 skoků (2 přes hranu + 1 s odbočením o 60°), po dvou na každý posun řad ±1, ±2, ±3. Vpřed všech šest, vzad jen −1. Skoky vpřed o 2 a 3 řady blokuje věž na předním sousedovi téže strany. |
| dáma | ≤ 4 šikmo, ≤ 2 rovně | ≤ 2 přes vrcholy, ≤ 2 přes hrany |
| král | ≤ 4 rovně, ≤ 2 šikmo | ≤ 3 přes hrany, 1 přes vrchol |
| poslední válečník | 1 do osmi směrů | 1 přes hranu |

Krok přes vrchol je delší než krok přes hranu (o dvě řady rovně vpřed), proto jsou
šikmé dosahy kratší. Posuv přes vrchol neblokují dvě pole, mezi kterými prochází.
Hex 8×8 v offset souřadnicích drží dnešní `grid[row][col]`, JSON i 64bitové masky.

---

## Krok 2 — trať A: světy a frakce

1. **Model** (`lib/core/worlds/`): `GameWorld {id, view: ArenaView, locomotion: Locomotion
   (air | sea | ground), balance, factions}`. Frakce = dnešní `FleetSkin`; slugy zůstávají
   globálně jedinečné a cesta `assets/fleets/<slug>/…` se nemění, svět je jen seskupení
   (`GameWorld.ofFaction(slug)`). `fleet_skin_test` dál hlídá shodu kódu, souborů a pubspec.
2. **Výběr:** Comcenter a dialog Local Game vybírají nejdřív svět, pak frakci. Single
   player: `AiProfile.fleetSkin` → frakce na svět. Síť: svět zakládá hostitel a je
   v založení hry; verze protokolu nahoru. Frakce z jiného světa nebo neznámá → výchozí
   frakce světa zápasu.
3. **Texty:** slova „loď“, „flotila“ a názvy živlů přes l10n s klíčem podle světa.
4. **Žetony na desce:** `PieceRenderer` nakreslí sprite frakce v kolečku barvy strany
   s malým šachovým znakem v rohu; bez spritu dnešní znak.
5. **Motiv:** barvy desky (`BoardTheme`), pozadí arény a paleta živlů na svět.
6. **Kresba podle pohybu** v `BattleArenaPainter`: `air` jako dnes. `sea`: roll = náklon
   trupu, flip = obrat o 360° v rovině, boost = brázda; velikost podle výšky a stín
   vypnout. `ground`: roll = otočka kolem svislé osy, flip = výskok (posun a menší stín),
   pitch = předklon, boost = prach.
7. **Boční aréna** (vlastní PR): `ArenaLayout.unitCenter(spot, side, arena, view)` pro
   malíře i vstup. V pohledu `side` vede dráha svisle a výška vodorovně od vlastního
   okraje ke středu; místní hráč je vlevo. Sprite se nepřetáčí o 180°, soupeř se převrací
   vodorovně. Vstup: prst ve vlastní polovině určuje dráhu, tah ke středu je postup 1 : 1.
   Hot-seat podle odpovědi 5. Testy: `arena_layout_test` pro oba pohledy, malíř
   `returnsNormally`, widgetový test řízení v bočním hot-seatu.
8. **Grafika prvního světa:** 2 frakce × 6 × 2 přes zobecněný `tools/fleet_art`, kontrola
   okem na listech, export, zápis do katalogu frakcí.

## Krok 3 — trať B: boj zblízka a komba

1. **Engine načisto** z 1B, se `suddenDeathAfterMs` (zóny zásahu +50 % každých 10 s po
   limitu) a s `rangeTravelScale` pro střely.
2. **Síť:** úder spouští jen zařízení jeho vlastníka a posílá `StrikeStartedEvent {color,
   targetX, targetAltitude, range}`; `BattleEngine.tick` dostane, kterým stranám smí
   úder spustit sám. Tolerantní čtení, round-trip test.
3. **Kresba a zvuk:** telegraf nápřahu (zóna dopadu v barvě živlu na soupeřově straně),
   výpad po spojnici, oblouk seku, jiskra bloku, zdržení po bloku. `BattleSoundCues`: úder,
   blok. Offscreen render fází poslat Olinovi.
4. **Manévry pro jednotky zblízka:** `FireCue` dostane `contact`; katalog ho nastaví
   podle stylu jednotky (`ManeuverCatalog.forShip` bere balanci). Kontaktní úder zasahuje
   bez letu střely, jen při `r ≤ 1`. Salva = série tří úderů, Přetlak = kratší interval
   úderu. Id a gesta beze změny.
5. **Komba:** `BattleUnit.combo` (0–3). Zásah zblízka: combo +1, energie +`energyPerHit`
   (10), škoda ×(1 + 0,1 × combo). Vlastní neodstíněný zásah nebo 2,5 s bez úderu combo
   nuluje. Počitadlo u panelu jednotky.
6. **Názvy rodin podle pohybu** v l10n (Looping → Výskok, Výkrut → Kotoul, Salva → Smršť).
7. `tools/duel_lab.dart` znovu po každé změně čísel; slow self-play zůstává zelený.

## Krok 4 — trať C: deska

1. **UI obdélníků a map:** `GameBoard` a oba malíři podle `rows`/`cols` (nečtvercový
   poměr stran), překážky jako vlastní vrstva pozadí, `flipBoard` přes geometrii. Volba
   desky v lobby u Local Game a single playeru; po síti je `spec` v založení hry.
   `FormationValidator` a `defaultFormation` podle `BoardSpec`.
2. **Které varianty:** jen ty, které Olin vybere z tabulky laboratoře. Návrh: `skirmish6`
   a jedna mapa s překážkami; `grand10` jen pro tablet a Windows.
3. **Hex** (jen po schválení): pravidla podle výsledků laboratoře, malíř hexů, převod
   dotyku na pole (zaokrouhlení v krychlových souřadnicích), zvýraznění tahů, animace.
   Váhy `EvalWeights` přeladit laboratoří.

## Kam až jde deska zvětšit

- **Šířka:** na telefonu širokém 390 dp má pole při 8 sloupcích 49 dp, při 10 sloupcích
  39 dp, při 12 už 32 dp, což je pod hranicí pohodlného doteku. Strop je 10 sloupců; řad
  se na výšku vejde 12. Hex o 8 sloupcích vychází na 44 dp.
- **Délka hry:** každé braní je bitva v aréně. Větší deska a víc figur znamená víc bitev;
  laboratoř proto měří průměr braní na hru. Menší deska je pro mobil cennější než větší.
- **AI:** masky do 64 polí; nad to `CellSet`. Hard hledá v časovém rozpočtu, na větší
  desce jen mělčeji.
- **Figury:** armáda zůstává ze šesti typů. Na širší desce buď mezery ve formaci, nebo
  víc kusů stejných typů.

## Odhad

| Krok | Odhad |
|---|---|
| 1A pilot grafiky | 0,5 dne + GPU |
| 1B melee nanečisto, `duel_lab` | 1,5 dne |
| 1C geometrie jádra, `variant_lab` | 3 dny |
| 2.1–2.6 model světů, výběr, žetony, motiv, kresba podle pohybu | 4 dny |
| 2.7 boční aréna | 3 dny |
| 2.8 grafika prvního světa | 1 den + GPU a kontrola okem |
| 3 boj zblízka načisto, síť, kresba, manévry, komba | 5,5 dne |
| 4.1–4.2 UI obdélníků a map | 2 dny |
| 4.3 hex | 4–5 dní |

## Rizika

- **FLUX a postavy z boku:** směr pohledu nejde ohlídat branou, šest hodností musí držet
  jeden styl. Proto pilot a figurkový styl; golemové před lidmi.
- **Pat v aréně:** dva piloti Hard se netrefí už dnes. Blok a úhyb to u melee mohou
  zhoršit; proto sudden death a měření podílu duelů na limitu.
- **`BattleOdds` proti skutečnosti:** když odhad nesedí, šachová AI obětuje figury
  špatně. Proto mez 0,15 v `duel_lab`.
- **Větev 1.0:** konflikty v katalogu manévrů, ve flotilách se zámky a v textech. Proto
  stavba až po sloučení.
- **Protokol:** starší klient na neznámou událost spadne do výjimky. Nový svět, deska
  i úder musí být za verzí protokolu.
- **Hex:** nová pravidla jsou nová hra na ladění, ne varianta zadarmo.

## Mimo rozsah

- Nové typy figur, frakční schopnosti a bonusy.
- Animace po snímcích. Jednotka je jedna póza + transformace + efekty; dvě tři pózy
  přes Kontext (nápřah, úder) až jako pozdější vylepšení.
- Terén, který mění pravidla v aréně; hry pro tři a čtyři hráče; kruhové desky.
- Vlastní zvuková sada světa (`tools/battle_audio` ji umí doplnit později).
- Sesterská aplikace a prodej světů — navazuje na plán 09, vlna 3.
