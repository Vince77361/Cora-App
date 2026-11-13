//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class VoucherDefaultsModel {
  /// Returns a new [VoucherDefaultsModel] instance.
  VoucherDefaultsModel({
    required this.defaultName,
    required this.defaultPeople,
    required this.defaultValue,
    required this.maxPeople,
    required this.maxValue,
    required this.minValue,
  });

  String defaultName;

  int defaultPeople;

  int defaultValue;

  int maxPeople;

  /// 식사권 금액의 최댓값(원).
  int maxValue;

  /// 식사권 금액의 최솟값(원).
  int minValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherDefaultsModel &&
          other.defaultName == defaultName &&
          other.defaultPeople == defaultPeople &&
          other.defaultValue == defaultValue &&
          other.maxPeople == maxPeople &&
          other.maxValue == maxValue &&
          other.minValue == minValue;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (defaultName.hashCode) +
      (defaultPeople.hashCode) +
      (defaultValue.hashCode) +
      (maxPeople.hashCode) +
      (maxValue.hashCode) +
      (minValue.hashCode);

  @override
  String toString() =>
      'VoucherDefaultsModel[defaultName=$defaultName, defaultPeople=$defaultPeople, defaultValue=$defaultValue, maxPeople=$maxPeople, maxValue=$maxValue, minValue=$minValue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'defaultName'] = this.defaultName;
    json[r'defaultPeople'] = this.defaultPeople;
    json[r'defaultValue'] = this.defaultValue;
    json[r'maxPeople'] = this.maxPeople;
    json[r'maxValue'] = this.maxValue;
    json[r'minValue'] = this.minValue;
    return json;
  }

  /// Returns a new [VoucherDefaultsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VoucherDefaultsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'defaultName'),
            'Required key "VoucherDefaultsModel[defaultName]" is missing from JSON.');
        assert(json[r'defaultName'] != null,
            'Required key "VoucherDefaultsModel[defaultName]" has a null value in JSON.');
        assert(json.containsKey(r'defaultPeople'),
            'Required key "VoucherDefaultsModel[defaultPeople]" is missing from JSON.');
        assert(json[r'defaultPeople'] != null,
            'Required key "VoucherDefaultsModel[defaultPeople]" has a null value in JSON.');
        assert(json.containsKey(r'defaultValue'),
            'Required key "VoucherDefaultsModel[defaultValue]" is missing from JSON.');
        assert(json[r'defaultValue'] != null,
            'Required key "VoucherDefaultsModel[defaultValue]" has a null value in JSON.');
        assert(json.containsKey(r'maxPeople'),
            'Required key "VoucherDefaultsModel[maxPeople]" is missing from JSON.');
        assert(json[r'maxPeople'] != null,
            'Required key "VoucherDefaultsModel[maxPeople]" has a null value in JSON.');
        assert(json.containsKey(r'maxValue'),
            'Required key "VoucherDefaultsModel[maxValue]" is missing from JSON.');
        assert(json[r'maxValue'] != null,
            'Required key "VoucherDefaultsModel[maxValue]" has a null value in JSON.');
        assert(json.containsKey(r'minValue'),
            'Required key "VoucherDefaultsModel[minValue]" is missing from JSON.');
        assert(json[r'minValue'] != null,
            'Required key "VoucherDefaultsModel[minValue]" has a null value in JSON.');
        return true;
      }());

      return VoucherDefaultsModel(
        defaultName: mapValueOfType<String>(json, r'defaultName')!,
        defaultPeople: mapValueOfType<int>(json, r'defaultPeople')!,
        defaultValue: mapValueOfType<int>(json, r'defaultValue')!,
        maxPeople: mapValueOfType<int>(json, r'maxPeople')!,
        maxValue: mapValueOfType<int>(json, r'maxValue')!,
        minValue: mapValueOfType<int>(json, r'minValue')!,
      );
    }
    return null;
  }

  static List<VoucherDefaultsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <VoucherDefaultsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VoucherDefaultsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VoucherDefaultsModel> mapFromJson(dynamic json) {
    final map = <String, VoucherDefaultsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VoucherDefaultsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VoucherDefaultsModel-objects as value to a dart map
  static Map<String, List<VoucherDefaultsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<VoucherDefaultsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VoucherDefaultsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'defaultName',
    'defaultPeople',
    'defaultValue',
    'maxPeople',
    'maxValue',
    'minValue',
  };
}
