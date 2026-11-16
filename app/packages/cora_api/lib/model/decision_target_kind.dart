//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 브랜드는 CREATOR만, 크리에이터는 CAMPAIGN만 보낸다.
enum DecisionTargetKind {
  CREATOR._(r'CREATOR'),
  CAMPAIGN._(r'CAMPAIGN'),
  ;

  /// Instantiate a new enum with the provided value.
  const DecisionTargetKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DecisionTargetKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DecisionTargetKind? fromJson(dynamic value) =>
      DecisionTargetKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DecisionTargetKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DecisionTargetKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DecisionTargetKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DecisionTargetKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DecisionTargetKind] to String,
/// and [decode] dynamic data back to [DecisionTargetKind].
class DecisionTargetKindTypeTransformer {
  factory DecisionTargetKindTypeTransformer() =>
      _instance ??= const DecisionTargetKindTypeTransformer._();

  const DecisionTargetKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DecisionTargetKind data) => data._value;

  /// Returns the instance of [DecisionTargetKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DecisionTargetKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is DecisionTargetKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CREATOR':
          return DecisionTargetKind.CREATOR;
        case r'CAMPAIGN':
          return DecisionTargetKind.CAMPAIGN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DecisionTargetKindTypeTransformer? _instance;
}
