import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/ai/ai_difficulty.dart';
import 'package:orbitron_tactics/core/ai/duel.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';

/// Seeded Medium vs Medium duels for every pairing of the space balance,
/// recorded before melee combat came in. Any change to the arena that should
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
}

const _expected = <String>[
  'pawn-pawn:white:7104:0:0',
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
