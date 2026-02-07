import 'package:freezed_annotation/freezed_annotation.dart';
import 'piece.dart';
import 'position.dart';

part 'formation.freezed.dart';
part 'formation.g.dart';

@freezed
class Formation with _$Formation {
  const factory Formation({
    /// Map from position (within player's first 2 rows) to piece.
    /// White uses rows 0-1, black uses rows 6-7.
    required List<FormationPlacement> placements,
  }) = _Formation;

  factory Formation.fromJson(Map<String, dynamic> json) =>
      _$FormationFromJson(json);
}

@freezed
class FormationPlacement with _$FormationPlacement {
  const factory FormationPlacement({
    required Position position,
    required Piece piece,
  }) = _FormationPlacement;

  factory FormationPlacement.fromJson(Map<String, dynamic> json) =>
      _$FormationPlacementFromJson(json);
}
