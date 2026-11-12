//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum NotificationTabFilter {
  ALL._(r'ALL'),
  MATCHING._(r'MATCHING'),
  COLLABORATION._(r'COLLABORATION'),
  SETTLEMENT._(r'SETTLEMENT'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationTabFilter._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationTabFilter] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationTabFilter? fromJson(dynamic value) =>
      NotificationTabFilterTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationTabFilter]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationTabFilter> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationTabFilter>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationTabFilter.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationTabFilter] to String,
/// and [decode] dynamic data back to [NotificationTabFilter].
class NotificationTabFilterTypeTransformer {
  factory NotificationTabFilterTypeTransformer() =>
      _instance ??= const NotificationTabFilterTypeTransformer._();

  const NotificationTabFilterTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NotificationTabFilter data) => data._value;

  /// Returns the instance of [NotificationTabFilter] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationTabFilter? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationTabFilter) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ALL':
          return NotificationTabFilter.ALL;
        case r'MATCHING':
          return NotificationTabFilter.MATCHING;
        case r'COLLABORATION':
          return NotificationTabFilter.COLLABORATION;
        case r'SETTLEMENT':
          return NotificationTabFilter.SETTLEMENT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationTabFilterTypeTransformer? _instance;
}
