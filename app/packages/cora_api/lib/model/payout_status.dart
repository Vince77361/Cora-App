//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인).
enum PayoutStatus {
  NONE._(r'NONE'),
  NEEDS_ACCOUNT._(r'NEEDS_ACCOUNT'),
  PENDING._(r'PENDING'),
  DONE._(r'DONE'),
  FAILED._(r'FAILED'),
  ;

  /// Instantiate a new enum with the provided value.
  const PayoutStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PayoutStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PayoutStatus? fromJson(dynamic value) =>
      PayoutStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PayoutStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PayoutStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PayoutStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PayoutStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PayoutStatus] to String,
/// and [decode] dynamic data back to [PayoutStatus].
class PayoutStatusTypeTransformer {
  factory PayoutStatusTypeTransformer() =>
      _instance ??= const PayoutStatusTypeTransformer._();

  const PayoutStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(PayoutStatus data) => data._value;

  /// Returns the instance of [PayoutStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PayoutStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is PayoutStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return PayoutStatus.NONE;
        case r'NEEDS_ACCOUNT':
          return PayoutStatus.NEEDS_ACCOUNT;
        case r'PENDING':
          return PayoutStatus.PENDING;
        case r'DONE':
          return PayoutStatus.DONE;
        case r'FAILED':
          return PayoutStatus.FAILED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PayoutStatusTypeTransformer? _instance;
}
