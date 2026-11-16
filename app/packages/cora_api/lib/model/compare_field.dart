//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// 두 후보의 보이는 값이 다른 줄(앞에 점을 붙인다).
enum CompareField {
  DELIVERABLE._(r'DELIVERABLE'),
  BENEFIT._(r'BENEFIT'),
  FEE._(r'FEE'),
  PERF_CAP._(r'PERF_CAP'),
  USAGE._(r'USAGE'),
  START._(r'START'),
  FACE._(r'FACE'),
  ;

  /// Instantiate a new enum with the provided value.
  const CompareField._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CompareField] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CompareField? fromJson(dynamic value) =>
      CompareFieldTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CompareField]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CompareField> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CompareField>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CompareField.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CompareField] to String,
/// and [decode] dynamic data back to [CompareField].
class CompareFieldTypeTransformer {
  factory CompareFieldTypeTransformer() =>
      _instance ??= const CompareFieldTypeTransformer._();

  const CompareFieldTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(CompareField data) => data._value;

  /// Returns the instance of [CompareField] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CompareField? decode(dynamic data, {bool allowNull = true}) {
    if (data is CompareField) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'DELIVERABLE':
          return CompareField.DELIVERABLE;
        case r'BENEFIT':
          return CompareField.BENEFIT;
        case r'FEE':
          return CompareField.FEE;
        case r'PERF_CAP':
          return CompareField.PERF_CAP;
        case r'USAGE':
          return CompareField.USAGE;
        case r'START':
          return CompareField.START;
        case r'FACE':
          return CompareField.FACE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CompareFieldTypeTransformer? _instance;
}
