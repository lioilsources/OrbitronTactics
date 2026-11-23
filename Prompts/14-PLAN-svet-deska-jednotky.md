# Phase 9: Svět spojuje desku a jednotky — zadání pro Opus

> Tři tratě: **A** jeden výběr „Svět“ určuje figurky na desce i jednotky v aréně,
> **B** boj zblízka z větve `claude/melee-lab` do hry, **C** čitelná deska na telefonu
> (tolerantní dotyk, nakloněná deska se stojícími figurkami).
> Fakta o kódu jsou ověřená k 23/11/2026 na `main` (`07e1926`). Tabulka „Návrh
> rozhodnutí“ je návrh; po schválení Olinem platí jako uzavřená.
> Navazuje na plán 12 (světy, melee, tvar desky — zatím jen na větvi `claude/melee-lab`)
> a plán 13 (frakce jako skin packy). Kde se s plánem 12 liší, platí tento.

## O co jde

1. **Deska a jednotky do sebe nezapadají.** Záložka DESKA vybírá svět figurek (Řím ×
   Kartágo, Rytíři × Orkové…), záložka JEDNOTKY vesmírnou flotilu. Při braní se proto
   i v Římě utkají vesmírné stíhačky; ze světa desky se do arény dostane jen jméno vítěze.
2. **Boj zblízka ve hře není.** Engine je hotový a změřený na větvi `claude/melee-lab`,
   ale není v `main`, nic ho nekreslí a žádný svět ho nepoužívá. Legionář tak střílí.
3. **Hexagonální deska je na telefonu malá.** Má 11 polí na šířku: na telefonu širokém
   360 dp vychází pole asi na 32 dp, u klasické desky na 44 dp. Plán 12 dával strop
   10 sloupců.

Řešení v jedné větě: **svět je jeden výběr**, který určí figurky na desce, jednotky
v aréně, pohled na desku i pravidla souboje; a figurky, které na desce stojí, mají stát
na nakloněné desce a přesahovat přes pole, místo aby se mačkaly do jeho půdorysu.

## Výchozí stav (ověřeno v kódu)

