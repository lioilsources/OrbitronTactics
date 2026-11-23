# Archion → Babylon.js: mapa portu

Webový klient Archionu v TypeScriptu nad Babylon.js. Zdroj pravdy je Flutter aplikace v kořeni repa
(pravidla v `lib/core/`). Plán: `DevConventions/Prompts/06-PLAN-babylon-web.md` (Archion = řádek 3, vlna 1B,
„nejdřív hot-seat“). Vzor: pilot RattleRamp (`ChrestysSkatepark/babylon/`).
Stav: **F0 (audit a spike)**: klasická deska 8×8 i hex6 s výchozí formací a silovými poli, ortografická kamera,
klepnutí vybere figurku hráče na tahu. Tahy, bitvy ani konec hry zatím nejsou. Hostování: GitHub Pages repa,
hra pod `/play/` (workflow `web.yml` čeká na přepnutí zdroje Pages, viz níže).

## Úrovně parity

- **P0** – diskrétní pravidla: tahy figur, braní, silová pole, Last Warrior, podmínky vítězství, výběr tahu AI
  na desce, odměny, ceny upgradů. Shoda bit po bitu přes zlaté vektory z Dartu (`tool/dump_vectors.dart` → `babylon/test/golden/`, F1).
- **P1** – spojitá simulace: bitva v aréně (`BattleEngine`, střely, manévry, melee, sudden death) a pilot `BattleAi`.
  ±5 % ve scénářích (délka bitvy, počet zásahů, výsledek seedovaného duelu `Duel`).
- **P2** – vzhled: stejný výchozí pohled (deska shora, ortograficky), barvy z `board_theme.dart`, rozložení obrazovek.

## Vrstvy

| Složka | Obsah | Hranice (ESLint) |
|---|---|---|
| `src/rules/` | port `lib/core/` + čistá geometrie desky (`BoardLayout`, `resolveTap`) | bez `@babylonjs/*`, bez DOM globálů, bez `game/` a `ui/` |
| `src/game/` | Babylon scéna, herní smyčka, napojení vstupu | smí vše |
| `src/ui/` | DOM overlay a Canvas 2D kreslení desky a figurek | bez Babylonu, bez `game/` |
| `scripts/` | generátory přes `tsx` (čtou Dart zdroje) | — |

## Mapa Dart → TS po souborech

Řádky = `wc -l` k 23. 11. 2026 (bez `*.g.dart` a `*.freezed.dart`). Celkem `lib/` 20 742 ř. (plán uváděl 9 454, od té doby
přibyly manévry, obchod, melee, hex deska a l10n). Fáze: **F0 hotovo** = v tomto PR, jinak plán.

### `lib/core/game_logic/` (3 408 ř., čistý Dart) → `src/rules/`

