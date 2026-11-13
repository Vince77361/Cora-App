//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreateCreatorSeriesDto {
  /// Returns a new [CreateCreatorSeriesDto] instance.
  CreateCreatorSeriesDto({
    required this.format,
    required this.name,
    this.note,
  });

  ContentFormat format;

  String name;

  /// 시리즈를 한 줄로 설명한다. 비우면 저장하지 않는다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateCreatorSeriesDto &&
          other.format == format &&
          other.name == name &&
          other.note == note;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) + (name.hashCode) + (note == null ? 0 : note!.hashCode);

  @override
  String toString() =>
      'CreateCreatorSeriesDto[format=$format, name=$name, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    json[r'name'] = this.name;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [CreateCreatorSeriesDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateCreatorSeriesDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "CreateCreatorSeriesDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "CreateCreatorSeriesDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "CreateCreatorSeriesDto[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreateCreatorSeriesDto[name]" has a null value in JSON.');
        return true;
      }());

      return CreateCreatorSeriesDto(
        format: ContentFormat.fromJson(json[r'format'])!,
        name: mapValueOfType<String>(json, r'name')!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<CreateCreatorSeriesDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateCreatorSeriesDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateCreatorSeriesDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateCreatorSeriesDto> mapFromJson(dynamic json) {
    final map = <String, CreateCreatorSeriesDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateCreatorSeriesDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateCreatorSeriesDto-objects as value to a dart map
  static Map<String, List<CreateCreatorSeriesDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateCreatorSeriesDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateCreatorSeriesDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'format',
    'name',
  };
}
