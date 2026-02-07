# OrbitronTactics - Implementation Plan

## Context

Strategická desková hra pro dva hráče přes síť, inspirovaná šachy, ale s unikátními mechanikami: power fields (kontrolní body), sniping, infiltrace a pravidlo Last Warrior. Cílem je vytvořit kompletní Flutter mobilní aplikaci (iOS + Android) s real-time multiplayer přes Supabase.

Projekt startuje z prázdného adresáře `/Volumes/YOTTA/Dev/OrbitronTactics`.

---

## Pravidla hry (finální)

### Deska
- 8x8 mřížka, 5 power fields (náhodně z 8 symetrických variant, spravedlivě)

### Figurky (16 na hráče)
8 pěšců + 2 věže + 2 jezdci + 2 střelci + 1 královna + 1 král

### Pohyb figurek
| Figurka | Pohyb | Speciální |
|---------|-------|-----------|
| **Pěšec** | Do stran a dozadu: chodí, NEBERE. Šikmo dopředu: chodí I bere. Přímo dopředu: NEMŮŽE. | Infiltrace = výhra |
| **Střelec** | Max 3 šikmo (sliding) | Snipe: přesně +3 přímo dopředu (přeskakuje) |
| **Věž** | Max 4 rovně (sliding) | — |
| **Jezdec** | Normální L dopředu/do stran | Dozadu jen "nízké L" (1 dozadu, 2 do strany). Blokován věží přímo před ním |
| **Královna** | Max 4 šikmo + max 2 rovně (sliding) | — |
| **Král** | Max 4 rovně + max 2 šikmo (sliding) | — |
| **Last Warrior** | +1 všemi 8 směry | Vznikne z přeživší královské figurky |

### Speciální pravidla
- **Last Warrior**: Když padne král NEBO královna → ta zbývající se oslabí na +1 všemi směry. Ostatní figurky beze změny.
- **Prohra**: Padne král I královna → okamžitá prohra.

### Podmínky výhry (3 způsoby)
1. **Power Field Domination** — obsadit všech 5 power fields na konci svého tahu
2. **Royal Elimination** — sebrat soupeři krále I královnu
3. **Infiltration** — jakýkoli pěšec dosáhne soupeřovy zadní řady

### Formace
- Obě strany volí startovní rozestavení nezávisle a tajně
- Detaily formací budou upřesněny později

---

## Architektura

### Klíčová technická rozhodnutí

1. **Riverpod 3.0** — state management s code generation (`@riverpod`)
2. **Freezed** — immutable modely s `copyWith`, deep equality, JSON serializace
3. **CustomPainter** — rendering desky (ne Flame engine — pro tahovou hru overkill)
4. **Supabase Broadcast** — real-time synchronizace tahů (nízká latence, ephemeral)
5. **Supabase Edge Functions** — server-side validace tahů (anti-cheat)
6. **Pure Dart game logic** — herní pravidla bez Flutter závislostí, portovatelné do TypeScript

### Projektová struktura

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── board_constants.dart          # BOARD_SIZE=8, POWER_FIELD_COUNT=5
│   │   └── supabase_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── board_theme.dart
│   ├── utils/
│   │   └── board_utils.dart              # Koordinátové konverze, flipping
│   └── game_logic/                       # PURE DART — zero Flutter dependencies
│       ├── models/
│       │   ├── position.dart
│       │   ├── piece.dart                # PieceType, PlayerColor, isLastWarrior
│       │   ├── board_state.dart          # 8x8 grid + power fields
│       │   ├── power_field.dart
│       │   ├── move.dart
│       │   ├── game_state.dart           # Board + turn + phase + history
│       │   ├── player.dart
│       │   ├── formation.dart
│       │   ├── game_phase.dart
│       │   └── victory_condition.dart    # Sealed union
│       ├── validators/
│       │   ├── move_validator.dart       # Centrální dispatcher
│       │   ├── pawn_validator.dart
│       │   ├── rook_validator.dart
│       │   ├── bishop_validator.dart
│       │   ├── knight_validator.dart
│       │   ├── queen_validator.dart
│       │   ├── king_validator.dart
│       │   ├── last_warrior_validator.dart
│       │   └── path_checker.dart         # Sdílená utilita pro sliding figurky
│       └── engine/
│           ├── game_engine.dart          # applyMove() → nový GameState
│           ├── victory_checker.dart
│           ├── power_field_generator.dart # 8 symetrických variant
│           ├── formation_validator.dart
│           └── last_warrior_rule.dart
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   └── presentation/...
│   ├── matchmaking/
│   │   ├── data/matchmaking_repository.dart
│   │   └── presentation/...
│   ├── formation/
│   │   └── presentation/...              # Drag & drop rozmístění figurek
│   └── game/
│       ├── data/
│       │   ├── game_repository.dart
│       │   ├── game_realtime_service.dart # Broadcast channel
│       │   └── move_submission_service.dart
│       └── presentation/
│           ├── providers/
│           │   ├── game_state_provider.dart
│           │   └── board_interaction_provider.dart
│           ├── screens/
│           │   ├── game_screen.dart
│           │   └── game_result_screen.dart
│           └── widgets/board/
│               ├── game_board.dart              # Top-level: Stack + GestureDetector
│               ├── board_background_painter.dart # Čtverce + power fields
│               ├── board_overlay_painter.dart    # Highlights, valid moves
│               ├── piece_layer.dart             # AnimatedPositioned figurky
│               └── piece_widget.dart
├── routing/
│   └── app_router.dart                   # GoRouter
└── services/
    └── supabase_service.dart