| Dart | ř. | TS | Parita | Fáze | Poznámka |
|---|---|---|---|---|---|
| `models/piece.dart`, `position.dart`, `player.dart` | 78 | `rules/piece.ts` | P0 | **F0 hotovo** (piece, position) | `freezed` → readonly objekty; rovnost přes `samePos` / `posKey` |
| `models/board_state.dart` | 108 | `rules/board-state.ts` | P0 | **F0 hotovo** | grid, `setPiece`, `movePiece`; `findPieces`, `powerFieldCount` v F1 |
| `board/board_spec.dart` | 213 | `rules/board-spec.ts` | P0 | **F0 hotovo** (classic8, hex6) | lab varianty (skirmish6, tall8x10, grand10, rocks8, hex6_*) v F1 jen kvůli vektorům, v menu ne |
| `board/board_geometry.dart` | 472 | `rules/board-geometry.ts` | P0 | **F0** buňky, zrcadlo, vzdálenost; **F1** směry, dosahy, skoky jezdce, snipe, `CornerBlock` | |
| `engine/power_field_generator.dart` | 179 | `rules/board-state.ts` (`generatePowerFields`, `symmetricFields`) | P0 | **F0** varianty a symetrie; **F1** Dart `Random` | viz Odchylky 2 |
| `engine/game_engine.dart` | 233 | `rules/game-engine.ts` | P0 | F0 `defaultFormation`; F1 zbytek | `createGame`, `applyFormation`, `applyMove`, `tryMove`, `resolveBattle` |
| `engine/formation_validator.dart` | 58 | `rules/formation.ts` | P0 | F1 | |
| `engine/last_warrior_rule.dart` | 42 | `rules/last-warrior.ts` | P0 | F1 | |
| `engine/victory_checker.dart` | 48 | `rules/victory.ts` | P0 | F1 | 4 podmínky: silová pole, královský pár, infiltrace, opuštění |
| `engine/upgrade_engine.dart` | 48 | `rules/upgrades.ts` | P0 | F1 | zaokrouhlení jako Dart `round()` |
| `engine/unit_base_stats.dart` | 48 | `rules/unit-stats.ts` | P0 | F1 | čísla generátorem z Dartu, ne ručně |
| `engine/battle_engine.dart` | 520 | `rules/battle-engine.ts` | P1 (+P0 výsledek seedovaného duelu) | F2 | pevný krok, `Projectile`, `Impact`, `ManeuverRun`, `StrikeRun`, štít |
| `models/*` ostatní (battle_state, battle_unit, impact, projectile, maneuver_run, strike_run, shield_state, unit_stats, upgrade_profile, fleet_progress, ship_maneuvers, game_state, move, formation, victory_condition, game_phase, spot, weapon_type) | 898 | `rules/models.ts` + soubory u enginů | P0/P1 | F1–F3 | JSON tvar zachovat (replaye, vektory) |
| `services/threat_analyzer.dart` | 34 | `rules/threats.ts` | P0 | F1 | červený odznak „!“ |
| `validators/*` (10 souborů) | 429 | `rules/validators.ts` | P0 | F1 | největší zdroj vektorů: všechny legální tahy z náhodných pozic na obou deskách |

### `lib/core/` ostatní

| Dart | ř. | TS | Parita | Fáze | Poznámka |
|---|---|---|---|---|---|
| `ai/board_ai.dart`, `board_evaluator.dart`, `move_generator.dart`, `cell_set.dart`, `battle_odds.dart` | 868 | `rules/ai/*.ts` | P0 (Easy/Medium), P1 (Hard: alfa-beta s náhodou) | F3 | Hard v Flutteru běží přes `compute()`; na webu Web Worker |
| `ai/battle_ai.dart` | 414 | `rules/ai/battle-ai.ts` | P1 | F3 | 700ms hodiny manévrů |
| `ai/ai_difficulty.dart`, `fleet_progression.dart` | 254 | `rules/ai/profile.ts` | P0 | F3 | `AiProfile` laditelné konstanty = jeden zdroj, generovat |
| `ai/duel.dart`, `self_play.dart` | 196 | `test/` (headless duely pro P1) | P1 | F2 | nástroj, ne hra |
| `maneuvers/maneuver.dart`, `maneuver_catalog.dart`, `maneuver_pattern.dart`, `pattern_recognizer.dart` | 1 314 | `rules/maneuvers/*.ts` | P0 (rozpoznání gesta, katalog), P1 (dráha `poseAt`) | F3 | katalog dumpovat do JSON (už existuje `tools/dump_maneuvers.dart`) |
| `worlds/world_balance.dart` | 152 | `rules/world-balance.ts` | P0 | F2 | melee (plán 14 krok 4) |
| `theme/board_theme.dart` | 37 | `ui/generated/board-theme.ts` | P2 | **F0 hotovo** | `npm run gen`, test `theme-sync` hlídá rozjezd. Jediný soubor `core/` s importem Flutteru |
| `constants/board_constants.dart` | 16 | `rules/board-spec.ts` | P0 | F1 | |
| `constants/supabase_constants.dart`, `release_constants.dart` | 41 | — | — | — | online lobby se na webu vypouští |
| `telemetry/telemetry.dart` | 29 | — | — | — | web bez telemetrie |

### `lib/features/game/` (5 015 ř.) → `src/game/` + `src/ui/`

