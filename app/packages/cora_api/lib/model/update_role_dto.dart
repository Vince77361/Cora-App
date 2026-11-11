//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpdateRoleDto {
  /// Returns a new [UpdateRoleDto] instance.
  UpdateRoleDto({
    required this.role,
  });

  UserRole role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UpdateRoleDto && other.role == role;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (role.hashCode);

  @override
  String toString() => 'UpdateRoleDto[role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'role'] = this.role;
    return json;
  }

  /// Returns a new [UpdateRoleDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateRoleDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'),
            'Required key "UpdateRoleDto[role]" is missing from JSON.');
        assert(json[r'role'] != null,
            'Required key "UpdateRoleDto[role]" has a null value in JSON.');
        return true;
      }());

      return UpdateRoleDto(
        role: UserRole.fromJson(json[r'role'])!,
      );
    }
    return null;
  }

  static List<UpdateRoleDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateRoleDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateRoleDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateRoleDto> mapFromJson(dynamic json) {
    final map = <String, UpdateRoleDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateRoleDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateRoleDto-objects as value to a dart map
  static Map<String, List<UpdateRoleDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateRoleDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateRoleDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
  };
}
