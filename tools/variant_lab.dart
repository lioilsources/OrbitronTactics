// Board variant lab: Medium against Medium on every board variant.
//
//   dart run tools/variant_lab.dart [games] [variant,variant,...]
//
// Prints per variant: white's wins, mean moves, mean captures (= battles),
// how the games were won and the share still unfinished at the ply limit.
// Seeded: the same arguments print the same table.
import 'dart:io';
import 'dart:math';

import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/board_ai.dart';
import 'package:orbitron_tactics/core/ai/self_play.dart';
import 'package:orbitron_tactics/core/game_logic/board/board_spec.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/victory_condition.dart';

const maxPlies = 300;

void main(List<String> args) {
  final games = args.isNotEmpty ? int.parse(args[0]) : 200;
  final specs = args.length > 1
      ? [for (final id in args[1].split(',')) BoardSpec.byId(id)]
      : BoardSpec.all;

  stdout.writeln('Medium vs Medium, $games games per variant, '
      'unfinished = no winner after $maxPlies moves\n');
  stdout.writeln(_row([
    'variant', 'cells', 'army', 'white wins', 'moves', 'captures',
    'fields', 'royals', 'infiltr.', 'unfinished', 's/game',
  ]));
  stdout.writeln(_row(List.filled(11, '---')));

  for (final spec in specs) {
    final clock = Stopwatch()..start();
    var whiteWins = 0;
    var decided = 0;
    var plies = 0;
    var captures = 0;
    var unfinished = 0;
    final wins = <String, int>{};
    for (var game = 0; game < games; game++) {
      final white =
          BoardAi.forProfile(AiProfile.medium, random: Random(1000 + game));
      final black =
          BoardAi.forProfile(AiProfile.medium, random: Random(2000 + game));
      final result = playSelfPlayGame(white, black, Random(game),
          maxPlies: maxPlies, spec: spec);
      plies += result.plies;
      captures += result.captures;
      final victory = result.victory;
      if (victory == null) {
        unfinished++;
        continue;
      }
      decided++;
      if (result.winner == PlayerColor.white) whiteWins++;
      final kind = switch (victory) {
        PowerFieldDomination() => 'fields',
        RoyalElimination() => 'royals',
        Infiltration() => 'infiltration',
        Abandonment() => 'abandonment',
      };
      wins[kind] = (wins[kind] ?? 0) + 1;
    }
    clock.stop();

    String share(int n) => '${(100 * n / games).round()} %';
    stdout.writeln(_row([
      spec.id,
      '${spec.geometry.cells.length}',
      '${spec.armySize}',
      decided == 0 ? '-' : '${(100 * whiteWins / decided).round()} % of $decided',
      (plies / games).toStringAsFixed(1),
      (captures / games).toStringAsFixed(1),
      share(wins['fields'] ?? 0),
      share(wins['royals'] ?? 0),
      share(wins['infiltration'] ?? 0),
      share(unfinished),
      (clock.elapsedMilliseconds / 1000 / games).toStringAsFixed(2),
    ]));
  }
}

String _row(List<String> cells) => '| ${cells.join(' | ')} |';