| Oblast | Co je v kódu | Co z toho plyne |
|---|---|---|
| Svět desky | `PieceSkin` (`features/game/data/piece_skin.dart`): `classic` (šachové znaky) a 16 obrázkových packů po dvou stranách, `assets/pieces/<slug>/<typ>_<white\|black>.png`, 256 px, s podstavcem, pohled zepředu ze tří čtvrtin, lehce doprava; černá strana se zrcadlí. Vlastní barvy polí, `sideName`. Uloženo na zařízení (`piece_skin`), platí ve všech režimech, zdarma. | Dvoustranné světy už existují. `PieceSkin` je hotový kandidát na „svět“; `classic` je vesmír. |
| Jednotky v aréně | `FleetSkin` (`features/battle/data/fleet_skin.dart`): 10 flotil, 6 placených, sprity shora, příď nahoře. `BattleScreen(attackerSkin, defenderSkin)`; `game_screen.dart` je plní jen v single playeru (`AiOpponentController.skinFor`), jinde `FleetSkin.fallback`. | Aréna o světě desky neví. Stačí jí předat jiný zdroj obrázku a způsob kresby. |
| Kresba arény | `BattleArenaPainter`: sprite příď nahoře, horní jednotka otočená o 180°, náklon podle boční rychlosti, výška jako velikost a stín; šířky podle typu v `_spriteWidthFractions`. `ArenaLayout.shipY` mapuje výšku na polohu od vlastního okraje k dělicí čáře. | Stojící figurka se nesmí otáčet ani naklánět; „výška“ se u ní čte jen jako postup vpřed. |
| Figurky na desce | `PieceRenderer.build(piece, size, skin, classicMarks)`: obrázek zarovnaný dolů do 85 % pole. `GameBoard` klade figurky jako `Positioned` v pořadí `geometry.cells`. | Figurka se vejde do půdorysu pole; na hexu je tedy vysoká nejvýš 27 dp. |
| Rozložení desky | `BoardLayout` (`widgets/board/board_layout.dart`): `fit`, `within`, `centreOf`, `cellPath`, `shadeOf`, `pieceBox`, `positionAt` (nejbližší střed). Oba malíři i dotyk jdou přes něj. | Naklonění i tolerantní dotyk patří sem, na jedno místo. |
| Dotyk | `GameBoard._handleTap` bere přesně pole pod prstem. | Na poli 32 dp se snadno klepne vedle. |
| Boj zblízka | Větev `claude/melee-lab`, 16 souborů, 70 commitů za `main`, bez PR: `AttackStyle.melee`, `StrikeRun`, `WorldBalance.space` a `.ground` (pěšec, kůň, věž, král zblízka; střelec a dáma na dálku), `tools/duel_lab.dart`, `docs/lab/duel-lab.md`, `space_duel_regression_test`. | Engine netřeba psát, jen sloučit. `main` mezitím dostal náhlou smrt v `BattleEngine` (`suddenDeathAfterMs = 45000`), větev má vlastní `ArenaRules.suddenDeathAfterMs`. |
| Otevřený nález laboratoře | Pěšci zblízka se ve 31 % duelů zničí navzájem (dva výpady dopadnou ve stejném ticku); aréna dnes dá remízu útočníkovi. | Před zapnutím ve hře je potřeba pravidlo. |
| Režimy | `GameMode`: `hotSeat` a `singlePlayer` běží na jednom zařízení; `localWifi` má arénu po síti (každé zařízení tiká vlastní engine); `multiplayer` (online) — ověř, jestli arénu vůbec otevírá. | Na jednom zařízení se svět a jeho pravidla shodnou samy. Po síti je musí nést založení hry. |
| Comcenter | Záložky JEDNOTKY (`_UnitsTab`: výběr flotily a vylepšení), MANÉVRY, DESKA (`PieceSkinPicker`), OBCHOD. | Dva výběry vzhledu na dvou místech. |
| Grafika figurek | `tools/faction_art/` (Qwen-Image); `postprocess.py` umí i variantu `battle` bez podstavce, ta je jen v gitignorovaném `out/`. | Na tento plán není potřeba generovat nic. |

## Návrh rozhodnutí

| # | Otázka | Návrh |
|---|---|---|
| 1 | Co je svět | `PieceSkin`. Identifikátor, slugy ani klíč `piece_skin` se nemění; `classic` se hráči ukazuje jako **Vesmír**. Nový model `GameWorld` z plánu 12 se nestaví. |
| 2 | Vesmír na desce | **Rozhodnuto:** šachové symboly jako dnes. Lodě se na desku nedávají. |
| 3 | Ostatní světy v aréně | Tytéž figurky jako na desce, i s podstavcem (styl oživlé figurky). Varianta bez podstavce by přidala asi 12 MB a nepřidává se. |
| 4 | Pohled arény pro figurky | **Stolní pohled:** dnešní rozložení (soupeř nahoře, hráč dole), figurky stojí zpříma jako na desce. Boční aréna z plánu 12 (krok 2.7) se odkládá. |
| 5 | Pohled desky | Podle pózy světa: lodě shora → plochá deska; stojící figurky → nakloněná deska. Čisté symboly vždy plochá. |
| 6 | Pravidla souboje | Dvě balance: `space` pro Vesmír, `ground` pro všech 16 světů figurek. Světy se liší kresbou, ne čísly. |
| 7 | Flotily a světy | **Rozhodnuto:** placené jsou flotily i světy figurek, každý za USD 0,99, Commander Edition obsahuje všechny. Product id `com.ol1n.orbitrontactics.pack.world_<slug>`. Výběr flotily platí jen ve Vesmíru. |
| 8 | Postup hráče | Vylepšení, manévry a kredity jsou podle role (pěšec až král) a společné všem světům. |
| 9 | Síť | `localWifi` do kroku 6 bojuje podle `space` (všichni střílí), každé zařízení kreslí svůj svět. Online beze změny. |
| 10 | Vzájemné zničení | **Rozhodnuto:** zničí-li se jednotky navzájem, z desky zmizí obě figury (v každém světě, i ve Vesmíru). |
| 11 | Zoom | Jen pokud bude hex malý i po krocích 1 a 3. |

