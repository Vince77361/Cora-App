//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ManualBranchDto {
  /// Returns a new [ManualBranchDto] instance.
  ManualBranchDto({
    required this.label,
    this.neighborhood,
    this.regionSido,
    this.regionSigungu,
  });

  String label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? neighborhood;

  /// 시·도 고정 목록(SIDO_LIST) 중 하나.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? regionSido;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? regionSigungu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualBranchDto &&
          other.label == label &&
          other.neighborhood == neighborhood &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (label.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode);

  @override
  String toString() =>
      'ManualBranchDto[label=$label, neighborhood=$neighborhood, regionSido=$regionSido, regionSigungu=$regionSigungu]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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

  /// Returns a new [ManualBranchDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ManualBranchDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'label'),
            'Required key "ManualBranchDto[label]" is missing from JSON.');
        assert(json[r'label'] != null,
            'Required key "ManualBranchDto[label]" has a null value in JSON.');
        return true;
      }());

      return ManualBranchDto(
        label: mapValueOfType<String>(json, r'label')!,
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
      );
    }
    return null;
  }

  static List<ManualBranchDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ManualBranchDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ManualBranchDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ManualBranchDto> mapFromJson(dynamic json) {
    final map = <String, ManualBranchDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ManualBranchDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ManualBranchDto-objects as value to a dart map
  static Map<String, List<ManualBranchDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ManualBranchDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ManualBranchDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'label',
  };
}
