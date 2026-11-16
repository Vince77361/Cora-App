//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum BrandUsageRights {
  REPOST_ONLY._(r'REPOST_ONLY'),
  ADS_TOO._(r'ADS_TOO'),
  NONE._(r'NONE'),
  ;

  /// Instantiate a new enum with the provided value.
  const BrandUsageRights._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [BrandUsageRights] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static BrandUsageRights? fromJson(dynamic value) =>
      BrandUsageRightsTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [BrandUsageRights]
  /// that were successfully decoded from the passed [JSON][json].
  static List<BrandUsageRights> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandUsageRights>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandUsageRights.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BrandUsageRights] to String,
/// and [decode] dynamic data back to [BrandUsageRights].
class BrandUsageRightsTypeTransformer {
  factory BrandUsageRightsTypeTransformer() =>
      _instance ??= const BrandUsageRightsTypeTransformer._();

  const BrandUsageRightsTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(BrandUsageRights data) => data._value;

  /// Returns the instance of [BrandUsageRights] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BrandUsageRights? decode(dynamic data, {bool allowNull = true}) {
    if (data is BrandUsageRights) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'REPOST_ONLY':
          return BrandUsageRights.REPOST_ONLY;
        case r'ADS_TOO':
          return BrandUsageRights.ADS_TOO;
        case r'NONE':
          return BrandUsageRights.NONE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static BrandUsageRightsTypeTransformer? _instance;
}
