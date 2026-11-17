//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MessageModel {
  /// Returns a new [MessageModel] instance.
  MessageModel({
    required this.card,
    required this.clientId,
    required this.createdAt,
    required this.id,
    required this.kind,
    required this.mine,
    required this.seq,
    required this.text,
  });

  MessageCardModel? card;

  /// 앱이 보낸 중복 방지 값. 내가 보낸 메시지에만 있다.
  String? clientId;

  DateTime createdAt;

  String id;

  MessageKind kind;

  /// 내가 보낸 메시지이면 true. 안내 줄은 false.
  bool mine;

  /// 방 안의 번호(1부터, 빠짐없이 늘어난다).
  int seq;

  /// 글 메시지의 글, 안내 줄은 읽는 사람에 맞춰 서버가 만든 문구. 콘텐츠 카드는 null.
  String? text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          other.card == card &&
          other.clientId == clientId &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.kind == kind &&
          other.mine == mine &&
          other.seq == seq &&
          other.text == text;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (card == null ? 0 : card!.hashCode) +
      (clientId == null ? 0 : clientId!.hashCode) +
      (createdAt.hashCode) +
      (id.hashCode) +
      (kind.hashCode) +
      (mine.hashCode) +
      (seq.hashCode) +
      (text == null ? 0 : text!.hashCode);

  @override
  String toString() =>
      'MessageModel[card=$card, clientId=$clientId, createdAt=$createdAt, id=$id, kind=$kind, mine=$mine, seq=$seq, text=$text]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.card != null) {
      json[r'card'] = this.card;
    } else {
      json[r'card'] = null;
    }
    if (this.clientId != null) {
      json[r'clientId'] = this.clientId;
    } else {
      json[r'clientId'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'mine'] = this.mine;
    json[r'seq'] = this.seq;
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    return json;
  }

  /// Returns a new [MessageModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MessageModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'card'),
            'Required key "MessageModel[card]" is missing from JSON.');
        assert(json.containsKey(r'clientId'),
            'Required key "MessageModel[clientId]" is missing from JSON.');
        assert(json.containsKey(r'createdAt'),
            'Required key "MessageModel[createdAt]" is missing from JSON.');
        assert(json[r'createdAt'] != null,
            'Required key "MessageModel[createdAt]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "MessageModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "MessageModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "MessageModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "MessageModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'mine'),
            'Required key "MessageModel[mine]" is missing from JSON.');
        assert(json[r'mine'] != null,
            'Required key "MessageModel[mine]" has a null value in JSON.');
        assert(json.containsKey(r'seq'),
            'Required key "MessageModel[seq]" is missing from JSON.');
        assert(json[r'seq'] != null,
            'Required key "MessageModel[seq]" has a null value in JSON.');
        assert(json.containsKey(r'text'),
            'Required key "MessageModel[text]" is missing from JSON.');
        return true;
      }());

      return MessageModel(
        card: MessageCardModel.fromJson(json[r'card']),
        clientId: mapValueOfType<String>(json, r'clientId'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        id: mapValueOfType<String>(json, r'id')!,
        kind: MessageKind.fromJson(json[r'kind'])!,
        mine: mapValueOfType<bool>(json, r'mine')!,
        seq: mapValueOfType<int>(json, r'seq')!,
        text: mapValueOfType<String>(json, r'text'),
      );
    }
    return null;
  }

  static List<MessageModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MessageModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MessageModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MessageModel> mapFromJson(dynamic json) {
    final map = <String, MessageModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MessageModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MessageModel-objects as value to a dart map
  static Map<String, List<MessageModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MessageModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MessageModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'card',
    'clientId',
    'createdAt',
    'id',
    'kind',
    'mine',
    'seq',
    'text',
  };
}
