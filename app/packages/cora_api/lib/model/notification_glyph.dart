//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 글자 그림. 정산은 WON(₩), 없으면 상대 사진.
enum NotificationGlyph {
  WON._(r'WON'),
  PEN._(r'PEN'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationGlyph._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationGlyph] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationGlyph? fromJson(dynamic value) =>
      NotificationGlyphTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationGlyph]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationGlyph> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationGlyph>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationGlyph.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationGlyph] to String,
/// and [decode] dynamic data back to [NotificationGlyph].
class NotificationGlyphTypeTransformer {
  factory NotificationGlyphTypeTransformer() =>
      _instance ??= const NotificationGlyphTypeTransformer._();

  const NotificationGlyphTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NotificationGlyph data) => data._value;

  /// Returns the instance of [NotificationGlyph] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationGlyph? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationGlyph) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WON':
          return NotificationGlyph.WON;
        case r'PEN':
          return NotificationGlyph.PEN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationGlyphTypeTransformer? _instance;
}
