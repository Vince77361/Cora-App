//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.
enum ProposalEndKind {
  AGREED._(r'AGREED'),
  ENDED._(r'ENDED'),
  EXPIRED._(r'EXPIRED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ProposalEndKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ProposalEndKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ProposalEndKind? fromJson(dynamic value) =>
      ProposalEndKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ProposalEndKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ProposalEndKind> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalEndKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalEndKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProposalEndKind] to String,
/// and [decode] dynamic data back to [ProposalEndKind].
class ProposalEndKindTypeTransformer {
  factory ProposalEndKindTypeTransformer() =>
      _instance ??= const ProposalEndKindTypeTransformer._();

  const ProposalEndKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ProposalEndKind data) => data._value;

  /// Returns the instance of [ProposalEndKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProposalEndKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is ProposalEndKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'AGREED':
          return ProposalEndKind.AGREED;
        case r'ENDED':
          return ProposalEndKind.ENDED;
        case r'EXPIRED':
          return ProposalEndKind.EXPIRED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ProposalEndKindTypeTransformer? _instance;
}
