//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 최신 판본의 확인 상태. NONE = 아무도 확인하지 않음, WAITING_BRAND = 크리에이터만 확인, WAITING_CREATOR = 브랜드만 확인, AGREED = 양쪽 확인.
enum TermsAgreement {
  NONE._(r'NONE'),
  WAITING_BRAND._(r'WAITING_BRAND'),
  WAITING_CREATOR._(r'WAITING_CREATOR'),
  AGREED._(r'AGREED'),
  ;

  /// Instantiate a new enum with the provided value.
  const TermsAgreement._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TermsAgreement] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TermsAgreement? fromJson(dynamic value) =>
      TermsAgreementTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TermsAgreement]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TermsAgreement> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsAgreement>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsAgreement.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TermsAgreement] to String,
/// and [decode] dynamic data back to [TermsAgreement].
class TermsAgreementTypeTransformer {
  factory TermsAgreementTypeTransformer() =>
      _instance ??= const TermsAgreementTypeTransformer._();

  const TermsAgreementTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TermsAgreement data) => data._value;

  /// Returns the instance of [TermsAgreement] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TermsAgreement? decode(dynamic data, {bool allowNull = true}) {
    if (data is TermsAgreement) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return TermsAgreement.NONE;
        case r'WAITING_BRAND':
          return TermsAgreement.WAITING_BRAND;
        case r'WAITING_CREATOR':
          return TermsAgreement.WAITING_CREATOR;
        case r'AGREED':
          return TermsAgreement.AGREED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TermsAgreementTypeTransformer? _instance;
}
