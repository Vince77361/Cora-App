//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MessageCardModel {
  /// Returns a new [MessageCardModel] instance.
  MessageCardModel({
    required this.photoUrl,
    required this.title,
  });

  /// 카드를 보낸 시점의 사진(사본). 없으면 null.
  String? photoUrl;

  /// 카드를 보낸 시점의 콘텐츠 제목(사본).
  String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageCardModel &&
          other.photoUrl == photoUrl &&
          other.title == title;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (photoUrl == null ? 0 : photoUrl!.hashCode) + (title.hashCode);

  @override
  String toString() => 'MessageCardModel[photoUrl=$photoUrl, title=$title]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'title'] = this.title;
    return json;
  }

  /// Returns a new [MessageCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MessageCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'photoUrl'),
            'Required key "MessageCardModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'title'),
            'Required key "MessageCardModel[title]" is missing from JSON.');
        assert(json[r'title'] != null,
            'Required key "MessageCardModel[title]" has a null value in JSON.');
        return true;
      }());

      return MessageCardModel(
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        title: mapValueOfType<String>(json, r'title')!,
      );
    }
    return null;
  }

  static List<MessageCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MessageCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MessageCardModel> mapFromJson(dynamic json) {
    final map = <String, MessageCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MessageCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MessageCardModel-objects as value to a dart map
  static Map<String, List<MessageCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MessageCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MessageCardModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'photoUrl',
    'title',
  };
}