## Pravidla práce

- Jeden krok = jeden PR, texty PR česky, commity anglicky. O merge rozhoduje Olin.
- Gate jako CI: `flutter analyze --no-fatal-infos` a `flutter test --exclude-tags slow`;
  po změně AI, enginu nebo pravidel i `flutter test --tags slow`. Když místní Flutter
  přepíše `pubspec.lock` nebo `analysis_options.yaml`, vrať je.
- Texty pro hráče jen přes `lib/l10n/app_en.arb` a `app_cs.arb`. Hra se jmenuje Archion.
- `lib/core/` zůstává bez Flutteru a deterministické. Čísla mají jediný zdroj:
  `WorldBalance` (souboj), `BoardSpec` (deska), `BoardLayout` (kresba desky).
- Nepřejmenovávej `PieceSkin`, `FleetSkin`, `ship`, `fleet` ani uložené klíče: rozbilo by
  to uložený postup. Mění se jen texty.
- Nepouštěj `dart format` na celé soubory.
- **Nejdřív ukázka, pak stavba.** Kroky 3 a 5 začínají listem pro Olina (P2, P3).
  Listy vykresli testem po vzoru `test/store_screenshots` do gitignorovaného `run/pilot/`
  a pošli je; do repa nepatří.
- Novou grafiku tento plán nepotřebuje. Kdyby na ni došlo: jen přes frontu GPU podle
  `tools/faction_art/README.md`, hotové assety jen z Qwen-Image nebo flux1-schnell
  (FLUX.1-dev má nekomerční licenci), nejdřív jeden kus.
- Po každém kroku: `CHANGELOG.md`, `docs/architecture.md`, `CLAUDE.md` (nejvýš 80 řádků).
  Když se změní obrazovky ve snímcích pro obchody, přegeneruj `docs/store/`
  (`STORE_SCREENSHOTS=1 flutter test test/store_screenshots`); nahrání do obchodů je Olinovo.

## Krok 0 — otázky na Olina

Olin 23/11/2026 rozhodl body 2, 7 a 10 (viz tabulka). Otevřené zůstávají:

1. Rozhodnutí 4: stolní pohled arény (návrh), nebo boční aréna z plánu 12?
2. Rozhodnutí 7: které světy figurek zůstanou zdarma (u flotil jsou zdarma 4 z 10)?

Kroky 1 a 4 na odpovědi nečekají. Krok 2 čeká na obě, jeho bod 4 na odpověď 1.

---

## Krok 1 — tolerantní dotyk (trať C)

Malý, samostatný, pomůže hned.

```dart
// lib/features/game/presentation/widgets/board/tap_resolver.dart — čistá funkce
Position? resolveTap(BoardLayout layout, Offset point,
    {required Set<Position> preferred, double reach = 0.8});
```

- `exact = layout.positionAt(point)`. Je-li v `preferred`, platí.
- Jinak nejbližší pole z `preferred`, jehož střed je od prstu do `reach × cellSize`.
- Jinak `exact`; co se stane dál, zůstává jako dnes.
- `preferred` s vybranou figurou: povolené cíle, vybrané pole a vlastní figury, které
  mají tah. Bez výběru: vlastní figury, které mají tah.
- `reach` musí zůstat pod 1,0: klepnutí doprostřed prázdného pole se nesmí přichytit
  k sousedovi. Hodnotu dolaď na hexu, klasická deska se nesmí chovat jinak než dnes.
- **Testy:** `tap_resolver_test` (klepnutí těsně vedle cíle, mezi dvěma cíli, doprostřed
  prázdného pole, obě desky, otočená deska) a widgetový test na `hex6`.
- **Hotovo, když:** na hexu jde táhnout klepnutím do 80 % šířky pole od středu cíle
  a dnešní testy desky projdou beze změny očekávání.

## Krok 2 — svět jako jeden výběr (trať A)

