//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreResultCreatorModel {
  /// Returns a new [StoreResultCreatorModel] instance.
  StoreResultCreatorModel({
    required this.name,
    required this.photoUrl,
    required this.userId,
  });

  /// 크리에이터의 활동 이름.
  String name;

  String? photoUrl;

  String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreResultCreatorModel &&
          other.name == name &&
          other.photoUrl == photoUrl &&
          other.userId == userId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (userId.hashCode);

  @override
  String toString() =>
      'StoreResultCreatorModel[name=$name, photoUrl=$photoUrl, userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'userId'] = this.userId;
    return json;
  }

  /// Returns a new [StoreResultCreatorModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreResultCreatorModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "StoreResultCreatorModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "StoreResultCreatorModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "StoreResultCreatorModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'userId'),
            'Required key "StoreResultCreatorModel[userId]" is missing from JSON.');
        assert(json[r'userId'] != null,
            'Required key "StoreResultCreatorModel[userId]" has a null value in JSON.');
        return true;
      }());

      return StoreResultCreatorModel(
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<StoreResultCreatorModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreResultCreatorModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreResultCreatorModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreResultCreatorModel> mapFromJson(dynamic json) {
    final map = <String, StoreResultCreatorModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreResultCreatorModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreResultCreatorModel-objects as value to a dart map
  static Map<String, List<StoreResultCreatorModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreResultCreatorModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreResultCreatorModel.listFromJson(
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
    'userId',
  };
}