| Dart | ř. | TS | Parita | Fáze | Poznámka |
|---|---|---|---|---|---|
| `widgets/board/board_layout.dart` | 143 | `rules/board-layout.ts` | P0 (umístění, zásah) / P2 | **F0 hotovo** | čistá geometrie bez `dart:ui`; testy podle `board_layout_test.dart` |
| `widgets/board/tap_resolver.dart` | 44 | `rules/board-layout.ts` (`resolveTap`, `tapReachFor`) | P0 | **F0 hotovo** | tolerance 0,8 pole na hexu (plán 14 krok 1) |
| `widgets/board/board_background_painter.dart` | 98 | `ui/board-paint.ts` (`paintCells`, `paintFieldFills`) | P2 | **F0 hotovo** | Canvas 2D do DynamicTexture; pulz silových polí = alfa materiálu (viz Odchylky 3) |
| `widgets/board/board_overlay_painter.dart` | 93 | `ui/board-paint.ts` (`paintOverlay`) | P2 | **F0 hotovo** (výběr, cíle, braní) | poslední tah v F2 |
| `widgets/board/piece_renderer.dart` | 208 | `ui/piece-paint.ts` | P2 | **F0** klasické figurky; F3 obrázkové packy | |
| `widgets/board/game_board.dart` | 449 | `game/board-scene.ts`, `game/main.ts`, `rules/interaction.ts` | P0 (výběr) / P2 | **F0** výběr; F2 tahy a animace (200 ms posun, 300 ms zánik) | |
| `providers/board_interaction_provider.dart` | 46 | `rules/interaction.ts` | P0 | **F0 hotovo** | |
| `providers/game_state_provider.dart` | 390 | `game/match.ts` | P0 | F2 (hot-seat), F3 (single player) | `GameMode.hotSeat` a `singlePlayer`; `multiplayer`, `localWifi` vypadávají |
| `providers/ai_opponent_controller.dart` | 359 | `game/ai-opponent.ts` | P0/P1 | F3 | odměny a výsledky do localStorage |
| `providers/piece_skin_provider.dart`, `data/piece_skin.dart` | 269 | `ui/piece-skins.ts` | P2 | F3 | 16 packů + classic, barvy polí z Dartu generátorem |
| `screens/game_screen.dart` | 827 | `ui/game-hud.ts`, `game/main.ts` | P2 | F2 | hráči, skóre polí, kdo je na tahu, výsledek |
| `screens/lobby_screen.dart` | 959 | `ui/menu.ts` | P2 | F2 (hot-seat + výběr desky), F3 (single player) | online/Wi-Fi část se vypouští |
| `data/game_event.dart`, `game_session.dart`, `game_transport.dart` | 717 | — (F2 jen to, co hot-seat potřebuje z `game_session`) | — | — | síťová vrstva |
| `data/supabase_game_transport.dart`, `local_wifi_game_transport.dart`, `game_repository.dart`, `providers/lobby_providers.dart` | 413 | — | — | — | vypouští se |

### `lib/features/battle/` (2 871 ř.) → aréna

| Dart | ř. | TS | Parita | Fáze | Poznámka |
|---|---|---|---|---|---|
| `screens/battle_screen.dart` | 715 | `game/arena-scene.ts`, `ui/arena-hud.ts` | P2 | F2 | vstup: x prstu = pozice, tah dopředu/dozadu = výška |
| `widgets/battle_arena_painter.dart`, `explosion_fx.dart`, `ship_bank.dart`, `arena_layout.dart` | 893 | `game/arena-scene.ts` (sprity na rovinách, výška = velikost + stín) | P2 (`ArenaLayout` P0) | F2 | |
| `widgets/maneuver_pad.dart`, `pattern_glyph.dart`, `shield_button.dart`, `unit_combat_panel.dart` | 596 | `ui/maneuver-pad.ts` aj. | P0 (rozpoznání) / P2 | F3 | Pointer Events |
| `providers/battle_state_provider.dart`, `ship_sprite_provider.dart` | 257 | `game/battle.ts`, `ui/sprites.ts` | P1 | F2 | |
| `audio/battle_audio.dart`, `battle_sound_cues.dart`, `data/battle_music.dart`, `battle_sounds.dart` | 319 | `ui/audio.ts` (Web Audio, odemčení prvním dotykem) | P2 | F3 | OGG nehraje Safari < 17; viz Assety |
| `data/battle_element.dart`, `fleet_skin.dart` | 91 | `rules/elements.ts`, `ui/fleets.ts` | P2 | F2 | |

