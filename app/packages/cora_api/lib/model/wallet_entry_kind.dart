//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// PAYOUT_SCHEDULED: 정산이 확정되고 송금 전, PAYOUT_DONE: 송금 끝, PAYOUT_FAILED: 송금 실패(운영팀이 확인), HELD: Cora가 보관 중, VOUCHER: 식사권.
enum WalletEntryKind {
  PAYOUT_SCHEDULED._(r'PAYOUT_SCHEDULED'),
  PAYOUT_DONE._(r'PAYOUT_DONE'),
  PAYOUT_FAILED._(r'PAYOUT_FAILED'),
  HELD._(r'HELD'),
  VOUCHER._(r'VOUCHER'),
  ;

  /// Instantiate a new enum with the provided value.
  const WalletEntryKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [WalletEntryKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static WalletEntryKind? fromJson(dynamic value) =>
      WalletEntryKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [WalletEntryKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<WalletEntryKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WalletEntryKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WalletEntryKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WalletEntryKind] to String,
/// and [decode] dynamic data back to [WalletEntryKind].
class WalletEntryKindTypeTransformer {
  factory WalletEntryKindTypeTransformer() =>
      _instance ??= const WalletEntryKindTypeTransformer._();

  const WalletEntryKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(WalletEntryKind data) => data._value;

  /// Returns the instance of [WalletEntryKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WalletEntryKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is WalletEntryKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'PAYOUT_SCHEDULED':
          return WalletEntryKind.PAYOUT_SCHEDULED;
        case r'PAYOUT_DONE':
          return WalletEntryKind.PAYOUT_DONE;
        case r'PAYOUT_FAILED':
          return WalletEntryKind.PAYOUT_FAILED;
        case r'HELD':
          return WalletEntryKind.HELD;
        case r'VOUCHER':
          return WalletEntryKind.VOUCHER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static WalletEntryKindTypeTransformer? _instance;
}
