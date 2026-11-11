//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum ContentFormat {
  SHORTS._(r'SHORTS'),
  REELS._(r'REELS'),
  CARD_NEWS._(r'CARD_NEWS'),
  BLOG._(r'BLOG'),
  ;

  /// Instantiate a new enum with the provided value.
  const ContentFormat._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ContentFormat] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ContentFormat? fromJson(dynamic value) =>
      ContentFormatTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ContentFormat]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ContentFormat> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentFormat>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentFormat.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContentFormat] to String,
/// and [decode] dynamic data back to [ContentFormat].
class ContentFormatTypeTransformer {
  factory ContentFormatTypeTransformer() =>
      _instance ??= const ContentFormatTypeTransformer._();

  const ContentFormatTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ContentFormat data) => data._value;

  /// Returns the instance of [ContentFormat] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContentFormat? decode(dynamic data, {bool allowNull = true}) {
    if (data is ContentFormat) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SHORTS':
          return ContentFormat.SHORTS;
        case r'REELS':
          return ContentFormat.REELS;
        case r'CARD_NEWS':
          return ContentFormat.CARD_NEWS;
        case r'BLOG':
          return ContentFormat.BLOG;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ContentFormatTypeTransformer? _instance;
}
