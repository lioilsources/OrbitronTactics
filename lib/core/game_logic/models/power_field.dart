import 'package:freezed_annotation/freezed_annotation.dart';
import 'position.dart';

part 'power_field.freezed.dart';
part 'power_field.g.dart';

@freezed
class PowerField with _$PowerField {
  const factory PowerField({
    required Position position,
  }) = _PowerField;

  factory PowerField.fromJson(Map<String, dynamic> json) =>
      _$PowerFieldFromJson(json);
}
