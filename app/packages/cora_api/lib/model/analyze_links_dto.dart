//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class AnalyzeLinksDto {
  /// Returns a new [AnalyzeLinksDto] instance.
  AnalyzeLinksDto({
    this.links = const [],
  });

  /// 링크 1~3개. 같은 종류는 한 번만.
  List<SourceLinkInputDto> links;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzeLinksDto && _deepEquality.equals(other.links, links);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (links.hashCode);

  @override
  String toString() => 'AnalyzeLinksDto[links=$links]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'links'] = this.links;
    return json;
  }

  /// Returns a new [AnalyzeLinksDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyzeLinksDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'links'),
            'Required key "AnalyzeLinksDto[links]" is missing from JSON.');
        assert(json[r'links'] != null,
            'Required key "AnalyzeLinksDto[links]" has a null value in JSON.');
        return true;
      }());

      return AnalyzeLinksDto(
        links: SourceLinkInputDto.listFromJson(json[r'links']),
      );
    }
    return null;
  }

  static List<AnalyzeLinksDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AnalyzeLinksDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyzeLinksDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyzeLinksDto> mapFromJson(dynamic json) {
    final map = <String, AnalyzeLinksDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyzeLinksDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyzeLinksDto-objects as value to a dart map
  static Map<String, List<AnalyzeLinksDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AnalyzeLinksDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyzeLinksDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'links',
  };
}
