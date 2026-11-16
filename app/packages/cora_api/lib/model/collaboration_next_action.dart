//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 지금 내가 할 일. RESPOND_TERMS: 최신 조건 판본을 아직 확인하지 않음, SIGN_CONTRACT: 양쪽이 합의해 계약할 차례. 그 밖은 null.
enum CollaborationNextAction {
  RESPOND_TERMS._(r'RESPOND_TERMS'),
  SIGN_CONTRACT._(r'SIGN_CONTRACT'),
  ;

  /// Instantiate a new enum with the provided value.
  const CollaborationNextAction._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CollaborationNextAction] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CollaborationNextAction? fromJson(dynamic value) =>
      CollaborationNextActionTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CollaborationNextAction]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CollaborationNextAction> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationNextAction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationNextAction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaborationNextAction] to String,
/// and [decode] dynamic data back to [CollaborationNextAction].
class CollaborationNextActionTypeTransformer {
  factory CollaborationNextActionTypeTransformer() =>
      _instance ??= const CollaborationNextActionTypeTransformer._();

  const CollaborationNextActionTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CollaborationNextAction data) => data._value;

  /// Returns the instance of [CollaborationNextAction] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaborationNextAction? decode(dynamic data, {bool allowNull = true}) {
    if (data is CollaborationNextAction) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'RESPOND_TERMS':
          return CollaborationNextAction.RESPOND_TERMS;
        case r'SIGN_CONTRACT':
          return CollaborationNextAction.SIGN_CONTRACT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CollaborationNextActionTypeTransformer? _instance;
}