### Ostatní `lib/`

| Dart | ř. | TS | Parita | Fáze | Poznámka |
|---|---|---|---|---|---|
| `features/comcenter/*` | 911 | `ui/comcenter.ts` | P2 | F3 | upgrady, manévry, výběr flotily (single player) |
| `features/progress/*` | 178 | `ui/progress-store.ts` (localStorage, stejný JSON `fleet_progress.<identity>`) | P0 (formát) | F3 | |
| `features/onboarding/*` | 246 | `ui/how-to-play.ts` | P2 | F3 | |
| `features/store/*` | 1 130 | — | — | — | IAP se na webu vypouští (premium flotily a hudba: viz Co se vypouští) |
| `features/telemetry/*` | 51 | — | — | — | |
| `l10n/*` (ARB en + cs, `content_cs.dart`) | 3 478 | `ui/generated/l10n-*.json` generátorem z `lib/l10n/app_{en,cs}.arb` | P2 | F2 | `?lang=` |
| `main.dart` | 133 | `index.html` + `game/main.ts` | — | **F0** | Sentry, Supabase, RevenueCat se neinicializují |

## Funkce

Seznam pro videa (plán kap. 5a): jedno video = jedna funkce a klient. V F0 videa ani změny na olin.now nevznikají.
Stav **F** = Flutter, **W** = web. Složka videa: `Store/shorts/orbitrontactics/NN-<id>/` (číslování od 01; jestli tam
Archion už něco má, jsem neověřil — repo Store není na tomto stroji naklonované).

| id | Popis | Stav F | Stav W | Video |
|---|---|---|---|---|
| `board` | Deska 8×8 s figurkami a pěti silovými poli, která pulzují v barvě vlastníka | hotovo | **F0** (bez vlastníka v průběhu hry) | `01-board` |
| `hex-board` | Šestiúhelníková deska hex6 (91 polí), tolerantní dotyk | hotovo | **F0** (bez tahů) | `02-hex-board` |
| `moves` | Vlastní pohyby figur (věž do 4, střelec do 3, dáma 2/4, král 4/2, jezdec s blokací, pěšec do stran i dozadu), nápověda cílů | hotovo | F1/F2 | `03-moves` |
| `threats` | Červený odznak na ohrožených figurkách | hotovo | F2 | `04-threats` |
| `power-fields` | Vítězství držením všech pěti silových polí | hotovo | F2 | `05-power-fields` |
| `win-conditions` | Další vítězství: oba královští, infiltrace pěšcem, Last Warrior | hotovo | F2 | `06-win-conditions` |
| `battle` | Braní = bitva lodí v reálném čase: řízení prstem, výška, střely podle elementu | hotovo | F2 | `07-battle` |
| `melee` | Boj zblízka: nápřah, výpad, štít (plán 14) | hotovo (engine) | F2 | `08-melee` |
| `maneuvers` | Manévry kreslené gestem, energie, nedotknutelné okno | hotovo | F3 | `09-maneuvers` |
| `sudden-death` | Po 45 s roste zásahová zóna, nikdo neuhne | hotovo | F2 | `10-sudden-death` |
| `hot-seat` | Dva hráči na jednom zařízení | hotovo | F2 | `11-hot-seat` |
| `single-player` | Hra proti AI (Easy, Medium, Hard) | hotovo | F3 | `12-single-player` |
| `fleets` | 10 flotil lodí, výběr v Comcenteru | hotovo | F3 (jen volné flotily, viz Co se vypouští) | `13-fleets` |
| `upgrades` | Kredity z bitev, upgrady jednotek | hotovo | F3 | `14-upgrades` |
| `piece-skins` | 16 světů figurek (Řím × Kartágo, Rytíři × Orkové…) | hotovo | F3 | `15-piece-skins` |
| `audio` | Hudba útočníka a zvuky výstřelů a výbuchů | hotovo | F3 | `16-audio` |
| `how-to-play` | Úvodní návod | hotovo | F3 | `17-how-to-play` |
| `online` | Online lobby přes Supabase | hotovo | — (vypouští se, R5) | jen F |
| `web-play` | Hra v prohlížeči bez instalace, odkaz z olin.now (jen W) | — | F0 nasazení čeká na přepnutí Pages | `18-web-play` |

