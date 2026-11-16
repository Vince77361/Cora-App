//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpsertBrandProfileDto {
  /// Returns a new [UpsertBrandProfileDto] instance.
  UpsertBrandProfileDto({
    required this.industry,
    required this.name,
    this.photoPath,
    this.tagline,
  });

  IndustryCategory industry;

  String name;

  /// 대표 사진 경로. 이 요청은 전체 교체라서 비우거나 빠뜨리면 지운다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? photoPath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tagline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpsertBrandProfileDto &&
          other.industry == industry &&
          other.name == name &&
          other.photoPath == photoPath &&
          other.tagline == tagline;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (industry.hashCode) +
      (name.hashCode) +
      (photoPath == null ? 0 : photoPath!.hashCode) +
      (tagline == null ? 0 : tagline!.hashCode);

  @override
  String toString() =>
      'UpsertBrandProfileDto[industry=$industry, name=$name, photoPath=$photoPath, tagline=$tagline]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'industry'] = this.industry;
    json[r'name'] = this.name;
    if (this.photoPath != null) {
      json[r'photoPath'] = this.photoPath;
    } else {
      json[r'photoPath'] = null;
    }
    if (this.tagline != null) {
      json[r'tagline'] = this.tagline;
    } else {
      json[r'tagline'] = null;
    }
    return json;
  }

  /// Returns a new [UpsertBrandProfileDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpsertBrandProfileDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'industry'),
            'Required key "UpsertBrandProfileDto[industry]" is missing from JSON.');
        assert(json[r'industry'] != null,
            'Required key "UpsertBrandProfileDto[industry]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "UpsertBrandProfileDto[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "UpsertBrandProfileDto[name]" has a null value in JSON.');
        return true;
      }());

      return UpsertBrandProfileDto(
        industry: IndustryCategory.fromJson(json[r'industry'])!,
        name: mapValueOfType<String>(json, r'name')!,
        photoPath: mapValueOfType<String>(json, r'photoPath'),
        tagline: mapValueOfType<String>(json, r'tagline'),
      );
    }
    return null;
  }

  static List<UpsertBrandProfileDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpsertBrandProfileDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpsertBrandProfileDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpsertBrandProfileDto> mapFromJson(dynamic json) {
    final map = <String, UpsertBrandProfileDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpsertBrandProfileDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpsertBrandProfileDto-objects as value to a dart map
  static Map<String, List<UpsertBrandProfileDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpsertBrandProfileDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpsertBrandProfileDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'industry',
    'name',
  };
}
