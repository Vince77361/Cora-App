//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// SPAM 광고·스팸, ABUSE 부적절한 말, FRAUD 사기 의심, OTHER 기타.
enum ReportReason {
  SPAM._(r'SPAM'),
  ABUSE._(r'ABUSE'),
  FRAUD._(r'FRAUD'),
  OTHER._(r'OTHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const ReportReason._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ReportReason] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ReportReason? fromJson(dynamic value) =>
      ReportReasonTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ReportReason]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ReportReason> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReportReason>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReportReason.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ReportReason] to String,
/// and [decode] dynamic data back to [ReportReason].
class ReportReasonTypeTransformer {
  factory ReportReasonTypeTransformer() =>
      _instance ??= const ReportReasonTypeTransformer._();

  const ReportReasonTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ReportReason data) => data._value;

  /// Returns the instance of [ReportReason] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ReportReason? decode(dynamic data, {bool allowNull = true}) {
    if (data is ReportReason) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'SPAM':
          return ReportReason.SPAM;
        case r'ABUSE':
          return ReportReason.ABUSE;
        case r'FRAUD':
          return ReportReason.FRAUD;
        case r'OTHER':
          return ReportReason.OTHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ReportReasonTypeTransformer? _instance;
}
