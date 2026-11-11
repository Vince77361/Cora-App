//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 오퍼 수락, 가게 결제, 방문·촬영, 링크 제출, 조회수 집계 후 지급. 항상 이 다섯 개가 이 순서로 온다.
enum CollaborationStepKey {
  ACCEPTED._(r'ACCEPTED'),
  PAID._(r'PAID'),
  VISIT._(r'VISIT'),
  SUBMIT._(r'SUBMIT'),
  SETTLE._(r'SETTLE'),
  ;

  /// Instantiate a new enum with the provided value.
  const CollaborationStepKey._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CollaborationStepKey] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CollaborationStepKey? fromJson(dynamic value) =>
      CollaborationStepKeyTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CollaborationStepKey]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CollaborationStepKey> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationStepKey>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationStepKey.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaborationStepKey] to String,
/// and [decode] dynamic data back to [CollaborationStepKey].
class CollaborationStepKeyTypeTransformer {
  factory CollaborationStepKeyTypeTransformer() =>
      _instance ??= const CollaborationStepKeyTypeTransformer._();

  const CollaborationStepKeyTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CollaborationStepKey data) => data._value;

  /// Returns the instance of [CollaborationStepKey] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaborationStepKey? decode(dynamic data, {bool allowNull = true}) {
    if (data is CollaborationStepKey) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'ACCEPTED':
          return CollaborationStepKey.ACCEPTED;
        case r'PAID':
          return CollaborationStepKey.PAID;
        case r'VISIT':
          return CollaborationStepKey.VISIT;
        case r'SUBMIT':
          return CollaborationStepKey.SUBMIT;
        case r'SETTLE':
          return CollaborationStepKey.SETTLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CollaborationStepKeyTypeTransformer? _instance;
}