Ukázka P1 odpadla: Vesmír má na desce symboly (rozhodnutí 2).

1. **Zdroj obrázku jednotky** (`features/battle/data/unit_art.dart`):
   ```dart
   enum UnitPose { topDown, standing }
   class UnitArt { final String asset; final UnitPose pose; final bool mirrored; }
   UnitArt unitArt(PieceSkin world, FleetSkin fleet, PieceType type, PlayerColor color);
   ```
   Vesmír: `fleet.assetFor`, `topDown`. Svět figurek: `world.assetFor`, `standing`,
   zrcadlení pro černou. `PieceSkin` dostane `isSpace` a `pose`.
2. **Flotily obou stran z jednoho místa:** provider, který pro barvu vrátí `FleetSkin`
   (single player přes `AiOpponentController.skinFor`, jinak `FleetSkin.fallback`). Čte
   ho deska i `game_screen.dart` při otevírání arény, aby se nemohly rozejít.
3. **Deska ve Vesmíru** zůstává se šachovými symboly jako dnes; přepínač `classicMarks`
   pro světy figurek beze změny.
4. **Aréna:** `BattleScreen` bere `attackerArt` a `defenderArt` místo flotil
   a `game_screen.dart` je plní ve všech režimech. `BattleArenaPainter` pro `standing`:
   - neotáčí horní jednotku o 180° (výjimka: hot-seat, kde horní hráč sedí naproti,
     jako dnes), nenaklání ji a nemění velikost podle výšky; výška je jen poloha;
   - všech šest typů kreslí na stejně velké plátno (výšky podle hodnosti jsou
     v obrázcích), pod podstavec dá kontaktní stín;
   - postoje manévrů: roll = otočka kolem svislé osy, flip = výskok, pitch = předklon,
     boost = prach; plameny motorů jen pro `topDown`.
   Střely, živly, zvuk a pravidla se v tomto kroku nemění: figurky zatím střílejí.
   Ověř, čím aréna dnes ukazuje pásmo zásahu, a u figurek to nech čitelné i bez změny
   velikosti.
5. **Comcenter:** záložky SVĚT, JEDNOTKY, MANÉVRY, OBCHOD. SVĚT = dnešní
   `PieceSkinPicker` (náhled obou armád), u Vesmíru výběr flotily přesunutý
   z `_UnitsTab`, a vzhled figurek. JEDNOTKY = vylepšení rolí, kreslená jednotkami
   zvoleného světa. V lobby vedle výběru desky řádek se zvoleným světem, který výběr
   otevře.
5b. **Obchod:** `StoreCatalog` prodává placené světy (`StoreItemKind.world`, id
   `${_prefix}world_<slug>`, USD 0,99); Commander Edition je zahrnuje. `Entitlements`
   zamyká výběr světa jako dnes flotily; vrácený nákup vrátí výběr na Vesmír.
   Doplň tabulku produktů v `docs/store-listing.md`.
6. **Texty:** `pieceSkinClassic` se ukazuje jako Space / Vesmír. Obecné texty mimo
   Vesmír nesmí říkat „loď“ a „flotila“ (projdi ARB, například `upgradeHint`,
   `yourFleet`).
7. **Testy:** každý svět × typ × barva má obrázek; uložené `piece_skin=classic` je
   Vesmír; zamčený svět nejde vybrat;
   `BattleScreen` se světem figurek (`returnsNormally`, horní figurka není vzhůru nohama);
   záložky Comcenteru; `fleet_skin_test` beze změny.
- **Hotovo, když:** v Římě × Kartágu se v aréně utkají římská a kartaginská figurka,
  ve Vesmíru zůstávají symboly a lodě flotily, placené světy jdou koupit a nikde nejsou dva výběry
  vzhledu.

## Krok 3 — nakloněná deska se stojícími figurkami (trať C)

Deska je na telefonu omezená šířkou, výšky je dost. Naklonění pole nezvětší; dovolí
figurce přesahovat nahoru přes pole za ní, takže je při stejném poli větší.

