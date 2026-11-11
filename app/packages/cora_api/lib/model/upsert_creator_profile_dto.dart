//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpsertCreatorProfileDto {
  /// Returns a new [UpsertCreatorProfileDto] instance.
  UpsertCreatorProfileDto({
    this.contentFocus,
    required this.displayName,
    this.instagramHandle,
    this.photoPath,
    required this.regionSido,
    this.regionSigungu,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contentFocus;

  String displayName;

  /// 영문, 숫자, 점, 밑줄. 앞의 @ 하나는 떼고 저장한다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? instagramHandle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? photoPath;

  /// 시·도 고정 목록(SIDO_LIST) 중 하나.
  String regionSido;

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
      other is UpsertCreatorProfileDto &&
          other.contentFocus == contentFocus &&
          other.displayName == displayName &&
          other.instagramHandle == instagramHandle &&
          other.photoPath == photoPath &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentFocus == null ? 0 : contentFocus!.hashCode) +
      (displayName.hashCode) +
      (instagramHandle == null ? 0 : instagramHandle!.hashCode) +
      (photoPath == null ? 0 : photoPath!.hashCode) +
      (regionSido.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode);

  @override
  String toString() =>
      'UpsertCreatorProfileDto[contentFocus=$contentFocus, displayName=$displayName, instagramHandle=$instagramHandle, photoPath=$photoPath, regionSido=$regionSido, regionSigungu=$regionSigungu]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentFocus != null) {
      json[r'contentFocus'] = this.contentFocus;
    } else {
      json[r'contentFocus'] = null;
    }
    json[r'displayName'] = this.displayName;
    if (this.instagramHandle != null) {
      json[r'instagramHandle'] = this.instagramHandle;
    } else {
      json[r'instagramHandle'] = null;
    }
    if (this.photoPath != null) {
      json[r'photoPath'] = this.photoPath;
    } else {
      json[r'photoPath'] = null;
    }
    json[r'regionSido'] = this.regionSido;
    if (this.regionSigungu != null) {
      json[r'regionSigungu'] = this.regionSigungu;
    } else {
      json[r'regionSigungu'] = null;
    }
    return json;
  }

  /// Returns a new [UpsertCreatorProfileDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpsertCreatorProfileDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'displayName'),
            'Required key "UpsertCreatorProfileDto[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "UpsertCreatorProfileDto[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "UpsertCreatorProfileDto[regionSido]" is missing from JSON.');
        assert(json[r'regionSido'] != null,
            'Required key "UpsertCreatorProfileDto[regionSido]" has a null value in JSON.');
        return true;
      }());

      return UpsertCreatorProfileDto(
        contentFocus: mapValueOfType<String>(json, r'contentFocus'),
        displayName: mapValueOfType<String>(json, r'displayName')!,
        instagramHandle: mapValueOfType<String>(json, r'instagramHandle'),
        photoPath: mapValueOfType<String>(json, r'photoPath'),
        regionSido: mapValueOfType<String>(json, r'regionSido')!,
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
      );
    }
    return null;
  }

  static List<UpsertCreatorProfileDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpsertCreatorProfileDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpsertCreatorProfileDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpsertCreatorProfileDto> mapFromJson(dynamic json) {
    final map = <String, UpsertCreatorProfileDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpsertCreatorProfileDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpsertCreatorProfileDto-objects as value to a dart map
  static Map<String, List<UpsertCreatorProfileDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpsertCreatorProfileDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpsertCreatorProfileDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'displayName',
    'regionSido',
  };
}
