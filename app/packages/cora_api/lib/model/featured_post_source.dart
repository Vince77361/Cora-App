//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum FeaturedPostSource {
  INSTAGRAM._(r'INSTAGRAM'),
  GALLERY._(r'GALLERY'),
  ;

  /// Instantiate a new enum with the provided value.
  const FeaturedPostSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [FeaturedPostSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static FeaturedPostSource? fromJson(dynamic value) =>
      FeaturedPostSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [FeaturedPostSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<FeaturedPostSource> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeaturedPostSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeaturedPostSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FeaturedPostSource] to String,
/// and [decode] dynamic data back to [FeaturedPostSource].
class FeaturedPostSourceTypeTransformer {
  factory FeaturedPostSourceTypeTransformer() =>
      _instance ??= const FeaturedPostSourceTypeTransformer._();

  const FeaturedPostSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(FeaturedPostSource data) => data._value;

  /// Returns the instance of [FeaturedPostSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FeaturedPostSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is FeaturedPostSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'INSTAGRAM':
          return FeaturedPostSource.INSTAGRAM;
        case r'GALLERY':
          return FeaturedPostSource.GALLERY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static FeaturedPostSourceTypeTransformer? _instance;
}