**P2 napřed:** list výchozího postavení jednoho světa figurek na `hex6` i `classic8`
při šířce 360 dp pro zploštění `k` ∈ {1,0; 0,85; 0,72} a výšku figurky ∈ {1,0; 1,25;
1,5} šířky pole. Olin vybere dvojici.

1. **`BoardLayout`** dostane `tilt` (svislé zploštění `k`, rovnoběžné promítání, žádná
   perspektiva): `centreOf` a `cellPath` násobí svislou souřadnici `k`, `positionAt`
   prst nejdřív vrátí do nezploštěného prostoru (nejbližší střed tam zůstává přesný).
   `size` přidá nahoře místo na figurky zadní řady. Vše platí i pro otočenou desku.
2. **Figurky:** ukotvené středem podstavce na střed pole, kreslené od zadní řady
   k přední (pořadí podle polohy na obrazovce, ne podle `geometry.cells`); táhnoucí
   figurka nahoře. Animace tahu a braní zůstávají.
3. **Dotyk:** `resolveTap` z kroku 1 dostane pro stojící figurku druhý záchytný bod
   v polovině její výšky. Klepnutí na hlavu figurky ji vybere, když pole pod prstem
   nedrží nic, co vybrat jde.
4. **Kdy:** jen pro světy figurek (póza `standing`). Vesmír
   a čisté symboly zůstávají ploché. Zvýraznění tahů, mocenská pole a poslední tah
   jdou přes `cellPath`, takže se zploští sama.
5. **Testy:** `board_layout_test` (každé pole obou desek: `positionAt(centreOf(p)) == p`
   s nakloněním, otočené i neotočené; výška desky), pořadí kresby, widgetový test
   klepnutí na hlavu krále a na pěšce za ním.
- **Hotovo, když:** figurka na hexu je při šířce 360 dp vysoká aspoň 40 dp a žádná
  figurka výchozího postavení není zakrytá z více než třetiny.

## Krok 4 — engine boje zblízka do `main` (trať B)

Bez změny chování hry: `ground` zatím nikdo nepoužívá.

1. Nejdřív na čistém `main` znovu zaznamenej výsledky pro `space_duel_regression_test`
   (stejná semínka). Záznam na větvi vznikl před náhlou smrtí a duely delší než 45 s
   už dopadají jinak.
2. Sluč `origin/main` do `claude/melee-lab` (žádný rebase s force pushem). Konflikty
   čekej v `battle_engine.dart`, `battle_ai.dart`, `battle_odds.dart` a `CLAUDE.md`.
   Náhlá smrt má jediný zdroj v `ArenaRules` (`suddenDeathAfterMs`, `suddenDeathRampMs`);
   `space` drží dnešních 45 s a 15 s.
3. Pusť `dart run tools/duel_lab.dart` pro oba světy a přepiš `docs/lab/duel-lab.md`.
- **Hotovo, když:** vesmírné duely sedí na nový záznam na milisekundu i HP, rychlé
  i slow testy jsou zelené a plán 12 je v `main`.

## Krok 5 — boj zblízka ve hře (trať B)

**P3 napřed:** vykreslené fáze úderu ve stolní aréně (nápřah, výpad, kontakt, blok)
pro pěšce a krále ve dvou světech.

1. **Vzájemné zničení** (rozhodnutí 10): dopadnou-li smrtící zásahy obou stran ve stejném
   ticku, z desky zmizí obě figury. Platí ve všech světech a režimech: `BattleState`
   dostane výsledek `mutualDestruction`, `GameEngine` odebere útočníka i obránce,
   `BattleResolvedEvent` ho nese (tolerantní čtení, starší zpráva = výhra útočníka).
   Výsledek arény i zápis do postupu (žádné kredity za remízu) ukaž hráči. Šachová AI
   (`BattleOdds`) počítá remízu jako ztrátu obou figur.
2. **Zapnutí:** `PieceSkin.balance` (`space` nebo `ground`). `BattleEngine.createBattle`
   ji dostane v `singlePlayer` a `hotSeat`; `localWifi` zůstává na `space`. Šachová AI
   (`BattleOdds`, `BoardEvaluator`, `SearchAi` v `compute()`) počítá s balancí hry;
   do izolátu posílej její `id`.
