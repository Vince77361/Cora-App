//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MeModel {
  /// Returns a new [MeModel] instance.
  MeModel({
    required this.id,
    required this.role,
  });

  String id;

  UserRole? role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeModel && other.id == id && other.role == role;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (role == null ? 0 : role!.hashCode);

  @override
  String toString() => 'MeModel[id=$id, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    if (this.role != null) {
      json[r'role'] = this.role;
    } else {
      json[r'role'] = null;
    }
    return json;
  }

  /// Returns a new [MeModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "MeModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "MeModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'role'),
            'Required key "MeModel[role]" is missing from JSON.');
        return true;
      }());

      return MeModel(
        id: mapValueOfType<String>(json, r'id')!,
        role: UserRole.fromJson(json[r'role']),
      );
    }
    return null;
  }

  static List<MeModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MeModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeModel> mapFromJson(dynamic json) {
    final map = <String, MeModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeModel-objects as value to a dart map
  static Map<String, List<MeModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MeModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'role',
  };
}
