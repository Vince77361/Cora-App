//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum OfferEndReason {
  SCHEDULE._(r'SCHEDULE'),
  TERMS._(r'TERMS'),
  OTHER_PARTNER._(r'OTHER_PARTNER'),
  NO_REASON._(r'NO_REASON'),
  ;

  /// Instantiate a new enum with the provided value.
  const OfferEndReason._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [OfferEndReason] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static OfferEndReason? fromJson(dynamic value) =>
      OfferEndReasonTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [OfferEndReason]
  /// that were successfully decoded from the passed [JSON][json].
  static List<OfferEndReason> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferEndReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferEndReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OfferEndReason] to String,
/// and [decode] dynamic data back to [OfferEndReason].
class OfferEndReasonTypeTransformer {
  factory OfferEndReasonTypeTransformer() =>
      _instance ??= const OfferEndReasonTypeTransformer._();

  const OfferEndReasonTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(OfferEndReason data) => data._value;

  /// Returns the instance of [OfferEndReason] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OfferEndReason? decode(dynamic data, {bool allowNull = true}) {
    if (data is OfferEndReason) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SCHEDULE':
          return OfferEndReason.SCHEDULE;
        case r'TERMS':
          return OfferEndReason.TERMS;
        case r'OTHER_PARTNER':
          return OfferEndReason.OTHER_PARTNER;
        case r'NO_REASON':
          return OfferEndReason.NO_REASON;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static OfferEndReasonTypeTransformer? _instance;
}