## Co se na webu vypouští

- **Online lobby (Supabase Realtime, Presence, anonymní přihlášení)** – rozhodnutí R5: nejdřív hot-seat. Anon klíč by ve
  veřejném bundlu viděl každý; před případným návratem ověřit RLS (plán kap. 7).
- **Lokální Wi-Fi hra** (`local_wifi_game_transport.dart`) – prohlížeč neumí hledat zařízení v LAN.
- **Obchod a IAP** (RevenueCat, `features/store/`) – Pages nejsou pro prodej. Na webu jen volné věci: Vanguard a flotily AI,
  standardní hudba, `classic` + packy figurek (jsou zdarma). Premium flotily a retro hudba jen s odkazem do storů (R4: demo + odkazy).
- **Telemetrie a Sentry** – web bez sledování.
- **Store screenshoty, `tools/fleet_art/`, `tools/battle_audio/`** – generování assetů se neportuje (SPARK se nepoužívá).

## Assety

Celkem `assets/` 22 MB (plán uváděl 0,9 MB; od té doby přibyly packy figurek, hudba a flotily).

| Soubor | Velikost | Na webu | Kdy |
|---|---|---|---|
| `fleets/<slug>/<unit>_<white\|black>.png` (10 flotil × 12) | 5,1 MB (420–590 kB / flotila) | ano, jen flotily ve hře; dotáhnout až při první bitvě | F2 (Vanguard), F3 |
| `pieces/<slug>/*.png` (16 packů × 12) | 9,1 MB (520–670 kB / pack) | ano, jen vybraný pack, líně | F3 |
| `audio/music/*.ogg` (6) | 3,2 MB | ano, líně po prvním dotyku | F3 |
| `audio/music_retro/*.ogg` (6) | 3,0 MB | ne (premium) | — |
| `audio/sfx/*.ogg` (10) | 424 kB | ano | F3 |
| `icon/icon.png` | 771 kB | zmenšené PWA ikony v `public/icons/` | F4 |
| `icon/icon_foreground.png` | 771 kB | ne (Android adaptive) | — |
| Fonty | Flutter: Roboto + Material Icons | systémový font; šachové znaky ze systémového fontu (`︎` proti emoji) | F0 |

První obrazovka (deska s klasickými figurkami) nepotřebuje žádný asset. OGG: Safari umí Vorbis až od 17 (iOS 17);
převod na AAC/Opus-in-CAF je změna souborů, rozhodne Olin v F3.

## Měření F0 (lokálně, 23. 11. 2026)

Stroj: MacBook (Apple Silicon), Chromium 1254 přes Playwright, telefonní okno 390×844 @3x s dotykem. Oba buildy servíroval
stejný lokální server s gzip (jako GitHub Pages), cache vypnutá. Mediány ze 3 běhů. „Škrcení“ = 4 Mbit/s, RTT 100 ms, CPU ×4.
První snímek: Babylon `performance.mark('archion-first-frame')` po prvním vykresleném snímku, Flutter událost `flutter-first-frame`.

| | Flutter web (`flutter build web --release`, 3.50.1, CanvasKit) | Babylon spike |
|---|---|---|
| Build na disku | 65 MB (36 MB `canvaskit/`, 25 MB assetů, `main.dart.js` 3,7 MB) | 1,5 MB `dist/` |
| Čas buildu | 107 s (create + pub get + build; samotná kompilace 69 s) | ~3 s (`vite build`) |
| Přeneseno do prvního snímku | 3,07 MB | 0,29 MB (JS 1,20 MB raw / 283 kB gzip) |
| První snímek, rychlá síť | 0,77 s | 0,12 s |
| První snímek, škrcení | 7,11 s | 1,08 s |
| FPS | — | na telefonu měří Olin (`?debug`) |

