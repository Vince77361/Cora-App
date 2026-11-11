//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SubmitContentDto {
  /// Returns a new [SubmitContentDto] instance.
  SubmitContentDto({
    required this.url,
  });

  /// 올린 콘텐츠의 주소. 형식(쇼츠·릴스·카드뉴스·블로그)에 맞는 https 주소만 받는다.
  String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubmitContentDto && other.url == url;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (url.hashCode);

  @override
  String toString() => 'SubmitContentDto[url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'url'] = this.url;
    return json;
  }

  /// Returns a new [SubmitContentDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubmitContentDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'url'),
            'Required key "SubmitContentDto[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "SubmitContentDto[url]" has a null value in JSON.');
        return true;
      }());

      return SubmitContentDto(
        url: mapValueOfType<String>(json, r'url')!,
      );
    }
    return null;
  }

  static List<SubmitContentDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SubmitContentDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubmitContentDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubmitContentDto> mapFromJson(dynamic json) {
    final map = <String, SubmitContentDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubmitContentDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubmitContentDto-objects as value to a dart map
  static Map<String, List<SubmitContentDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SubmitContentDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubmitContentDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
  };
}
