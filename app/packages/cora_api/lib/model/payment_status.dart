//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 결제 완료 여부는 결제창의 결과가 아니라 서버가 PG에서 받은 통지로 정해진다. 앱은 창이 닫힌 뒤 이 값을 묻는다.
enum PaymentStatus {
  PENDING._(r'PENDING'),
  APPROVED._(r'APPROVED'),
  FAILED._(r'FAILED'),
  CANCELLED._(r'CANCELLED'),
  ;

  /// Instantiate a new enum with the provided value.
  const PaymentStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PaymentStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PaymentStatus? fromJson(dynamic value) =>
      PaymentStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PaymentStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PaymentStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PaymentStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PaymentStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PaymentStatus] to String,
/// and [decode] dynamic data back to [PaymentStatus].
class PaymentStatusTypeTransformer {
  factory PaymentStatusTypeTransformer() =>
      _instance ??= const PaymentStatusTypeTransformer._();

  const PaymentStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(PaymentStatus data) => data._value;

  /// Returns the instance of [PaymentStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PaymentStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is PaymentStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PENDING':
          return PaymentStatus.PENDING;
        case r'APPROVED':
          return PaymentStatus.APPROVED;
        case r'FAILED':
          return PaymentStatus.FAILED;
        case r'CANCELLED':
          return PaymentStatus.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PaymentStatusTypeTransformer? _instance;
}
