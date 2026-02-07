import 'package:freezed_annotation/freezed_annotation.dart';
import 'piece.dart';
import 'position.dart';

part 'move.freezed.dart';
part 'move.g.dart';

@freezed
class Move with _$Move {
  const factory Move({
    required Position from,
    required Position to,
    required Piece piece,
    Piece? capturedPiece,
    @Default(false) bool isSnipe,
  }) = _Move;

  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
}
