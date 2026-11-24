import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/duel.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/upgrade_profile.dart';

/// Seeded duels in the space balance, recorded on `main` before melee
/// combat came in (with sudden death). Any change to the arena that should
/// leave space as it was must reproduce them exactly.
void main() {
  test('space duels replay exactly as recorded', () {
    final results = <String>[];
    for (final a in PieceType.values) {
      for (final d in PieceType.values) {
        final s = Duel.fight(a, d,
            attackerPilot: AiProfile.medium,
            defenderPilot: AiProfile.medium,
            seed: a.index * 6 + d.index,
            limitMs: 60000);
        results.add('${a.name}-${d.name}:${s.winner?.name ?? '-'}:'
            '${s.elapsedMs}:${s.attacker.currentHp}:${s.defender.currentHp}');
      }
    }
    expect(results, _expected);
  });

  // Every duel above ends before sudden death at 45 s; these upgraded Hard
  // duels run into it, so its timing and ramp are pinned too.
  test('space duels through sudden death replay exactly as recorded', () {
    const upgrades = UpgradeProfile(levels: {
      PieceType.king: 5,
      PieceType.queen: 5,
      PieceType.rook: 5,
    });
    final results = <String>[];
    for (final (a, d) in const [
      (PieceType.king, PieceType.king),
      (PieceType.king, PieceType.queen),
      (PieceType.rook, PieceType.king),
    ]) {
      for (var seed = 0; seed < 3; seed++) {
        for (final defenderFirst in const [false, true]) {
          final s = Duel.fight(a, d,
              attackerPilot: AiProfile.hard,
              defenderPilot: AiProfile.hard,
              attackerUpgrades: upgrades,
              defenderUpgrades: upgrades,
              seed: seed,
              defenderDecidesFirst: defenderFirst,
              limitMs: 120000);
          results.add('${a.name}-${d.name}/$seed/${defenderFirst ? 'd' : 'a'}:'
              '${s.winner?.name ?? '-'}:${s.elapsedMs}:'
              '${s.attacker.currentHp}:${s.defender.currentHp}');
        }
      }
    }
    expect(results, _expectedSuddenDeath);
  });
}

const _expected = <String>[
  // Both pawns fall in one tick: mutual destruction (plan 14, decision 10)
  // has no winner. It was the attacker's before; time and HP are unchanged.
  'pawn-pawn:-:7104:0:0',
  'pawn-rook:black:7264:0:94',
  'pawn-knight:black:7712:0:10',
  'pawn-bishop:black:3840:0:54',
  'pawn-queen:black:3696:0:144',
  'pawn-king:black:7792:0:150',
  'rook-pawn:white:11024:48:0',
  'rook-rook:black:19728:0:76',
  'rook-knight:white:9120:60:0',
  'rook-bishop:white:7056:6:0',
  'rook-queen:black:20288:0:54',
  'rook-king:black:28528:0:20',
  'knight-pawn:white:8128:14:0',
  'knight-rook:black:17280:0:60',
  'knight-knight:black:13152:0:26',
  'knight-bishop:black:5648:0:32',
  'knight-queen:black:15504:0:70',
  'knight-king:black:9776:0:115',
  'bishop-pawn:white:4336:46:0',
  'bishop-rook:black:15088:0:25',
  'bishop-knight:black:5296:0:58',
  'bishop-bishop:black:4016:0:22',
  'bishop-queen:black:6176:0:90',
  'bishop-king:black:8848:0:100',
  'queen-pawn:white:1696:150:0',
  'queen-rook:white:11008:49:0',
  'queen-knight:white:11904:86:0',
  'queen-bishop:white:7584:70:0',
  'queen-queen:white:10016:86:0',
  'queen-king:black:22976:0:50',
  'king-pawn:white:5568:155:0',
  'king-rook:white:14672:104:0',
  'king-knight:white:26256:24:0',
  'king-bishop:black:17936:0:4',
  'king-queen:black:21952:0:10',
  'king-king:white:44320:65:0',
];

const _expectedSuddenDeath = <String>[
  'king-king/0/a:black:66032:0:72',
  'king-king/0/d:white:70224:72:0',
  'king-king/1/a:white:62048:180:0',
  'king-king/1/d:white:62816:144:0',
  'king-king/2/a:black:58848:0:252',
  'king-king/2/d:white:60176:36:0',
  'king-queen/0/a:black:58016:0:150',
  'king-queen/0/d:black:53440:0:150',
  'king-queen/1/a:black:59280:0:195',
  'king-queen/1/d:black:52320:0:195',
  'king-queen/2/a:black:53280:0:150',
  'king-queen/2/d:black:57248:0:150',
  'rook-king/0/a:black:51056:0:219',
  'rook-king/0/d:black:58144:0:112',
  'rook-king/1/a:black:72480:0:70',
  'rook-king/1/d:black:66832:0:48',
  'rook-king/2/a:black:52896:0:181',
  'rook-king/2/d:black:58096:0:119',
];
