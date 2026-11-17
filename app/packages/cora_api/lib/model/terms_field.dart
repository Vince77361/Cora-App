//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 바로 앞 판본에서 바뀐 항목. 판본 1은 빈 배열이다.
enum TermsField {
  TITLE._(r'TITLE'),
  FEE._(r'FEE'),
  PERFORMANCE._(r'PERFORMANCE'),
  START_DATE._(r'START_DATE'),
  DELIVERABLE._(r'DELIVERABLE'),
  PRODUCT._(r'PRODUCT'),
  REVISION._(r'REVISION'),
  USAGE._(r'USAGE'),
  PAYOUT._(r'PAYOUT'),
  ;

  /// Instantiate a new enum with the provided value.
  const TermsField._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TermsField] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TermsField? fromJson(dynamic value) =>
      TermsFieldTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TermsField]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TermsField> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsField>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsField.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TermsField] to String,
/// and [decode] dynamic data back to [TermsField].
class TermsFieldTypeTransformer {
  factory TermsFieldTypeTransformer() =>
      _instance ??= const TermsFieldTypeTransformer._();

  const TermsFieldTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TermsField data) => data._value;

  /// Returns the instance of [TermsField] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TermsField? decode(dynamic data, {bool allowNull = true}) {
    if (data is TermsField) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'TITLE':
          return TermsField.TITLE;
        case r'FEE':
          return TermsField.FEE;
        case r'PERFORMANCE':
          return TermsField.PERFORMANCE;
        case r'START_DATE':
          return TermsField.START_DATE;
        case r'DELIVERABLE':
          return TermsField.DELIVERABLE;
        case r'PRODUCT':
          return TermsField.PRODUCT;
        case r'REVISION':
          return TermsField.REVISION;
        case r'USAGE':
          return TermsField.USAGE;
        case r'PAYOUT':
          return TermsField.PAYOUT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TermsFieldTypeTransformer? _instance;
}
