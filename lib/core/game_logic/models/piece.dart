import 'package:freezed_annotation/freezed_annotation.dart';

part 'piece.freezed.dart';
part 'piece.g.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }

enum PlayerColor { white, black }

extension PlayerColorX on PlayerColor {
  PlayerColor get opposite =>
      this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;

  /// Forward direction: white moves toward higher rows, black toward lower.
  int get forwardDir => this == PlayerColor.white ? 1 : -1;

  /// The back rank row for this player (where they start).
  int get backRank => this == PlayerColor.white ? 0 : 7;

  /// The opponent's back rank (infiltration target).
  int get infiltrationRank => this == PlayerColor.white ? 7 : 0;
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
