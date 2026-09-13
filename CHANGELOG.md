# Changelog

## [13/09/2026]
- Maneuvers: draw a gesture on the 3×3 pad and the ship flies it on its own — sidesteps, loops, barrel rolls, slaloms, dashes and a signature move for every unit type, firing from the maneuver's own plan
- Every ship has twelve shared maneuver families in its own variant plus a signature of its own; the mirrored gesture flies the mirrored maneuver
- Energy pays for them: 50 at the start of a battle, 100 at most, 12 a second back
- Four armed slots per ship; new maneuvers come from battles won with that ship, credits, or a pack
- Comcenter splits into Units and Maneuvers, where gestures are armed, bought and trained
- Ships now travel the whole of their half of the arena: lowest at their own edge, highest just short of the divider
- The AI pilot flies maneuvers too — how many it knows and how often it reaches for one depends on the difficulty

## [11/09/2026]
- Battle music: every attacking unit type brings its own theme, from the pawn's fast synthwave to the king's dark orchestra
- Sound effects per element: a shot like firing a pistol and an explosion with a long echo; impacts play the head of the explosion, a destroyed ship the whole echo
- Sound on/off button in the battle header
- Climbing also carries a ship a little forward, toward the enemy, and diving back, so altitude changes read at a glance
- Altitude in the battle arena: drag forward to climb, back to dive; ships grow and cast longer shadows as they climb, and bank into their turns
- A shot flies at the altitude it was fired from and hits only a ship at about that altitude; shots off their target's altitude are dimmed
- Elemental shots and explosions: pawn slugs, knight water, bishop fire, rook ice, queen and king electricity; impacts scale with the shot's power, and the losing ship explodes before the result shows
- The AI pilot matches its target's altitude and also dodges by climbing or diving; WiFi battles sync altitude
- Ship art for the battle arena: ten fleets, each with a white and a black ship for every unit type
- Pick your fleet in the Comcenter; each AI difficulty flies its own (Easy Star Nomads, Medium Iron Armada, Hard Void Hive)
- Arena ships scale with the arena around the hit width, heavier ships larger; the unit panels show the ship

## [10/09/2026]
- Single Player mode against an on-device AI: Easy, Medium or Hard, playing either color
- Board AI: one-ply greedy play (Easy, Medium) and a Hard alpha-beta search that treats captures as battle chance nodes, running on a background isolate
- Battle AI flies its own ship in the arena: aims, dodges incoming fire, raises the shield
- Fleet progress for the player and each AI difficulty — battle credits, upgrades, win/loss record — saved on the device; AI fleets upgrade within a rubber band of the player's fleet
- Comcenter upgrades the saved player fleet; the board animates opponent moves

## [12/02/2026]
- Disconnect handling for multiplayer via Supabase Presence
- Fix turn bar visibility and multiplayer networking bugs

## [09/02/2026]
- Release APK added to project root for easy distribution
- Alpha 0.1.0-alpha.1: Android release build

## [08/02/2026]
- Phase 2b: Threat indicators — red badge on endangered pieces
- Phase 2: UI polish — animations, power field glow, game over overlay
- Supabase config secured, cloud deployment plan documented

## [07/02/2026]
- Phase 3: Supabase multiplayer transport + lobby UI
- Phase 3: Abstract transport layer + mock networking
- Phase 1: Core game logic, board UI, and local hot-seat mode
