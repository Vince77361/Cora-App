//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// NONE: 계약 동의 전, AWAITING_BRAND: 크리에이터가 동의해 브랜드 결제 대기, CONCLUDED: 체결.
enum ContractProgress {
  NONE._(r'NONE'),
  AWAITING_BRAND._(r'AWAITING_BRAND'),
  CONCLUDED._(r'CONCLUDED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ContractProgress._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ContractProgress] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ContractProgress? fromJson(dynamic value) =>
      ContractProgressTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ContractProgress]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ContractProgress> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContractProgress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractProgress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContractProgress] to String,
/// and [decode] dynamic data back to [ContractProgress].
class ContractProgressTypeTransformer {
  factory ContractProgressTypeTransformer() =>
      _instance ??= const ContractProgressTypeTransformer._();

  const ContractProgressTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ContractProgress data) => data._value;

  /// Returns the instance of [ContractProgress] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContractProgress? decode(dynamic data, {bool allowNull = true}) {
    if (data is ContractProgress) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return ContractProgress.NONE;
        case r'AWAITING_BRAND':
          return ContractProgress.AWAITING_BRAND;
        case r'CONCLUDED':
          return ContractProgress.CONCLUDED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ContractProgressTypeTransformer? _instance;
}
