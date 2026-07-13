import 'piece.dart';
import 'shield_state.dart';
import 'unit_stats.dart';

class BattleUnit {
  final Piece piece;
  final UnitStats stats;
  final int currentHp;
  final ShieldState shieldState;
  final int nextAttackMs;

  /// Horizontal ship position across the arena, 0.0 (left) to 1.0 (right).
  final double xFraction;

  const BattleUnit({
    required this.piece,
    required this.stats,
    required this.currentHp,
    required this.shieldState,
    this.nextAttackMs = 0,
    this.xFraction = 0.5,
  });

  double get hpFraction => currentHp / stats.maxHp;
  bool get isAlive => currentHp > 0;

  BattleUnit copyWith({
    Piece? piece,
    UnitStats? stats,
    int? currentHp,
    ShieldState? shieldState,
    int? nextAttackMs,
    double? xFraction,
  }) {
    return BattleUnit(
      piece: piece ?? this.piece,
      stats: stats ?? this.stats,
      currentHp: currentHp ?? this.currentHp,
      shieldState: shieldState ?? this.shieldState,
      nextAttackMs: nextAttackMs ?? this.nextAttackMs,
      xFraction: xFraction ?? this.xFraction,
    );
  }
}
