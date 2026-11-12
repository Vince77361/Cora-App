//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class NotificationModel {
  /// Returns a new [NotificationModel] instance.
  NotificationModel({
    required this.actor,
    required this.createdAt,
    required this.glyph,
    required this.id,
    required this.read,
    required this.tab,
    required this.target,
    required this.text,
  });

  NotificationActorModel? actor;

  /// 만든 시각(ISO 8601).
  DateTime createdAt;

  /// 글자 그림. 정산은 WON(₩), 없으면 상대 사진.
  NotificationGlyph? glyph;

  String id;

  bool read;

  NotificationTab tab;

  NotificationTargetModel target;

  /// 종류와 값으로 만든 문구(카탈로그의 render).
  String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          other.actor == actor &&
          other.createdAt == createdAt &&
          other.glyph == glyph &&
          other.id == id &&
          other.read == read &&
          other.tab == tab &&
          other.target == target &&
          other.text == text;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (actor == null ? 0 : actor!.hashCode) +
      (createdAt.hashCode) +
      (glyph == null ? 0 : glyph!.hashCode) +
      (id.hashCode) +
      (read.hashCode) +
      (tab.hashCode) +
      (target.hashCode) +
      (text.hashCode);

  @override
  String toString() =>
      'NotificationModel[actor=$actor, createdAt=$createdAt, glyph=$glyph, id=$id, read=$read, tab=$tab, target=$target, text=$text]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.actor != null) {
      json[r'actor'] = this.actor;
    } else {
      json[r'actor'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.glyph != null) {
      json[r'glyph'] = this.glyph;
    } else {
      json[r'glyph'] = null;
    }
    json[r'id'] = this.id;
    json[r'read'] = this.read;
    json[r'tab'] = this.tab;
    json[r'target'] = this.target;
    json[r'text'] = this.text;
    return json;
  }

  /// Returns a new [NotificationModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'actor'),
            'Required key "NotificationModel[actor]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "NotificationModel[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "NotificationModel[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'glyph'),
            'Required key "NotificationModel[glyph]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "NotificationModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "NotificationModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'read'),
            'Required key "NotificationModel[read]" is missing from JSON.');
        assert(json[r'read'] != null,
            'Required key "NotificationModel[read]" has a null value in JSON.');
        assert(json.containsKey(r'tab'),
            'Required key "NotificationModel[tab]" is missing from JSON.');
        assert(json[r'tab'] != null,
            'Required key "NotificationModel[tab]" has a null value in JSON.');
        assert(json.containsKey(r'target'),
            'Required key "NotificationModel[target]" is missing from JSON.');
        assert(json[r'target'] != null,
            'Required key "NotificationModel[target]" has a null value in JSON.');
        assert(json.containsKey(r'text'),
            'Required key "NotificationModel[text]" is missing from JSON.');
        assert(json[r'text'] != null,
            'Required key "NotificationModel[text]" has a null value in JSON.');
        return true;
      }());

      return NotificationModel(
        actor: NotificationActorModel.fromJson(json[r'actor']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        glyph: NotificationGlyph.fromJson(json[r'glyph']),
        id: mapValueOfType<String>(json, r'id')!,
        read: mapValueOfType<bool>(json, r'read')!,
        tab: NotificationTab.fromJson(json[r'tab'])!,
        target: NotificationTargetModel.fromJson(json[r'target'])!,
        text: mapValueOfType<String>(json, r'text')!,
      );
    }
    return null;
  }

  static List<NotificationModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationModel> mapFromJson(dynamic json) {
    final map = <String, NotificationModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationModel-objects as value to a dart map
  static Map<String, List<NotificationModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<NotificationModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'actor',
    'createdAt',
    'glyph',
    'id',
    'read',
    'tab',
    'target',
    'text',
  };
}
