//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ConversationLastMessageModel {
  /// Returns a new [ConversationLastMessageModel] instance.
  ConversationLastMessageModel({
    required this.at,
    required this.kind,
    required this.preview,
  });

  DateTime at;

  MessageKind kind;

  /// 한 줄 미리 보기. 글은 60자에서 자르고 …을 붙인다. 안내 줄은 읽는 사람에 맞춘 문구.
  String preview;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationLastMessageModel &&
          other.at == at &&
          other.kind == kind &&
          other.preview == preview;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (at.hashCode) + (kind.hashCode) + (preview.hashCode);

  @override
  String toString() =>
      'ConversationLastMessageModel[at=$at, kind=$kind, preview=$preview]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'at'] = this.at.toUtc().toIso8601String();
    json[r'kind'] = this.kind;
    json[r'preview'] = this.preview;
    return json;
  }

  /// Returns a new [ConversationLastMessageModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConversationLastMessageModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'at'),
            'Required key "ConversationLastMessageModel[at]" is missing from JSON.');
        assert(json[r'at'] != null,
            'Required key "ConversationLastMessageModel[at]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "ConversationLastMessageModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "ConversationLastMessageModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'preview'),
            'Required key "ConversationLastMessageModel[preview]" is missing from JSON.');
        assert(json[r'preview'] != null,
            'Required key "ConversationLastMessageModel[preview]" has a null value in JSON.');
        return true;
      }());

      return ConversationLastMessageModel(
        at: mapDateTime(json, r'at', r'')!,
        kind: MessageKind.fromJson(json[r'kind'])!,
        preview: mapValueOfType<String>(json, r'preview')!,
      );
    }
    return null;
  }

  static List<ConversationLastMessageModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConversationLastMessageModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationLastMessageModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConversationLastMessageModel> mapFromJson(dynamic json) {
    final map = <String, ConversationLastMessageModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConversationLastMessageModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConversationLastMessageModel-objects as value to a dart map
  static Map<String, List<ConversationLastMessageModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ConversationLastMessageModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConversationLastMessageModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'at',
    'kind',
    'preview',
  };
}
