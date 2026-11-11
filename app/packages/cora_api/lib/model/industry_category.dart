//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum IndustryCategory {
  FOOD_CAFE._(r'FOOD_CAFE'),
  BEAUTY._(r'BEAUTY'),
  FASHION._(r'FASHION'),
  ACCESSORY._(r'ACCESSORY'),
  LIVING._(r'LIVING'),
  GROCERY._(r'GROCERY'),
  DIGITAL._(r'DIGITAL'),
  HEALTH._(r'HEALTH'),
  OTHER._(r'OTHER'),
  ALCOHOL._(r'ALCOHOL'),
  GAMBLING._(r'GAMBLING'),
  LOAN._(r'LOAN'),
  DIET_SUPPLEMENT._(r'DIET_SUPPLEMENT'),
  ;

  /// Instantiate a new enum with the provided value.
  const IndustryCategory._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [IndustryCategory] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static IndustryCategory? fromJson(dynamic value) =>
      IndustryCategoryTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [IndustryCategory]
  /// that were successfully decoded from the passed [JSON][json].
  static List<IndustryCategory> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <IndustryCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IndustryCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [IndustryCategory] to String,
/// and [decode] dynamic data back to [IndustryCategory].
class IndustryCategoryTypeTransformer {
  factory IndustryCategoryTypeTransformer() =>
      _instance ??= const IndustryCategoryTypeTransformer._();

  const IndustryCategoryTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(IndustryCategory data) => data._value;

  /// Returns the instance of [IndustryCategory] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  IndustryCategory? decode(dynamic data, {bool allowNull = true}) {
    if (data is IndustryCategory) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'FOOD_CAFE':
          return IndustryCategory.FOOD_CAFE;
        case r'BEAUTY':
          return IndustryCategory.BEAUTY;
        case r'FASHION':
          return IndustryCategory.FASHION;
        case r'ACCESSORY':
          return IndustryCategory.ACCESSORY;
        case r'LIVING':
          return IndustryCategory.LIVING;
        case r'GROCERY':
          return IndustryCategory.GROCERY;
        case r'DIGITAL':
          return IndustryCategory.DIGITAL;
        case r'HEALTH':
          return IndustryCategory.HEALTH;
        case r'OTHER':
          return IndustryCategory.OTHER;
        case r'ALCOHOL':
          return IndustryCategory.ALCOHOL;
        case r'GAMBLING':
          return IndustryCategory.GAMBLING;
        case r'LOAN':
          return IndustryCategory.LOAN;
        case r'DIET_SUPPLEMENT':
          return IndustryCategory.DIET_SUPPLEMENT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static IndustryCategoryTypeTransformer? _instance;
}
