//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum PassReason {
  MOOD._(r'MOOD'),
  REGION._(r'REGION'),
  FEE._(r'FEE'),
  FIELD._(r'FIELD'),
  ;

  /// Instantiate a new enum with the provided value.
  const PassReason._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PassReason] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PassReason? fromJson(dynamic value) =>
      PassReasonTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PassReason]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PassReason> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PassReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PassReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PassReason] to String,
/// and [decode] dynamic data back to [PassReason].
class PassReasonTypeTransformer {
  factory PassReasonTypeTransformer() =>
      _instance ??= const PassReasonTypeTransformer._();

  const PassReasonTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(PassReason data) => data._value;

  /// Returns the instance of [PassReason] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PassReason? decode(dynamic data, {bool allowNull = true}) {
    if (data is PassReason) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'MOOD':
          return PassReason.MOOD;
        case r'REGION':
          return PassReason.REGION;
        case r'FEE':
          return PassReason.FEE;
        case r'FIELD':
          return PassReason.FIELD;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PassReasonTypeTransformer? _instance;
}
