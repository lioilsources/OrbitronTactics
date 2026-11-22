import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.freezed.dart';
part 'position.g.dart';

@freezed
class Position with _$Position {
  const Position._();

  const factory Position({
    required int row, // 0 = Player 1 (white) back rank
    required int col, // 0 = left from Player 1's perspective
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  Position offset(int dRow, int dCol) => Position(row: row + dRow, col: col + dCol);

  // Whether a position is on the board and its mirror image depend on the
  // board: see BoardGeometry.contains and BoardGeometry.mirror.

  int distanceTo(Position other) =>
      (row - other.row).abs() + (col - other.col).abs();
}
