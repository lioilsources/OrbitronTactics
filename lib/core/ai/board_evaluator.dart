import 'dart:math';

import '../game_logic/engine/unit_base_stats.dart';
import '../game_logic/engine/upgrade_engine.dart';
import '../game_logic/models/game_state.dart';
import '../game_logic/models/move.dart';
import '../game_logic/models/piece.dart';
import '../game_logic/models/position.dart';
import '../game_logic/models/upgrade_profile.dart';
import 'battle_odds.dart';
import 'move_generator.dart';

/// Weights of the terms of [BoardEvaluator.evaluate].
class EvalWeights {
  final double material;
  final double powerField;
  final double powerFieldReach;
  final double infiltration;
  final double threat;
  final double mobility;
  final double royal;

  const EvalWeights({
    required this.material,
    required this.powerField,
    required this.powerFieldReach,
    required this.infiltration,
    required this.threat,
    required this.mobility,
    required this.royal,
  });

  static const standard = EvalWeights(
    material: 1.0,
    powerField: 30,
    powerFieldReach: 8,
    infiltration: 3,
    threat: 0.8,
    mobility: 0.5,
    royal: 1.0,
  );

  EvalWeights copyWith({
    double? material,
    double? powerField,
    double? powerFieldReach,
    double? infiltration,
    double? threat,
    double? mobility,
    double? royal,
  }) {
    return EvalWeights(
      material: material ?? this.material,
      powerField: powerField ?? this.powerField,
      powerFieldReach: powerFieldReach ?? this.powerFieldReach,
      infiltration: infiltration ?? this.infiltration,
      threat: threat ?? this.threat,
      mobility: mobility ?? this.mobility,
      royal: royal ?? this.royal,
    );
  }
}

/// Static evaluation of a position, in points; positive favours `pov`.
///
/// Every term is computed the same way for both sides and subtracted, so a
/// position scores exactly the negation for the other side.
class BoardEvaluator {
  const BoardEvaluator._();

  /// Score of a won game; a lost game scores −[win].
  static const double win = 1e6;

  /// Brings combat strength into the range of the positional terms — a
  /// pawn is worth about 90 points, a power field 30.
  static const double materialScale = 100;

  static const double _missingRoyalPenalty = 150;
  static const double _unstoppablePawnBonus = 200;

  static final Map<int, List<double>> _valueTables = {};

  /// [povMoves] and [oppMoves] may pass in [MoveGenerator.generate]'s
  /// result for either side when the caller already has it.
  static double evaluate(
    GameState s,
    PlayerColor pov, {
    EvalWeights w = EvalWeights.standard,
    UpgradeProfile? povUpgrades,
    UpgradeProfile? oppUpgrades,
    List<Move>? povMoves,
    List<Move>? oppMoves,
  }) {
    if (s.isFinished) {
      if (s.winner == null) return 0;
      return s.winner == pov ? win : -win;
    }

    final opp = pov.opposite;
    final myUpgrades = povUpgrades ?? const UpgradeProfile();
    final theirUpgrades = oppUpgrades ?? const UpgradeProfile();
    final myMoves = povMoves ?? MoveGenerator.generate(s, pov);
    final theirMoves = oppMoves ?? MoveGenerator.generate(s, opp);

    return _side(s, pov, w, myUpgrades, theirUpgrades, myMoves, theirMoves) -
        _side(s, opp, w, theirUpgrades, myUpgrades, theirMoves, myMoves);
  }

  /// Combat strength × role: `sqrt(hp · dmg / interval / (1 − defense))`,
  /// scaled by [materialScale].
  static double pieceValue(Piece p, UpgradeProfile up) =>
      _valuesFor(up)[_valueIndex(p)];

