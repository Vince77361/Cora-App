//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class NotificationActorModel {
  /// Returns a new [NotificationActorModel] instance.
  NotificationActorModel({
    required this.name,
    required this.photoUrl,
  });

  /// 알림을 만들 때 저장한 상대의 이름 사본.
  String name;

  /// 상대 사진의 공개 주소. 사진이 없으면 null(앱이 이름 첫 글자를 그린다).
  String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationActorModel &&
          other.name == name &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (photoUrl == null ? 0 : photoUrl!.hashCode);

  @override
  String toString() => 'NotificationActorModel[name=$name, photoUrl=$photoUrl]';

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

  /// Returns a new [NotificationActorModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationActorModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'),
            'Required key "NotificationActorModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "NotificationActorModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "NotificationActorModel[photoUrl]" is missing from JSON.');
        return true;
      }());

      return NotificationActorModel(
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
      );
    }
    return null;
  }

  static List<NotificationActorModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationActorModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationActorModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationActorModel> mapFromJson(dynamic json) {
    final map = <String, NotificationActorModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationActorModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationActorModel-objects as value to a dart map
  static Map<String, List<NotificationActorModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<NotificationActorModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationActorModel.listFromJson(
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
