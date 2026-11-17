//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SetMutedDto {
  /// Returns a new [SetMutedDto] instance.
  SetMutedDto({
    required this.muted,
  });

  /// 이 방의 알림을 끄려면 true.
  bool muted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SetMutedDto && other.muted == muted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (muted.hashCode);

  @override
  String toString() => 'SetMutedDto[muted=$muted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'muted'] = this.muted;
    return json;
  }

  /// Returns a new [SetMutedDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetMutedDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'muted'),
            'Required key "SetMutedDto[muted]" is missing from JSON.');
        assert(json[r'muted'] != null,
            'Required key "SetMutedDto[muted]" has a null value in JSON.');
        return true;
      }());

      return SetMutedDto(
        muted: mapValueOfType<bool>(json, r'muted')!,
      );
    }
    return null;
  }

  static List<SetMutedDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SetMutedDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetMutedDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetMutedDto> mapFromJson(dynamic json) {
    final map = <String, SetMutedDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetMutedDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetMutedDto-objects as value to a dart map
  static Map<String, List<SetMutedDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SetMutedDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetMutedDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'muted',
  };
}
