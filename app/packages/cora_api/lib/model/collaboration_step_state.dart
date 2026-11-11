//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// DONE: 끝남, NOW: 지금 하는 단계, TODO: 아직. 끝난 협업에는 NOW가 없다.
enum CollaborationStepState {
  DONE._(r'DONE'),
  NOW._(r'NOW'),
  TODO._(r'TODO'),
  ;

  /// Instantiate a new enum with the provided value.
  const CollaborationStepState._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CollaborationStepState] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CollaborationStepState? fromJson(dynamic value) =>
      CollaborationStepStateTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CollaborationStepState]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CollaborationStepState> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationStepState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationStepState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CollaborationStepState] to String,
/// and [decode] dynamic data back to [CollaborationStepState].
class CollaborationStepStateTypeTransformer {
  factory CollaborationStepStateTypeTransformer() =>
      _instance ??= const CollaborationStepStateTypeTransformer._();

  const CollaborationStepStateTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CollaborationStepState data) => data._value;

  /// Returns the instance of [CollaborationStepState] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CollaborationStepState? decode(dynamic data, {bool allowNull = true}) {
    if (data is CollaborationStepState) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'DONE':
          return CollaborationStepState.DONE;
        case r'NOW':
          return CollaborationStepState.NOW;
        case r'TODO':
          return CollaborationStepState.TODO;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CollaborationStepStateTypeTransformer? _instance;
}
