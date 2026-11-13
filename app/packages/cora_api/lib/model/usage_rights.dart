//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum UsageRights {
  STORE_REPOST_3M._(r'STORE_REPOST_3M'),
  STORE_REPOST_6M._(r'STORE_REPOST_6M'),
  NONE._(r'NONE'),
  ;

  /// Instantiate a new enum with the provided value.
  const UsageRights._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [UsageRights] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static UsageRights? fromJson(dynamic value) =>
      UsageRightsTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [UsageRights]
  /// that were successfully decoded from the passed [JSON][json].
  static List<UsageRights> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UsageRights>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsageRights.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UsageRights] to String,
/// and [decode] dynamic data back to [UsageRights].
class UsageRightsTypeTransformer {
  factory UsageRightsTypeTransformer() =>
      _instance ??= const UsageRightsTypeTransformer._();

  const UsageRightsTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(UsageRights data) => data._value;

  /// Returns the instance of [UsageRights] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UsageRights? decode(dynamic data, {bool allowNull = true}) {
    if (data is UsageRights) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'STORE_REPOST_3M':
          return UsageRights.STORE_REPOST_3M;
        case r'STORE_REPOST_6M':
          return UsageRights.STORE_REPOST_6M;
        case r'NONE':
          return UsageRights.NONE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static UsageRightsTypeTransformer? _instance;
}
