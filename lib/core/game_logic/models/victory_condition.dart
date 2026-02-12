import 'package:freezed_annotation/freezed_annotation.dart';
import 'position.dart';

part 'victory_condition.freezed.dart';
part 'victory_condition.g.dart';

@freezed
sealed class VictoryCondition with _$VictoryCondition {
  const factory VictoryCondition.powerFieldDomination() =
      PowerFieldDomination;
  const factory VictoryCondition.royalElimination() = RoyalElimination;
  const factory VictoryCondition.infiltration({
    required Position pawnPosition,
  }) = Infiltration;
  const factory VictoryCondition.abandonment() = Abandonment;

  factory VictoryCondition.fromJson(Map<String, dynamic> json) =>
      _$VictoryConditionFromJson(json);
}
