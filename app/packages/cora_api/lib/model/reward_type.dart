//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum RewardType {
  VOUCHER._(r'VOUCHER'),
  PER_VIEW._(r'PER_VIEW'),
  BOTH._(r'BOTH'),
  ;

  /// Instantiate a new enum with the provided value.
  const RewardType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RewardType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RewardType? fromJson(dynamic value) =>
      RewardTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RewardType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RewardType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RewardType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RewardType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RewardType] to String,
/// and [decode] dynamic data back to [RewardType].
class RewardTypeTypeTransformer {
  factory RewardTypeTypeTransformer() =>
      _instance ??= const RewardTypeTypeTransformer._();

  const RewardTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RewardType data) => data._value;

  /// Returns the instance of [RewardType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RewardType? decode(dynamic data, {bool allowNull = true}) {
    if (data is RewardType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'VOUCHER':
          return RewardType.VOUCHER;
        case r'PER_VIEW':
          return RewardType.PER_VIEW;
        case r'BOTH':
          return RewardType.BOTH;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RewardTypeTypeTransformer? _instance;
}
