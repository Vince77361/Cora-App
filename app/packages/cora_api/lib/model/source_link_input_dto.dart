//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SourceLinkInputDto {
  /// Returns a new [SourceLinkInputDto] instance.
  SourceLinkInputDto({
    required this.kind,
    required this.url,
  });

  SourceLinkKind kind;

  /// 종류에 맞는 https 주소. 네이버 지도: naver.me, map.naver.com. 캐치테이블: app.catchtable.co.kr. 인스타그램: instagram.com, www.instagram.com.
  String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceLinkInputDto && other.kind == kind && other.url == url;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (kind.hashCode) + (url.hashCode);

  @override
  String toString() => 'SourceLinkInputDto[kind=$kind, url=$url]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'kind'] = this.kind;
    json[r'url'] = this.url;
    return json;
  }

  /// Returns a new [SourceLinkInputDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SourceLinkInputDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'kind'),
            'Required key "SourceLinkInputDto[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "SourceLinkInputDto[kind]" has a null value in JSON.');
        assert(json.containsKey(r'url'),
            'Required key "SourceLinkInputDto[url]" is missing from JSON.');
        assert(json[r'url'] != null,
            'Required key "SourceLinkInputDto[url]" has a null value in JSON.');
        return true;
      }());

      return SourceLinkInputDto(
        kind: SourceLinkKind.fromJson(json[r'kind'])!,
        url: mapValueOfType<String>(json, r'url')!,
      );
    }
    return null;
  }

  static List<SourceLinkInputDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SourceLinkInputDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SourceLinkInputDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SourceLinkInputDto> mapFromJson(dynamic json) {
    final map = <String, SourceLinkInputDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SourceLinkInputDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SourceLinkInputDto-objects as value to a dart map
  static Map<String, List<SourceLinkInputDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SourceLinkInputDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SourceLinkInputDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'url',
  };
}