supabase/
├── migrations/
│   ├── 001_create_profiles.sql
│   ├── 002_create_games.sql
│   ├── 003_create_matchmaking.sql
│   └── 004_create_rls_policies.sql
└── functions/
    ├── validate-move/index.ts            # Server-side validace tahů
    ├── create-game/index.ts
    ├── submit-formation/index.ts
    └── _shared/
        ├── game_logic.ts                 # TS port pravidel
        └── types.ts

test/
├── core/game_logic/
│   ├── validators/                       # 7 validator testů (~120+ test cases)
│   └── engine/                           # Engine, victory, power fields, last warrior
├── features/game/
└── integration/
```

### Supabase databáze

**Tabulky:**
- `profiles` — hráčský profil (rating, statistiky)
- `games` — stav hry (board_state JSONB, power_fields, formace, tah, historie)
- `matchmaking_queue` — fronta pro hledání soupeře
- `game_events` — audit log pro replay

**Real-time komunikace:**
- Kanál `game:{game_id}` přes Supabase Broadcast
- Eventy: `formation_locked`, `game_started`, `move_validated`, `game_over`

**Flow tahu:**
```
Hráč klikne → lokální validace (instant feedback) → optimistický update
  → Edge Function validate-move → server validace → uložení do DB
  → Broadcast obou hráčům → reconciliace stavu
```

---

## Fáze implementace

### Fáze 1: Základ + herní logika (Týden 1-2)
1. `flutter create orbitron_tactics` + závislosti
2. Všechny Freezed modely (Position, Piece, Board, GameState, Move, ...)
3. Všech 7 piece validatorů + PathChecker
4. GameEngine + VictoryChecker + LastWarriorRule + PowerFieldGenerator
5. Základní board UI (CustomPainter + tap-to-move)
6. **Lokální hot-seat mód** na jednom zařízení
7. **120+ unit testů** pro herní logiku

**Výstup:** Plně funkční lokální hra se všemi pravidly.

### Fáze 2: UI polish + formace (Týden 3)
1. Formation screen (drag & drop rozmístění)
2. Animace tahů (AnimatedPositioned ~200ms)
3. Animace braní (fade + scale)
4. Power field vizuály (glow/pulse)
5. Game result screen
6. Piece assety (SVG/PNG)

**Výstup:** Krásná, kompletní single-device hra.

### Fáze 3: Supabase backend + multiplayer (Týden 4-5)
1. Supabase projekt + migrace + RLS
2. Auth (email/heslo pro MVP)
3. Edge Functions (validate-move, create-game, submit-formation)
4. Port herní logiky do TypeScript
5. Matchmaking (fronta + automatické párování)
6. Game real-time sync (Broadcast + optimistické updaty + reconnect)

**Výstup:** Dva hráči na oddělených zařízeních hrají přes síť.

### Fáze 4: Robustnost (Týden 6)
1. Reconnection handling
2. Error handling + retry
3. Anti-cheat hardening
4. Performance optimalizace
5. Platform-specific handling (lifecycle, back button)

### Fáze 5: Nice-to-have (Týden 7+)
- Replay viewer, spectator mode, zvuky, haptics, tutorial, push notifikace, friend system

---

## Závislosti

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^4.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  supabase_flutter: ^2.8.0
  go_router: ^14.0.0
  flutter_svg: ^2.0.0
  uuid: ^4.0.0
  collection: ^1.18.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^4.0.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mocktail: ^1.0.0
```

---

## Verifikace

1. `flutter test` — 120+ unit testů pro herní logiku
2. `flutter run` — lokální hra, ověřit všechna pravidla ručně
3. Ověřit pohyby všech figurek (zejména pěšec, jezdec, střelec-snipe)
4. Ověřit všechny 3 výherní podmínky
5. Ověřit Last Warrior transformaci
6. Test multiplayer na 2 zařízeních/emulátorech
7. Test reconnectu (kill app, přijít zpět)
8. Test power field symetrie (žádná strana nemá výhodu)
