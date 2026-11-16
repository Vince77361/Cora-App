//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다.
enum MatchReason {
  FIELD._(r'FIELD'),
  FACE._(r'FACE'),
  SCRIPT._(r'SCRIPT'),
  FEE._(r'FEE'),
  TRIAL._(r'TRIAL'),
  ;

  /// Instantiate a new enum with the provided value.
  const MatchReason._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MatchReason] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MatchReason? fromJson(dynamic value) =>
      MatchReasonTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MatchReason]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MatchReason> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MatchReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MatchReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MatchReason] to String,
/// and [decode] dynamic data back to [MatchReason].
class MatchReasonTypeTransformer {
  factory MatchReasonTypeTransformer() =>
      _instance ??= const MatchReasonTypeTransformer._();

  const MatchReasonTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MatchReason data) => data._value;

  /// Returns the instance of [MatchReason] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MatchReason? decode(dynamic data, {bool allowNull = true}) {
    if (data is MatchReason) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'FIELD':
          return MatchReason.FIELD;
        case r'FACE':
          return MatchReason.FACE;
        case r'SCRIPT':
          return MatchReason.SCRIPT;
        case r'FEE':
          return MatchReason.FEE;
        case r'TRIAL':
          return MatchReason.TRIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MatchReasonTypeTransformer? _instance;
}