  /// Weighted score of [color]'s own terms (the penalties included).
  static double _side(
    GameState s,
    PlayerColor color,
    EvalWeights w,
    UpgradeProfile upgrades,
    UpgradeProfile enemyUpgrades,
    List<Move> moves,
    List<Move> enemyMoves,
  ) {
    final board = s.board;
    final values = _valuesFor(upgrades);
    final targets = _targetMask(moves);
    final enemyTargets = _targetMask(enemyMoves);

    // Material, royals, infiltration
    var material = 0.0;
    var infiltration = 0.0;
    var hasKing = false;
    var hasQueen = false;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board.grid[row][col];
        if (piece == null || piece.color != color) continue;
        material += values[_valueIndex(piece)];
        switch (piece.type) {
          case PieceType.king:
            hasKing = true;
          case PieceType.queen:
            hasQueen = true;
          case PieceType.pawn:
            final distance = (color.infiltrationRank - row).abs();
            infiltration += ((7 - distance) * (7 - distance)).toDouble();
            if (distance == 1 && enemyTargets & _bit(row, col) == 0) {
              infiltration += _unstoppablePawnBonus;
            }
          default:
            break;
        }
      }
    }
    // Board presence, not Player.hasKing/hasQueen: a royal that attacked and
    // lost its battle leaves the board without clearing the flag.
    final royal = -_missingRoyalPenalty *
        ((hasKing ? 0 : 1) + (hasQueen ? 0 : 1));

    // Power fields held (doubled one field short of domination) and in reach
    var held = 0;
    var inReach = 0;
    for (final field in board.powerFields) {
      final position = field.position;
      if (board.pieceAt(position)?.color == color) {
        held++;
      } else if (targets & _bit(position.row, position.col) != 0) {
        inReach++;
      }
    }
    final fieldCount = board.powerFields.length;
    final fieldScore =
        fieldCount > 1 && held >= fieldCount - 1 ? 2 * held : held;

    // Pieces the enemy can attack, at the best attacker's odds
    var threat = 0.0;
    if (w.threat != 0) {
      final odds = BattleOdds.table(enemyUpgrades, upgrades);
      final worstOdds = <Position, double>{};
      for (final move in enemyMoves) {
        final target = move.capturedPiece;
        if (target == null) continue;
        final p = odds.of(move.piece.type, target.type);
        if (p > (worstOdds[move.to] ?? 0)) worstOdds[move.to] = p;
      }
      worstOdds.forEach((position, p) {
        threat -= p * values[_valueIndex(board.pieceAt(position)!)];
      });
    }

    return w.material * material +
        w.royal * royal +
        w.powerField * fieldScore +
        w.powerFieldReach * inReach +
        w.infiltration * infiltration +
        w.threat * threat +
        w.mobility * moves.length;
  }

  static int _valueIndex(Piece p) =>
      p.type.index * 2 + (p.isLastWarrior ? 1 : 0);

  static int _bit(int row, int col) => 1 << (row * 8 + col);

  static int _targetMask(List<Move> moves) {
    var mask = 0;
    for (final move in moves) {
      mask |= _bit(move.to.row, move.to.col);
    }
    return mask;
  }

  static List<double> _valuesFor(UpgradeProfile up) {
    return _valueTables[_levelsKey(up)] ??= [
      for (final type in PieceType.values) ...[
        _computeValue(type, up, lastWarrior: false),
        _computeValue(type, up, lastWarrior: true),
      ],
    ];
  }

  static double _computeValue(
    PieceType type,
    UpgradeProfile up, {
    required bool lastWarrior,
  }) {
    final stats = UpgradeEngine.statsFor(type, up, unitBaseStats);
    final strength = sqrt(stats.maxHp *
        stats.damage /
        stats.attackIntervalMs /
        (1 - stats.defenseRating));
    final role = lastWarrior
        ? 0.6
        : switch (type) {
            PieceType.pawn || PieceType.knight || PieceType.bishop => 1.0,
            PieceType.rook => 1.1,
            PieceType.queen => 1.6,
            PieceType.king => 1.8,
          };
    return strength * role * materialScale;
  }

  /// Cache key of an upgrade profile: one base-4 digit per piece type.
  static int _levelsKey(UpgradeProfile up) {
    var key = 0;
    for (final type in PieceType.values) {
      key = key * 4 + up.levelFor(type).clamp(0, 3);
    }
    return key;
  }
}
