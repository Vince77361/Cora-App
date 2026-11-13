//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안.
enum ProposalGroup {
  MY_TURN._(r'MY_TURN'),
  WAITING._(r'WAITING'),
  ENDED._(r'ENDED'),
  ;

  /// Instantiate a new enum with the provided value.
  const ProposalGroup._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ProposalGroup] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ProposalGroup? fromJson(dynamic value) =>
      ProposalGroupTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ProposalGroup]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ProposalGroup> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalGroup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalGroup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProposalGroup] to String,
/// and [decode] dynamic data back to [ProposalGroup].
class ProposalGroupTypeTransformer {
  factory ProposalGroupTypeTransformer() =>
      _instance ??= const ProposalGroupTypeTransformer._();

  const ProposalGroupTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ProposalGroup data) => data._value;

  /// Returns the instance of [ProposalGroup] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProposalGroup? decode(dynamic data, {bool allowNull = true}) {
    if (data is ProposalGroup) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'MY_TURN':
          return ProposalGroup.MY_TURN;
        case r'WAITING':
          return ProposalGroup.WAITING;
        case r'ENDED':
          return ProposalGroup.ENDED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ProposalGroupTypeTransformer? _instance;
}
