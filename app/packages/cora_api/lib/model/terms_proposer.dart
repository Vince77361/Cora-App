//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// SYSTEM은 서로 관심이 닿을 때 서버가 만든 버전 1이다.
enum TermsProposer {
  BRAND._(r'BRAND'),
  CREATOR._(r'CREATOR'),
  SYSTEM._(r'SYSTEM'),
  ;

  /// Instantiate a new enum with the provided value.
  const TermsProposer._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TermsProposer] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TermsProposer? fromJson(dynamic value) =>
      TermsProposerTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TermsProposer]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TermsProposer> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsProposer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsProposer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TermsProposer] to String,
/// and [decode] dynamic data back to [TermsProposer].
class TermsProposerTypeTransformer {
  factory TermsProposerTypeTransformer() =>
      _instance ??= const TermsProposerTypeTransformer._();

  const TermsProposerTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TermsProposer data) => data._value;

  /// Returns the instance of [TermsProposer] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TermsProposer? decode(dynamic data, {bool allowNull = true}) {
    if (data is TermsProposer) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'BRAND':
          return TermsProposer.BRAND;
        case r'CREATOR':
          return TermsProposer.CREATOR;
        case r'SYSTEM':
          return TermsProposer.SYSTEM;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TermsProposerTypeTransformer? _instance;
}