Flutter při prvním spuštění kreslí úvodní návod (How to Play), ne desku; Babylon rovnou desku. Flutter se měřil na dočasné
kopii projektu (`flutter create --platforms=web` mimo repo, repo `web/` nemá); nic z buildu není v repu.
Cíle plánu (první obrazovka do 3 MB, první snímek do 3 s) Babylon splňuje s velkou rezervou, Flutter web je překračuje.

**Čeká na Olina (po nasazení):** referenční telefon – objem první obrazovky, čas do prvního snímku, FPS (`/play/?debug`).

## Nasazení a stávající Pages

Pages repa dnes servírují `docs/` z `main` (režim legacy, `docs/.nojekyll` je). Na ně odkazují listingy ve storech
(`fastlane/metadata/ios/*/privacy_url.txt`, `support_url.txt`) a README. Workflow `.github/workflows/web.yml`:

- na PR i na `main`: `npm run gate`, pak sestaví `_site/` = celý `docs/` beze změny v kořeni + `babylon/dist/` pod `/play/`,
  a ověří, že v něm jsou `index.html`, `privacy.html`, `support.html`, `icon.png` a `play/index.html`;
- job `deploy` běží jen tehdy, když API hlásí `build_type == workflow`. Do přepnutí zdroje Pages se tedy nic nenasazuje
  a legacy web běží dál.

URL ověřené 23. 11. 2026 (všechny 200): `/`, `/index.html`, `/privacy.html`, `/support.html`, `/icon.png`, `/architecture.md`,
`/store-listing.md`, `/lab/duel-lab.md`, `/store/feature_graphic_en.png`, `/store/screenshots/en/01_lobby.png`; `/play/` 404.
Po přepnutí se mají projít znovu (stejný seznam + `/play/`).

## Deep linky (F0)

`?board=hex6` (výchozí `classic8`), `?seed=<n>` (los silových polí), `?debug` (FPS).

## Odchylky

1. **Větev `claude/babylon-f0`** místo `web/babylon-f0` (plán kap. 6 bod 3): pokyn session, která F0 spustila.
2. **Los silových polí není Dart `Random`.** Klasická deska bere jednu z 8 pevných variant, hex6 symetrická pole; v F0 obojí
   losuje malý LCG (`lcg` v `board-state.ts`). Pro P0 se v F1 portuje Dart `Random` bit po bitu. Navíc Flutter seeduje
   `gameId.hashCode`, a `String.hashCode` se mezi Dart VM a webem liší; vektory proto v F1 budou volat `generateFor`
   s pevným seedem, ne s `gameId`.
3. **Pulz silových polí = alfa materiálu**, ne překreslování textury každý snímek: výplň polí je vlastní vrstva s plnou
   barvou a Babylon mění její alfu 0,3–0,6 (Flutter: `withValues(alpha: glowOpacity)`, stejný výsledek). Křivka
   `easeInOut` je nahrazena kosinem (P2).
4. **Klepnutí přes Pointer Events, ne Babylon `POINTERTAP`**: Babylonův tap s obecným observerem čeká 300 ms na
   případný dvojklik. Práh posunu 18 px (Flutter `kTouchSlop`).
5. **V F0 se na hexu přitahuje ke každé vlastní figurce**, ne jen k té, která má tah (`_tapTargets`): pravidla tahů přijdou v F1,
   pak `tapTargets(..., requireMove: true)`.
6. **Barva pozadí obrazovky `#1A1A2E`** je ve Flutteru natvrdo ve `game_screen.dart` (ne v `BoardTheme`), web ji má jako
   konstantu `SCREEN_BG` v `ui/palette.ts`. Barvy desky a figurek generuje `npm run gen` z `board_theme.dart`.
7. **Zlaté vektory a job `golden` ve `web.yml` až v F1**: F0 neportuje žádné pravidlo, které by vektory potřebovalo
   (geometrie a výběr mají jednotkové testy podle Dart testů).
