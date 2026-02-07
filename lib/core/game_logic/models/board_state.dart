import 'package:freezed_annotation/freezed_annotation.dart';
import 'piece.dart';
import 'position.dart';
import 'power_field.dart';

part 'board_state.freezed.dart';
part 'board_state.g.dart';

@freezed
class BoardState with _$BoardState {
  const BoardState._();

  const factory BoardState({
    /// 8x8 grid indexed as grid[row][col]. Null = empty square.
    required List<List<Piece?>> grid,
    required List<PowerField> powerFields,
  }) = _BoardState;

  factory BoardState.fromJson(Map<String, dynamic> json) =>
      _$BoardStateFromJson(json);

  factory BoardState.empty(List<PowerField> powerFields) => BoardState(
        grid: List.generate(8, (_) => List.generate(8, (_) => null)),
        powerFields: powerFields,
      );

  Piece? pieceAt(Position pos) => grid[pos.row][pos.col];

  bool isEmpty(Position pos) => pieceAt(pos) == null;

  bool isEnemy(Position pos, PlayerColor color) {
    final piece = pieceAt(pos);
    return piece != null && piece.color != color;
  }

  bool isFriendly(Position pos, PlayerColor color) {
    final piece = pieceAt(pos);
    return piece != null && piece.color == color;
  }

  /// Returns a new BoardState with a piece moved from [from] to [to].
  BoardState movePiece(Position from, Position to) {
    final newGrid = [
      for (int r = 0; r < 8; r++) [...grid[r]],
    ];
    final piece = newGrid[from.row][from.col];
    newGrid[from.row][from.col] = null;
    newGrid[to.row][to.col] = piece;
    return copyWith(grid: newGrid);
  }

  /// Returns a new BoardState with the piece at [pos] replaced.
  BoardState setPiece(Position pos, Piece? piece) {
    final newGrid = [
      for (int r = 0; r < 8; r++) [...grid[r]],
    ];
    newGrid[pos.row][pos.col] = piece;
    return copyWith(grid: newGrid);
  }

  /// Find all positions of pieces matching the given criteria.
  List<Position> findPieces({
    PieceType? type,
    PlayerColor? color,
    bool? isLastWarrior,
  }) {
    final results = <Position>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = grid[r][c];
        if (piece == null) continue;
        if (type != null && piece.type != type) continue;
        if (color != null && piece.color != color) continue;
        if (isLastWarrior != null && piece.isLastWarrior != isLastWarrior) {
          continue;
        }
        results.add(Position(row: r, col: c));
      }
    }
    return results;
  }

  /// Check if a player controls a power field (has their piece on it).
  bool controlsPowerField(PowerField pf, PlayerColor color) {
    final piece = pieceAt(pf.position);
    return piece != null && piece.color == color;
  }

  /// Count how many power fields a player controls.
  int powerFieldCount(PlayerColor color) {
    return powerFields.where((pf) => controlsPowerField(pf, color)).length;
  }
}
