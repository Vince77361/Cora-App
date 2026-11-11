//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum ApplicationStatus {
  APPLIED._(r'APPLIED'),
  CANCELLED._(r'CANCELLED'),
  OFFERED._(r'OFFERED'),
  CLOSED._(r'CLOSED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ApplicationStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ApplicationStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ApplicationStatus? fromJson(dynamic value) =>
      ApplicationStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ApplicationStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ApplicationStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApplicationStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApplicationStatus] to String,
/// and [decode] dynamic data back to [ApplicationStatus].
class ApplicationStatusTypeTransformer {
  factory ApplicationStatusTypeTransformer() =>
      _instance ??= const ApplicationStatusTypeTransformer._();

  const ApplicationStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ApplicationStatus data) => data._value;

  /// Returns the instance of [ApplicationStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApplicationStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is ApplicationStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APPLIED':
          return ApplicationStatus.APPLIED;
        case r'CANCELLED':
          return ApplicationStatus.CANCELLED;
        case r'OFFERED':
          return ApplicationStatus.OFFERED;
        case r'CLOSED':
          return ApplicationStatus.CLOSED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ApplicationStatusTypeTransformer? _instance;
}
