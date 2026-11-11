//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class InstagramConnectionModel {
  /// Returns a new [InstagramConnectionModel] instance.
  InstagramConnectionModel({
    required this.followers,
    required this.handle,
  });

  int? followers;

  /// 연결된 인스타그램 아이디(@ 없이).
  String handle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstagramConnectionModel &&
          other.followers == followers &&
          other.handle == handle;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (followers == null ? 0 : followers!.hashCode) + (handle.hashCode);

  @override
  String toString() =>
      'InstagramConnectionModel[followers=$followers, handle=$handle]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.followers != null) {
      json[r'followers'] = this.followers;
    } else {
      json[r'followers'] = null;
    }
    json[r'handle'] = this.handle;
    return json;
  }

  /// Returns a new [InstagramConnectionModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InstagramConnectionModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'followers'),
            'Required key "InstagramConnectionModel[followers]" is missing from JSON.');
        assert(json.containsKey(r'handle'),
            'Required key "InstagramConnectionModel[handle]" is missing from JSON.');
        assert(json[r'handle'] != null,
            'Required key "InstagramConnectionModel[handle]" has a null value in JSON.');
        return true;
      }());

      return InstagramConnectionModel(
        followers: mapValueOfType<int>(json, r'followers'),
        handle: mapValueOfType<String>(json, r'handle')!,
      );
    }
    return null;
  }

  static List<InstagramConnectionModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InstagramConnectionModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InstagramConnectionModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InstagramConnectionModel> mapFromJson(dynamic json) {
    final map = <String, InstagramConnectionModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InstagramConnectionModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InstagramConnectionModel-objects as value to a dart map
  static Map<String, List<InstagramConnectionModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InstagramConnectionModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InstagramConnectionModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'followers',
    'handle',
  };
}
