//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FixedCashMaxModel {
  /// Returns a new [FixedCashMaxModel] instance.
  FixedCashMaxModel({
    required this.brand,
    required this.store,
  });

  /// 브랜드가 맡길 때의 최대(원).
  int brand;

  /// 가게가 맡길 때의 최대(원).
  int store;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedCashMaxModel &&
          other.brand == brand &&
          other.store == store;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brand.hashCode) + (store.hashCode);

  @override
  String toString() => 'FixedCashMaxModel[brand=$brand, store=$store]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'brand'] = this.brand;
    json[r'store'] = this.store;
    return json;
  }

  /// Returns a new [FixedCashMaxModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FixedCashMaxModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brand'),
            'Required key "FixedCashMaxModel[brand]" is missing from JSON.');
        assert(json[r'brand'] != null,
            'Required key "FixedCashMaxModel[brand]" has a null value in JSON.');
        assert(json.containsKey(r'store'),
            'Required key "FixedCashMaxModel[store]" is missing from JSON.');
        assert(json[r'store'] != null,
            'Required key "FixedCashMaxModel[store]" has a null value in JSON.');
        return true;
      }());

      return FixedCashMaxModel(
        brand: mapValueOfType<int>(json, r'brand')!,
        store: mapValueOfType<int>(json, r'store')!,
      );
    }
    return null;
  }

  static List<FixedCashMaxModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FixedCashMaxModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FixedCashMaxModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FixedCashMaxModel> mapFromJson(dynamic json) {
    final map = <String, FixedCashMaxModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FixedCashMaxModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FixedCashMaxModel-objects as value to a dart map
  static Map<String, List<FixedCashMaxModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FixedCashMaxModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FixedCashMaxModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brand',
    'store',
  };
}
