//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 사장님에게 보이는 상태. 거절은 30초가 지나야 DECLINED로 보이고 그전에는 WAITING이다.
enum OfferView {
  WAITING._(r'WAITING'),
  ACCEPTED._(r'ACCEPTED'),
  DECLINED._(r'DECLINED'),
  EXPIRED._(r'EXPIRED'),
  CANCELLED._(r'CANCELLED'),
  ;

  /// Instantiate a new enum with the provided value.
  const OfferView._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [OfferView] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static OfferView? fromJson(dynamic value) =>
      OfferViewTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [OfferView]
  /// that were successfully decoded from the passed [JSON][json].
  static List<OfferView> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OfferView] to String,
/// and [decode] dynamic data back to [OfferView].
class OfferViewTypeTransformer {
  factory OfferViewTypeTransformer() =>
      _instance ??= const OfferViewTypeTransformer._();

  const OfferViewTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(OfferView data) => data._value;

  /// Returns the instance of [OfferView] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OfferView? decode(dynamic data, {bool allowNull = true}) {
    if (data is OfferView) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'WAITING':
          return OfferView.WAITING;
        case r'ACCEPTED':
          return OfferView.ACCEPTED;
        case r'DECLINED':
          return OfferView.DECLINED;
        case r'EXPIRED':
          return OfferView.EXPIRED;
        case r'CANCELLED':
          return OfferView.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static OfferViewTypeTransformer? _instance;
}
