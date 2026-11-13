//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreBranchModel {
  /// Returns a new [StoreBranchModel] instance.
  StoreBranchModel({
    required this.address,
    required this.label,
    required this.neighborhood,
    required this.regionSido,
    required this.regionSigungu,
  });

  String address;

  /// 지점 이름(예: 성수점).
  String label;

  String? neighborhood;

  String? regionSido;

  String? regionSigungu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreBranchModel &&
          other.address == address &&
          other.label == label &&
          other.neighborhood == neighborhood &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (address.hashCode) +
      (label.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode);

  @override
  String toString() =>
      'StoreBranchModel[address=$address, label=$label, neighborhood=$neighborhood, regionSido=$regionSido, regionSigungu=$regionSigungu]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'address'] = this.address;
    json[r'label'] = this.label;
    if (this.neighborhood != null) {
      json[r'neighborhood'] = this.neighborhood;
    } else {
      json[r'neighborhood'] = null;
    }
    if (this.regionSido != null) {
      json[r'regionSido'] = this.regionSido;
    } else {
      json[r'regionSido'] = null;
    }
    if (this.regionSigungu != null) {
      json[r'regionSigungu'] = this.regionSigungu;
    } else {
      json[r'regionSigungu'] = null;
    }
    return json;
  }

  /// Returns a new [StoreBranchModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreBranchModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'address'),
            'Required key "StoreBranchModel[address]" is missing from JSON.');
        assert(json[r'address'] != null,
            'Required key "StoreBranchModel[address]" has a null value in JSON.');
        assert(json.containsKey(r'label'),
            'Required key "StoreBranchModel[label]" is missing from JSON.');
        assert(json[r'label'] != null,
            'Required key "StoreBranchModel[label]" has a null value in JSON.');
        assert(json.containsKey(r'neighborhood'),
            'Required key "StoreBranchModel[neighborhood]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "StoreBranchModel[regionSido]" is missing from JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "StoreBranchModel[regionSigungu]" is missing from JSON.');
        return true;
      }());

      return StoreBranchModel(
        address: mapValueOfType<String>(json, r'address')!,
        label: mapValueOfType<String>(json, r'label')!,
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
      );
    }
    return null;
  }

  static List<StoreBranchModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreBranchModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreBranchModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreBranchModel> mapFromJson(dynamic json) {
    final map = <String, StoreBranchModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreBranchModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreBranchModel-objects as value to a dart map
  static Map<String, List<StoreBranchModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreBranchModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreBranchModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'label',
    'neighborhood',
    'regionSido',
    'regionSigungu',
  };
}
