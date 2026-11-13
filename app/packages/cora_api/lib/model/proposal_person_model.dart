//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalPersonModel {
  /// Returns a new [ProposalPersonModel] instance.
  ProposalPersonModel({
    required this.name,
    required this.photoUrl,
    required this.userId,
  });

  String name;

  String? photoUrl;

  String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalPersonModel &&
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
      'ProposalPersonModel[name=$name, photoUrl=$photoUrl, userId=$userId]';

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

  /// Returns a new [ProposalPersonModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposalPersonModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "ProposalPersonModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "ProposalPersonModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "ProposalPersonModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'userId'),
            'Required key "ProposalPersonModel[userId]" is missing from JSON.');
        assert(json[r'userId'] != null,
            'Required key "ProposalPersonModel[userId]" has a null value in JSON.');
        return true;
      }());

      return ProposalPersonModel(
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<ProposalPersonModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalPersonModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalPersonModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposalPersonModel> mapFromJson(dynamic json) {
    final map = <String, ProposalPersonModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposalPersonModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposalPersonModel-objects as value to a dart map
  static Map<String, List<ProposalPersonModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposalPersonModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposalPersonModel.listFromJson(
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
