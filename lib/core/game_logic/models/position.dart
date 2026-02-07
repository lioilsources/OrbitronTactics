import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.freezed.dart';
part 'position.g.dart';

@freezed
class Position with _$Position {
  const Position._();

  const factory Position({
    required int row, // 0-7, where 0 = Player 1 (white) back rank
    required int col, // 0-7, where 0 = left from Player 1's perspective
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  bool get isOnBoard => row >= 0 && row < 8 && col >= 0 && col < 8;

  Position offset(int dRow, int dCol) => Position(row: row + dRow, col: col + dCol);

  /// Point-symmetric mirror about the board center (3.5, 3.5).
  Position get mirrored => Position(row: 7 - row, col: 7 - col);

  int distanceTo(Position other) =>
      (row - other.row).abs() + (col - other.col).abs();
}
