//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum FeeBand {
  W200K._(r'W200K'),
  W300K._(r'W300K'),
  W400K._(r'W400K'),
  W500K_PLUS._(r'W500K_PLUS'),
  ;

  /// Instantiate a new enum with the provided value.
  const FeeBand._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [FeeBand] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static FeeBand? fromJson(dynamic value) =>
      FeeBandTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [FeeBand]
  /// that were successfully decoded from the passed [JSON][json].
  static List<FeeBand> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeeBand>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeeBand.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FeeBand] to String,
/// and [decode] dynamic data back to [FeeBand].
class FeeBandTypeTransformer {
  factory FeeBandTypeTransformer() =>
      _instance ??= const FeeBandTypeTransformer._();

  const FeeBandTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(FeeBand data) => data._value;

  /// Returns the instance of [FeeBand] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FeeBand? decode(dynamic data, {bool allowNull = true}) {
    if (data is FeeBand) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'W200K':
          return FeeBand.W200K;
        case r'W300K':
          return FeeBand.W300K;
        case r'W400K':
          return FeeBand.W400K;
        case r'W500K_PLUS':
          return FeeBand.W500K_PLUS;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static FeeBandTypeTransformer? _instance;
}
