//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ImportInstagramPostsDto {
  /// Returns a new [ImportInstagramPostsDto] instance.
  ImportInstagramPostsDto({
    this.postIds = const [],
  });

  /// 가져올 인스타그램 게시물 ID. 같은 ID를 두 번 보낼 수 없다.
  List<String> postIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportInstagramPostsDto &&
          _deepEquality.equals(other.postIds, postIds);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (postIds.hashCode);

  @override
  String toString() => 'ImportInstagramPostsDto[postIds=$postIds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'postIds'] = this.postIds;
    return json;
  }

  /// Returns a new [ImportInstagramPostsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImportInstagramPostsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'postIds'),
            'Required key "ImportInstagramPostsDto[postIds]" is missing from JSON.');
        assert(json[r'postIds'] != null,
            'Required key "ImportInstagramPostsDto[postIds]" has a null value in JSON.');
        return true;
      }());

      return ImportInstagramPostsDto(
        postIds: json[r'postIds'] is Iterable
            ? (json[r'postIds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<ImportInstagramPostsDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportInstagramPostsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportInstagramPostsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImportInstagramPostsDto> mapFromJson(dynamic json) {
    final map = <String, ImportInstagramPostsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImportInstagramPostsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImportInstagramPostsDto-objects as value to a dart map
  static Map<String, List<ImportInstagramPostsDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ImportInstagramPostsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImportInstagramPostsDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'postIds',
  };
}
