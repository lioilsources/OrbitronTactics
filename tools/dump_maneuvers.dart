// Dumps the maneuver catalog for the olin.now fleet gallery.
//
// Two files, because the gallery is a static site with one dynamic part:
//   maneuvers.tsv   one row per maneuver — everything the page prints as text
//                   (bash generates the cards, so it must not need a JSON parser)
//   maneuvers.json  the flight paths, sampled through `Maneuver.poseAt`, for the
//                   canvas that animates them
//
// Sampling rather than re-deriving the easing and anchors in JavaScript: the
// point of the gallery is to show the paths the engine actually flies, and a
// second implementation would drift from this one the first time a curve changes.
//
//   dart run tools/dump_maneuvers.dart [out-dir]      (default: build/maneuvers)
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/spot.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_catalog.dart';

/// Samples per maneuver. The canvas interpolates between them, so this only has
/// to be fine enough for the tightest curve (the loop) to stay round.
const int samples = 61;

/// Where the demo ship starts: mid-arena, low, the way a maneuver usually begins.
const Spot demoOrigin = (x: 0.5, altitude: 0.12);

/// The demo enemy drifts, so a maneuver anchored to [Anchor.enemyLive] visibly
/// chases it instead of flying a path that happens to look fixed.
Spot demoEnemy(double t) => (
      x: 0.62 + 0.2 * math.sin(2 * math.pi * t),
      altitude: 0.74 + 0.12 * math.sin(4 * math.pi * t),
    );

double r(double v) => double.parse(v.toStringAsFixed(3));

String unlockOf(Unlock unlock) => switch (unlock) {
      StarterUnlock() => 'starter',
      WinsUnlock(:final wins) => 'wins:$wins',
      PackUnlock(:final packId) => 'pack:$packId',
    };

void main(List<String> args) {
  final outDir = Directory(args.isEmpty ? 'build/maneuvers' : args.first)
    ..createSync(recursive: true);

  final enemyAtStart = demoEnemy(0);
  final rows = <String>[];
  final paths = <String, Object>{};

  for (final ship in PieceType.values) {
    for (final maneuver in ManeuverCatalog.forShip(ship)) {
      // ---- the text row ----
      final shots = maneuver.fire.fold<int>(0, (sum, cue) => sum + cue.shots);
      final tags = <String>[
        if (maneuver.shield) 'shield',
        if (maneuver.keepsControl) 'control',
        if (maneuver.mirrorable) 'mirror',
      ];
      rows.add([
        maneuver.id,
        ship.name,
        maneuver.family.name,
        maneuver.tier.name,
        maneuver.name,
        maneuver.description,
        '${maneuver.energyCost}',
        '${maneuver.durationMs}',
        maneuver.pattern.join('-'),
        unlockOf(maneuver.unlock),
        maneuver.price?.toString() ?? '',
        maneuver.untouchable == null
            ? ''
            : '${r(maneuver.untouchable!.$1)}-${r(maneuver.untouchable!.$2)}',
        tags.join(','),
        '$shots',
      ].join('\t'));

      // ---- the sampled flight path ----
      final pose = <List<double>>[];
      for (var i = 0; i < samples; i++) {
        final t = i / (samples - 1);
        final p = maneuver.poseAt(
          t,
          context: ManeuverContext(
            origin: demoOrigin,
            enemyAtStart: enemyAtStart,
            enemyLive: demoEnemy(t),
          ),
        );
        pose.add([
          r(p.x),
          r(p.altitude),
          r(p.attitude.roll),
          r(p.attitude.pitch),
          r(p.attitude.flip),
          r(p.attitude.boost),
        ]);
      }
      paths[maneuver.id] = {
        'd': maneuver.durationMs,
        'p': pose,
        'f': [
          for (final cue in maneuver.fire) [r(cue.t), cue.shots, r(cue.spread)],
        ],
        if (maneuver.untouchable != null)
          'u': [r(maneuver.untouchable!.$1), r(maneuver.untouchable!.$2)],
        if (maneuver.keepsControl) 'c': 1,
      };
    }
  }

  File('${outDir.path}/maneuvers.tsv').writeAsStringSync('${rows.join('\n')}\n');
  File('${outDir.path}/maneuvers.json').writeAsStringSync(jsonEncode({
    'samples': samples,
    'origin': [demoOrigin.x, demoOrigin.altitude],
    'enemy': [
      for (var i = 0; i < samples; i++)
        [r(demoEnemy(i / (samples - 1)).x), r(demoEnemy(i / (samples - 1)).altitude)],
    ],
    'paths': paths,
  }));

  stderr.writeln('${rows.length} maneuvers -> ${outDir.path}');
}
