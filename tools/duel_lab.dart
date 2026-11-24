// Arena balance lab: seeded AI duels for every unit pairing of a world.
//
//   dart run tools/duel_lab.dart [--world ground] [--duels 200]
//       [--pilot medium] [--limit 180] [--contact 0.4]
//
// --contact tries another ArenaRules.contactDamageScale for the world.
//
// Prints, per attacker/defender pairing, the attacker's win share, the
// median duel length, the share of duels that hit the time limit, the
// share of mutual destruction and the `BattleOdds` estimates next to the
// simulated shares. Then checks the acceptance bounds of plan 12, step 1B.

import 'dart:io';

import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/battle_odds.dart';
import 'package:orbitron_tactics/core/ai/duel.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';

class _Cell {
  final double winShare;
  final double medianS;
  final double capShare;
  final double drawShare;
  final double odds;
  final double drawOdds;
  const _Cell(this.winShare, this.medianS, this.capShare, this.drawShare,
      this.odds, this.drawOdds);
}

void main(List<String> args) {
  String option(String name, String fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final worldId = option('world', 'ground');
  final known = WorldBalance.all.firstWhere((w) => w.id == worldId,
      orElse: () => throw ArgumentError('unknown world $worldId'));
  final contact = double.tryParse(option('contact', ''));
  final balance = contact == null
      ? known
      : WorldBalance(
          id: known.id,
          units: known.units,
          arena: ArenaRules(
            rangeTravelScale: known.arena.rangeTravelScale,
            suddenDeathAfterMs: known.arena.suddenDeathAfterMs,
            suddenDeathRampMs: known.arena.suddenDeathRampMs,
            suddenDeathMaxScale: known.arena.suddenDeathMaxScale,
            energyPerHit: known.arena.energyPerHit,
            contactDamageScale: contact,
          ),
        );
  final duels = int.parse(option('duels', '200'));
  final limitMs = int.parse(option('limit', '180')) * 1000;
  final pilot = switch (option('pilot', 'medium')) {
    'easy' => AiProfile.easy,
    'hard' => AiProfile.hard,
    _ => AiProfile.medium,
  };

  const types = PieceType.values;
  final cells = _simulate(balance, pilot, duels, limitMs);
  final space = balance.id == WorldBalance.space.id
      ? cells
      : _simulate(WorldBalance.space, pilot, duels, limitMs);

  String pct(double v) => '${(v * 100).round()}%'.padLeft(4);
  String style(PieceType t) =>
      balance.statsOf(t).isMelee ? '${t.name}*' : t.name;

  stdout.writeln('world ${balance.id} '
      '(contact damage ×${balance.arena.contactDamageScale}), '
      '${pilot.difficulty.name} vs '
      '${pilot.difficulty.name}, $duels duels per pairing, '
      'limit ${limitMs ~/ 1000} s; * = melee');
  stdout.writeln();
  stdout.writeln('| attacker \\ defender | '
      '${types.map(style).join(' | ')} |');
  stdout.writeln('|---|${types.map((_) => '---').join('|')}|');
  for (final a in types) {
    final row = [
      for (final d in types)
        () {
          final c = cells[(a, d)]!;
          return '${pct(c.winShare)} (${pct(c.odds).trim()}) '
              '${c.medianS.toStringAsFixed(1)} s'
              '${c.capShare > 0 ? ' cap ${pct(c.capShare).trim()}' : ''}'
              '${c.drawShare > 0 || c.drawOdds >= 0.01 ? ' draw ${pct(c.drawShare).trim()} (${pct(c.drawOdds).trim()})' : ''}';
        }(),
    ];
    stdout.writeln('| ${style(a)} | ${row.join(' | ')} |');
  }
  stdout.writeln();
  stdout.writeln('cell: simulated attacker win share (BattleOdds estimate), '
      'median length, share at the time limit, share destroyed together '
      '(both pieces leave the board; counted as half a win) with the '
      'BattleOdds estimate');
  stdout.writeln();

  // Acceptance bounds of plan 12, step 1B.
  final mirror = [for (final t in types) cells[(t, t)]!.winShare];
  final mixed = [
    for (final (m, r) in _sameWeight)
      if (balance.statsOf(m).isMelee != balance.statsOf(r).isMelee) ...[
        cells[(m, r)]!.winShare,
        cells[(r, m)]!.winShare,
      ],
  ];
  // A queen shoots a pawn down in seconds; the length bound is for even
  // fights.
  final medians = [for (final t in types) cells[(t, t)]!.medianS];
  final caps = cells.values.map((c) => c.capShare).reduce((a, b) => a + b) /
      cells.length;
  final oddsGaps = [
    for (final c in cells.values) (c.winShare - c.odds).abs(),
  ];
  final badOdds = oddsGaps.where((g) => g > 0.15).length;

  // Melee must not tilt a pairing against today's space arena.
  // Shifts are from the melee unit's view: its win share here minus the
  // same pairing's in space.
  final shifts = [
    for (final a in types)
      for (final d in types)
        if (balance.statsOf(a).isMelee != balance.statsOf(d).isMelee)
          (
            a,
            d,
            (cells[(a, d)]!.winShare - space[(a, d)]!.winShare) *
                (balance.statsOf(a).isMelee ? 1 : -1),
          ),
  ];

  void check(String name, bool ok, String detail) =>
      stdout.writeln('- ${ok ? 'OK  ' : 'FAIL'} $name: $detail');

  check(
      'mirror pairings 45–55 %',
      mirror.every((v) => v >= 0.45 && v <= 0.55),
      mirror.map(pct).join(', '));
  if (mixed.isNotEmpty) {
    check(
        'melee vs ranged of the same weight 35–65 %',
        mixed.every((v) => v >= 0.35 && v <= 0.65),
        mixed.map(pct).join(', '));
  }
  check(
      'mirror medians 8–25 s',
      medians.every((m) => m >= 8 && m <= 25),
      'from ${medians.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} '
          'to ${medians.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} s');
  if (shifts.isNotEmpty) {
    final worst = shifts.reduce((x, y) => x.$3.abs() >= y.$3.abs() ? x : y);
    final mean =
        shifts.map((x) => x.$3).reduce((x, y) => x + y) / shifts.length;
    check(
        'melee vs ranged within 10 points of space',
        worst.$3.abs() <= 0.10,
        'melee side ${(mean * 100).round()} points on average, worst '
            '${worst.$1.name}→${worst.$2.name} '
            '${(worst.$3 * 100).round()} points');
  }
  check('at the limit at most 2 %', caps <= 0.02, pct(caps).trim());
  final draws = cells.values.map((c) => c.drawShare).reduce((a, b) => a + b) /
      cells.length;
  final mirrorDraws = [for (final t in types) cells[(t, t)]!.drawShare];
  stdout.writeln('- mutual destruction: ${pct(draws).trim()} of all duels, '
      'mirrors ${mirrorDraws.map((v) => pct(v).trim()).join(', ')}');
  check(
      '|BattleOdds − simulation| ≤ 0.15',
      badOdds == 0,
      '$badOdds of ${cells.length} pairings over, largest gap '
          '${oddsGaps.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}');
}

Map<(PieceType, PieceType), _Cell> _simulate(
  WorldBalance balance,
  AiProfile pilot,
  int duels,
  int limitMs,
) {
  const types = PieceType.values;
  final cells = <(PieceType, PieceType), _Cell>{};
  for (final a in types) {
    for (final d in types) {
      var wins = 0;
      var capped = 0;
      var draws = 0;
      final lengths = <int>[];
      for (var i = 0; i < duels; i++) {
        final seed = (a.index * 6 + d.index) * 100003 + i;
        final s = Duel.fight(a, d,
            attackerPilot: pilot,
            defenderPilot: pilot,
            seed: seed,
            limitMs: limitMs,
            balance: balance,
            defenderDecidesFirst: i.isOdd);
        if (!s.isFinished) {
          capped++;
        } else if (s.isMutualDestruction) {
          draws++;
        } else if (s.winner == PlayerColor.white) {
          wins++;
        }
        lengths.add(s.elapsedMs);
      }
      lengths.sort();
      final finished = duels - capped;
      final odds = BattleOdds.outcomes(
        Piece(type: a, color: PlayerColor.white),
        Piece(type: d, color: PlayerColor.black),
        const UpgradeProfile(),
        const UpgradeProfile(),
        balance: balance,
      );
      cells[(a, d)] = _Cell(
        finished == 0 ? 0.5 : (wins + draws / 2) / finished,
        lengths[lengths.length ~/ 2] / 1000,
        capped / duels,
        draws / duels,
        odds.score,
        odds.draw,
      );
    }
    stderr.write('.');
  }
  stderr.writeln();
  return cells;
}

/// Pairings of about the same board value, one melee and one ranged in the
/// ground world.
const _sameWeight = [
  (PieceType.knight, PieceType.bishop),
  (PieceType.rook, PieceType.queen),
  (PieceType.king, PieceType.queen),
];
