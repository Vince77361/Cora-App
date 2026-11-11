//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum SourceLinkKind {
  NAVER_MAP._(r'NAVER_MAP'),
  CATCHTABLE._(r'CATCHTABLE'),
  INSTAGRAM._(r'INSTAGRAM'),
  ;

  /// Instantiate a new enum with the provided value.
  const SourceLinkKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SourceLinkKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SourceLinkKind? fromJson(dynamic value) =>
      SourceLinkKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SourceLinkKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SourceLinkKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SourceLinkKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SourceLinkKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SourceLinkKind] to String,
/// and [decode] dynamic data back to [SourceLinkKind].
class SourceLinkKindTypeTransformer {
  factory SourceLinkKindTypeTransformer() =>
      _instance ??= const SourceLinkKindTypeTransformer._();

  const SourceLinkKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SourceLinkKind data) => data._value;

  /// Returns the instance of [SourceLinkKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SourceLinkKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is SourceLinkKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NAVER_MAP':
          return SourceLinkKind.NAVER_MAP;
        case r'CATCHTABLE':
          return SourceLinkKind.CATCHTABLE;
        case r'INSTAGRAM':
          return SourceLinkKind.INSTAGRAM;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SourceLinkKindTypeTransformer? _instance;
}
