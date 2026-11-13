//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

/// COMPARE: 종료일이 30일 안이라 비교를 보여 준다. HINT: 계약 정보를 넣으면 비교해 준다는 안내를 한 번 보여 준다.
enum TrialBanner {
  COMPARE._(r'COMPARE'),
  HINT._(r'HINT'),
  ;

  /// Instantiate a new enum with the provided value.
  const TrialBanner._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [TrialBanner] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static TrialBanner? fromJson(dynamic value) =>
      TrialBannerTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [TrialBanner]
  /// that were successfully decoded from the passed [JSON][json].
  static List<TrialBanner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TrialBanner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrialBanner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TrialBanner] to String,
/// and [decode] dynamic data back to [TrialBanner].
class TrialBannerTypeTransformer {
  factory TrialBannerTypeTransformer() =>
      _instance ??= const TrialBannerTypeTransformer._();

  const TrialBannerTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(TrialBanner data) => data._value;

  /// Returns the instance of [TrialBanner] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TrialBanner? decode(dynamic data, {bool allowNull = true}) {
    if (data is TrialBanner) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'COMPARE':
          return TrialBanner.COMPARE;
        case r'HINT':
          return TrialBanner.HINT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static TrialBannerTypeTransformer? _instance;
}
