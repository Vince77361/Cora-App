//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 \"이번에는 함께하기 어렵대요.\"만 본다).
enum DropReasonChoice {
  SCHEDULE._(r'SCHEDULE'),
  BUDGET._(r'BUDGET'),
  DIRECTION._(r'DIRECTION'),
  OTHER._(r'OTHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const DropReasonChoice._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DropReasonChoice] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DropReasonChoice? fromJson(dynamic value) =>
      DropReasonChoiceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DropReasonChoice]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DropReasonChoice> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DropReasonChoice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DropReasonChoice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DropReasonChoice] to String,
/// and [decode] dynamic data back to [DropReasonChoice].
class DropReasonChoiceTypeTransformer {
  factory DropReasonChoiceTypeTransformer() =>
      _instance ??= const DropReasonChoiceTypeTransformer._();

  const DropReasonChoiceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DropReasonChoice data) => data._value;

  /// Returns the instance of [DropReasonChoice] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DropReasonChoice? decode(dynamic data, {bool allowNull = true}) {
    if (data is DropReasonChoice) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SCHEDULE':
          return DropReasonChoice.SCHEDULE;
        case r'BUDGET':
          return DropReasonChoice.BUDGET;
        case r'DIRECTION':
          return DropReasonChoice.DIRECTION;
        case r'OTHER':
          return DropReasonChoice.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DropReasonChoiceTypeTransformer? _instance;
}
