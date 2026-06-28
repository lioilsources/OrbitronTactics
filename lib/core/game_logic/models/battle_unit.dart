import 'piece.dart';
import 'shield_state.dart';
import 'unit_stats.dart';

class BattleUnit {
  final Piece piece;
  final UnitStats stats;
  final int currentHp;
  final ShieldState shieldState;
  final int nextAttackMs;

  const BattleUnit({
    required this.piece,
    required this.stats,
    required this.currentHp,
    required this.shieldState,
    this.nextAttackMs = 0,
  });

  double get hpFraction => currentHp / stats.maxHp;
  bool get isAlive => currentHp > 0;

  BattleUnit copyWith({
    Piece? piece,
    UnitStats? stats,
    int? currentHp,
    ShieldState? shieldState,
    int? nextAttackMs,
  }) {
    return BattleUnit(
      piece: piece ?? this.piece,
      stats: stats ?? this.stats,
      currentHp: currentHp ?? this.currentHp,
      shieldState: shieldState ?? this.shieldState,
      nextAttackMs: nextAttackMs ?? this.nextAttackMs,
    );
  }
}
