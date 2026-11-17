//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MarkReadDto {
  /// Returns a new [MarkReadDto] instance.
  MarkReadDto({
    required this.seq,
  });

  /// 여기까지 읽었다는 번호. 방의 마지막 번호를 넘을 수 없다.
  ///
  /// Minimum value: 0
  int seq;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MarkReadDto && other.seq == seq;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (seq.hashCode);

  @override
  String toString() => 'MarkReadDto[seq=$seq]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'seq'] = this.seq;
    return json;
  }

  /// Returns a new [MarkReadDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarkReadDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'seq'),
            'Required key "MarkReadDto[seq]" is missing from JSON.');
        assert(json[r'seq'] != null,
            'Required key "MarkReadDto[seq]" has a null value in JSON.');
        return true;
      }());

      return MarkReadDto(
        seq: mapValueOfType<int>(json, r'seq')!,
      );
    }
    return null;
  }

  static List<MarkReadDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MarkReadDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarkReadDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarkReadDto> mapFromJson(dynamic json) {
    final map = <String, MarkReadDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarkReadDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarkReadDto-objects as value to a dart map
  static Map<String, List<MarkReadDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MarkReadDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarkReadDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'seq',
  };
}
