//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum SettlementMethod {
  PER_VIEW._(r'PER_VIEW'),
  FIXED._(r'FIXED'),
  NONE._(r'NONE'),
  FIXED_AND_PER_VIEW._(r'FIXED_AND_PER_VIEW'),
  ;

  /// Instantiate a new enum with the provided value.
  const SettlementMethod._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SettlementMethod] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SettlementMethod? fromJson(dynamic value) =>
      SettlementMethodTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SettlementMethod]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SettlementMethod> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SettlementMethod>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettlementMethod.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SettlementMethod] to String,
/// and [decode] dynamic data back to [SettlementMethod].
class SettlementMethodTypeTransformer {
  factory SettlementMethodTypeTransformer() =>
      _instance ??= const SettlementMethodTypeTransformer._();

  const SettlementMethodTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SettlementMethod data) => data._value;

  /// Returns the instance of [SettlementMethod] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SettlementMethod? decode(dynamic data, {bool allowNull = true}) {
    if (data is SettlementMethod) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PER_VIEW':
          return SettlementMethod.PER_VIEW;
        case r'FIXED':
          return SettlementMethod.FIXED;
        case r'NONE':
          return SettlementMethod.NONE;
        case r'FIXED_AND_PER_VIEW':
          return SettlementMethod.FIXED_AND_PER_VIEW;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SettlementMethodTypeTransformer? _instance;
}
