import 'package:freezed_annotation/freezed_annotation.dart';

part 'piece.freezed.dart';
part 'piece.g.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }

enum PlayerColor { white, black }

extension PlayerColorX on PlayerColor {
  PlayerColor get opposite =>
      this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;

  // Forward is toward higher rows for white, lower for black; the ranks
  // depend on the board: see BoardGeometry.backRank and infiltrationRank.
}

@freezed
class Piece with _$Piece {
  const Piece._();

  const factory Piece({
    required PieceType type,
    required PlayerColor color,
    @Default(false) bool isLastWarrior,
  }) = _Piece;

  factory Piece.fromJson(Map<String, dynamic> json) => _$PieceFromJson(json);

  bool get isRoyal => type == PieceType.king || type == PieceType.queen;
}
