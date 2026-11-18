//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 내가 저장한 결정(하트 또는 저장). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다.
enum SavedDecision {
  LIKE._(r'LIKE'),
  HOLD._(r'HOLD'),
  ;

  /// Instantiate a new enum with the provided value.
  const SavedDecision._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SavedDecision] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SavedDecision? fromJson(dynamic value) =>
      SavedDecisionTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SavedDecision]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SavedDecision> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SavedDecision>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SavedDecision.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SavedDecision] to String,
/// and [decode] dynamic data back to [SavedDecision].
class SavedDecisionTypeTransformer {
  factory SavedDecisionTypeTransformer() =>
      _instance ??= const SavedDecisionTypeTransformer._();

  const SavedDecisionTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(SavedDecision data) => data._value;

  /// Returns the instance of [SavedDecision] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SavedDecision? decode(dynamic data, {bool allowNull = true}) {
    if (data is SavedDecision) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'LIKE':
          return SavedDecision.LIKE;
        case r'HOLD':
          return SavedDecision.HOLD;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SavedDecisionTypeTransformer? _instance;
}