3. **Kresba:** telegraf nápřahu (zóna dopadu v barvě živlu na soupeřově straně), výpad
   po spojnici podle `StrikeRun.lungeAt`, oblouk seku, jiskra bloku, zdržení po bloku.
   Logická poloha jednotky zůstává doma, výpad je jen kresba.
4. **Zvuk:** `BattleSoundCues` pro úder a blok. Do nových zvuků použij kinetický výstřel
   a hlavu výbuchu; nové zvuky přes `tools/battle_audio` jsou samostatný malý PR.
5. **Manévry jednotek zblízka** podle plánu 12, krok 3.4 (`FireCue.contact`). Názvy
   rodin pro stojící světy v l10n (Looping → Výskok, Výkrut → Kotoul, Salva → Smršť);
   id a gesta beze změny.
6. **Texty:** karty vylepšení a „Jak hrát“ nesmí u jednotky zblízka mluvit o střelbě.
- **Hotovo, když:** v Římě × Kartágu pěšec, kůň, věž a král bijí zblízka, střelec
  a dáma střílejí, Vesmír se nezměnil (regresní test) a slow self-play je zelený.

## Krok 6 — jen na Olinův pokyn

- **`localWifi`:** svět hostitele v založení hry a `StrikeStartedEvent`; čtení tolerantní,
  chybějící svět je Vesmír. Do té doby platí rozhodnutí 9.
- **Zoom dvěma prsty:** `InteractiveViewer` kolem desky, nejvýš 1,8×, dvojité klepnutí
  vrací celek. Jen když hex zůstane malý i po krocích 1 a 3.

## Zváženo a zamítnuto

- **Kamera se zoomem jako hlavní řešení:** v deskovce bere přehled a nutí posouvat
  před každým tahem.
- **Hex otočený o 90°** (ploché vršky): pole větší jen o 12 % a mění směry pravidel.
- **Menší nebo protáhlý hexagon:** Olin rozhodl pravidelný hexagon o straně 6.
- **Vlastní balance pro každý svět:** šestnáctkrát víc ladění bez přínosu pro hráče.
- **Boční aréna hned:** tři dny práce a nové ovládání; nejdřív ukázat stolní pohled.

## Odhad

| Krok | Odhad |
|---|---|
| 1 tolerantní dotyk | 0,5 dne |
| 2 svět jako jeden výběr | 4 dny |
| 3 nakloněná deska | 3 dny |
| 4 engine zblízka do `main` | 1 den |
| 5 boj zblízka ve hře | 4 dny |
| 6 `localWifi`, zoom | 2 dny a 1 den |

## Rizika

- **Zákryty na nakloněné desce**, hlavně král před pěšcem. Proto P2 a mez „nejvýš
  třetina“; ústupem je menší naklonění.
- **Figurka bez animace působí v aréně staticky.** Styl oživlé figurky je záměr; pohyb
  nesou výpad, výskok a efekty. Pózy nápřahu a úderu jsou pozdější vylepšení.
- **Výška jako rozměr zásahu** nemá u figurek oporu ve velikosti a stínu. Pásmo zásahu
  musí být vidět jinak (krok 2.4), jinak hráč nepozná, proč minul.
- **Placené flotily jsou vidět jen ve Vesmíru.** Popis v obchodě to musí říkat.
- **Nové produkty:** světy za USD 0,99 se v Google Play dají založit až po nahrání AAB
  s nimi; pak je importuj do RevenueCat. To dělá Olin, plán jen připraví katalog
  a `docs/store-listing.md`.
- **Sloučení větve zblízka** naráží na náhlou smrt; proto nový záznam před sloučením.

## Mimo rozsah

- Nová grafika: zadní pohledy figurek, pózy úderu, varianty bez podstavce.
- Komba (plán 12, krok 3.5), boční aréna, aréna v online hře.
- Změna cen, telemetrie zvoleného světa (měnila by text zásad soukromí).
- Nové typy figur, frakční schopnosti, další tvary desky.
