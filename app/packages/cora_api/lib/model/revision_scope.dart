//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum RevisionScope {
  NONE._(r'NONE'),
  GUIDE_1._(r'GUIDE_1'),
  DRAFT_1._(r'DRAFT_1'),
  DRAFT_2._(r'DRAFT_2'),
  ;

  /// Instantiate a new enum with the provided value.
  const RevisionScope._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RevisionScope] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RevisionScope? fromJson(dynamic value) =>
      RevisionScopeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RevisionScope]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RevisionScope> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RevisionScope>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RevisionScope.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RevisionScope] to String,
/// and [decode] dynamic data back to [RevisionScope].
class RevisionScopeTypeTransformer {
  factory RevisionScopeTypeTransformer() =>
      _instance ??= const RevisionScopeTypeTransformer._();

  const RevisionScopeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RevisionScope data) => data._value;

  /// Returns the instance of [RevisionScope] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RevisionScope? decode(dynamic data, {bool allowNull = true}) {
    if (data is RevisionScope) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'NONE':
          return RevisionScope.NONE;
        case r'GUIDE_1':
          return RevisionScope.GUIDE_1;
        case r'DRAFT_1':
          return RevisionScope.DRAFT_1;
        case r'DRAFT_2':
          return RevisionScope.DRAFT_2;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RevisionScopeTypeTransformer? _instance;
}
