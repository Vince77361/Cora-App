//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class NotificationTargetModel {
  /// Returns a new [NotificationTargetModel] instance.
  NotificationTargetModel({
    required this.id,
    required this.kind,
  });

  String? id;

  /// 누르면 가는 곳의 종류(예: COLLABORATION, OFFER_INBOX, WALLET). 앱이 화면으로 바꾼다.
  String kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTargetModel && other.id == id && other.kind == kind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id == null ? 0 : id!.hashCode) + (kind.hashCode);

  @override
  String toString() => 'NotificationTargetModel[id=$id, kind=$kind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    json[r'kind'] = this.kind;
    return json;
  }

  /// Returns a new [NotificationTargetModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationTargetModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "NotificationTargetModel[id]" is missing from JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "NotificationTargetModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "NotificationTargetModel[kind]" has a null value in JSON.');
        return true;
      }());

      return NotificationTargetModel(
        id: mapValueOfType<String>(json, r'id'),
        kind: mapValueOfType<String>(json, r'kind')!,
      );
    }
    return null;
  }

  static List<NotificationTargetModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationTargetModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationTargetModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationTargetModel> mapFromJson(dynamic json) {
    final map = <String, NotificationTargetModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationTargetModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationTargetModel-objects as value to a dart map
  static Map<String, List<NotificationTargetModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<NotificationTargetModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationTargetModel.listFromJson(
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
    'kind',
  };
}
