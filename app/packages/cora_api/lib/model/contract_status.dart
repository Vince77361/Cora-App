//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// NOT_READY = 양쪽이 같은 판본을 확인하기 전(미리 보기), AWAITING_CREATOR = 합의됨·크리에이터 동의 전, AWAITING_BRAND = 크리에이터 동의 뒤·브랜드 동의(결제) 전, PAYING = 브랜드가 결제 중(결제창을 연 지 60분 안), CONCLUDED = 결제가 승인돼 체결됨.
enum ContractStatus {
  NOT_READY._(r'NOT_READY'),
  AWAITING_CREATOR._(r'AWAITING_CREATOR'),
  AWAITING_BRAND._(r'AWAITING_BRAND'),
  PAYING._(r'PAYING'),
  CONCLUDED._(r'CONCLUDED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ContractStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ContractStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ContractStatus? fromJson(dynamic value) =>
      ContractStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ContractStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ContractStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContractStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContractStatus] to String,
/// and [decode] dynamic data back to [ContractStatus].
class ContractStatusTypeTransformer {
  factory ContractStatusTypeTransformer() =>
      _instance ??= const ContractStatusTypeTransformer._();

  const ContractStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ContractStatus data) => data._value;

  /// Returns the instance of [ContractStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContractStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is ContractStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NOT_READY':
          return ContractStatus.NOT_READY;
        case r'AWAITING_CREATOR':
          return ContractStatus.AWAITING_CREATOR;
        case r'AWAITING_BRAND':
          return ContractStatus.AWAITING_BRAND;
        case r'PAYING':
          return ContractStatus.PAYING;
        case r'CONCLUDED':
          return ContractStatus.CONCLUDED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ContractStatusTypeTransformer? _instance;
}
