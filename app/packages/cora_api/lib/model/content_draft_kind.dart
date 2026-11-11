//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum ContentDraftKind {
  CARD_NEWS._(r'CARD_NEWS'),
  REELS_SCRIPT._(r'REELS_SCRIPT'),
  BLOG._(r'BLOG'),
  ;

  /// Instantiate a new enum with the provided value.
  const ContentDraftKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ContentDraftKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ContentDraftKind? fromJson(dynamic value) =>
      ContentDraftKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ContentDraftKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ContentDraftKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentDraftKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentDraftKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContentDraftKind] to String,
/// and [decode] dynamic data back to [ContentDraftKind].
class ContentDraftKindTypeTransformer {
  factory ContentDraftKindTypeTransformer() =>
      _instance ??= const ContentDraftKindTypeTransformer._();

  const ContentDraftKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ContentDraftKind data) => data._value;

  /// Returns the instance of [ContentDraftKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContentDraftKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is ContentDraftKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CARD_NEWS':
          return ContentDraftKind.CARD_NEWS;
        case r'REELS_SCRIPT':
          return ContentDraftKind.REELS_SCRIPT;
        case r'BLOG':
          return ContentDraftKind.BLOG;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ContentDraftKindTypeTransformer? _instance;
}
