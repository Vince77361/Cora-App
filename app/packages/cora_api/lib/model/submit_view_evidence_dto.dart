//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SubmitViewEvidenceDto {
  /// Returns a new [SubmitViewEvidenceDto] instance.
  SubmitViewEvidenceDto({
    required this.path,
    required this.views,
  });

  /// 올린 캡처의 경로. POST /uploads/photos(purpose VIEW_EVIDENCE)가 내준 내 경로만 받는다.
  String path;

  /// 캡처에서 읽은 조회수.
  ///
  /// Minimum value: 0
  /// Maximum value: 1000000000
  int views;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmitViewEvidenceDto &&
          other.path == path &&
          other.views == views;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (path.hashCode) + (views.hashCode);

  @override
  String toString() => 'SubmitViewEvidenceDto[path=$path, views=$views]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'path'] = this.path;
    json[r'views'] = this.views;
    return json;
  }

  /// Returns a new [SubmitViewEvidenceDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubmitViewEvidenceDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'path'),
            'Required key "SubmitViewEvidenceDto[path]" is missing from JSON.');
        assert(json[r'path'] != null,
            'Required key "SubmitViewEvidenceDto[path]" has a null value in JSON.');
        assert(json.containsKey(r'views'),
            'Required key "SubmitViewEvidenceDto[views]" is missing from JSON.');
        assert(json[r'views'] != null,
            'Required key "SubmitViewEvidenceDto[views]" has a null value in JSON.');
        return true;
      }());

      return SubmitViewEvidenceDto(
        path: mapValueOfType<String>(json, r'path')!,
        views: mapValueOfType<int>(json, r'views')!,
      );
    }
    return null;
  }

  static List<SubmitViewEvidenceDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SubmitViewEvidenceDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubmitViewEvidenceDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubmitViewEvidenceDto> mapFromJson(dynamic json) {
    final map = <String, SubmitViewEvidenceDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubmitViewEvidenceDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubmitViewEvidenceDto-objects as value to a dart map
  static Map<String, List<SubmitViewEvidenceDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SubmitViewEvidenceDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubmitViewEvidenceDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'views',
  };
}
