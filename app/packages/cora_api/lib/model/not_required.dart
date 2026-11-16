//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 요구하지 않는 것.
enum NotRequired {
  FACE._(r'FACE'),
  FIXED_LINES._(r'FIXED_LINES'),
  SCRIPT_READING._(r'SCRIPT_READING'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotRequired._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotRequired] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotRequired? fromJson(dynamic value) =>
      NotRequiredTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotRequired]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotRequired> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotRequired>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotRequired.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotRequired] to String,
/// and [decode] dynamic data back to [NotRequired].
class NotRequiredTypeTransformer {
  factory NotRequiredTypeTransformer() =>
      _instance ??= const NotRequiredTypeTransformer._();

  const NotRequiredTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NotRequired data) => data._value;

  /// Returns the instance of [NotRequired] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotRequired? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotRequired) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'FACE':
          return NotRequired.FACE;
        case r'FIXED_LINES':
          return NotRequired.FIXED_LINES;
        case r'SCRIPT_READING':
          return NotRequired.SCRIPT_READING;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotRequiredTypeTransformer? _instance;
}
