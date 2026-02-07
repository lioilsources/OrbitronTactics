import 'package:freezed_annotation/freezed_annotation.dart';
import 'formation.dart';
import 'piece.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required String userId,
    required String displayName,
    required PlayerColor color,
    Formation? formation,
    @Default(false) bool formationLocked,
    @Default(true) bool hasKing,
    @Default(true) bool hasQueen,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);
}
