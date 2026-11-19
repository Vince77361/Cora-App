//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// APPLICANTS = 이 가게에 지원 중인 사람 중에서, ALL = 지원자가 없어 Cora 크리에이터 전체에서 뽑았다.
enum RecommendedSource {
  APPLICANTS._(r'APPLICANTS'),
  ALL._(r'ALL'),
  ;

  /// Instantiate a new enum with the provided value.
  const RecommendedSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RecommendedSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RecommendedSource? fromJson(dynamic value) =>
      RecommendedSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RecommendedSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RecommendedSource> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RecommendedSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecommendedSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RecommendedSource] to String,
/// and [decode] dynamic data back to [RecommendedSource].
class RecommendedSourceTypeTransformer {
  factory RecommendedSourceTypeTransformer() =>
      _instance ??= const RecommendedSourceTypeTransformer._();

  const RecommendedSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(RecommendedSource data) => data._value;

  /// Returns the instance of [RecommendedSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RecommendedSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is RecommendedSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'APPLICANTS':
          return RecommendedSource.APPLICANTS;
        case r'ALL':
          return RecommendedSource.ALL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RecommendedSourceTypeTransformer? _instance;
}
