//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationCounterpartModel {
  /// Returns a new [CollaborationCounterpartModel] instance.
  CollaborationCounterpartModel({
    required this.name,
    required this.photoUrl,
  });

  /// 크리에이터에게는 가게 이름, 사장님에게는 크리에이터의 활동 이름.
  String name;

  String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationCounterpartModel &&
          other.name == name &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (photoUrl == null ? 0 : photoUrl!.hashCode);

  @override
  String toString() =>
      'CollaborationCounterpartModel[name=$name, photoUrl=$photoUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    return json;
  }

  /// Returns a new [CollaborationCounterpartModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollaborationCounterpartModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "CollaborationCounterpartModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CollaborationCounterpartModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CollaborationCounterpartModel[photoUrl]" is missing from JSON.');
        return true;
      }());

      return CollaborationCounterpartModel(
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
      );
    }
    return null;
  }

  static List<CollaborationCounterpartModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationCounterpartModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationCounterpartModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollaborationCounterpartModel> mapFromJson(dynamic json) {
    final map = <String, CollaborationCounterpartModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollaborationCounterpartModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollaborationCounterpartModel-objects as value to a dart map
  static Map<String, List<CollaborationCounterpartModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CollaborationCounterpartModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollaborationCounterpartModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'photoUrl',
  };
}
