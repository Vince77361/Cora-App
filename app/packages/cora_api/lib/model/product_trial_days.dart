//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

enum ProductTrialDays {
  D3._(r'D3'),
  D7._(r'D7'),
  D14._(r'D14'),
  ANY._(r'ANY'),
  ;

  /// Instantiate a new enum with the provided value.
  const ProductTrialDays._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ProductTrialDays] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ProductTrialDays? fromJson(dynamic value) =>
      ProductTrialDaysTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ProductTrialDays]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ProductTrialDays> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProductTrialDays>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProductTrialDays.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ProductTrialDays] to String,
/// and [decode] dynamic data back to [ProductTrialDays].
class ProductTrialDaysTypeTransformer {
  factory ProductTrialDaysTypeTransformer() =>
      _instance ??= const ProductTrialDaysTypeTransformer._();

  const ProductTrialDaysTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ProductTrialDays data) => data._value;

  /// Returns the instance of [ProductTrialDays] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ProductTrialDays? decode(dynamic data, {bool allowNull = true}) {
    if (data is ProductTrialDays) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'D3':
          return ProductTrialDays.D3;
        case r'D7':
          return ProductTrialDays.D7;
        case r'D14':
          return ProductTrialDays.D14;
        case r'ANY':
          return ProductTrialDays.ANY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ProductTrialDaysTypeTransformer? _instance;
}
