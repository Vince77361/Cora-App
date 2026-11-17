//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ConversationSummaryModel {
  /// Returns a new [ConversationSummaryModel] instance.
  ConversationSummaryModel({
    required this.contextLabel,
    required this.counterpart,
    required this.id,
    required this.kind,
    required this.lastMessage,
    required this.muted,
    required this.section,
    required this.status,
    required this.unreadCount,
  });

  /// 캠페인 한 줄 또는 가게 이름.
  String contextLabel;

  ConversationCounterpartModel counterpart;

  String id;

  CollaborationKind kind;

  ConversationLastMessageModel? lastMessage;

  /// 이 방의 알림을 꺼 두었으면 true.
  bool muted;

  /// REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL.
  ConversationSection section;

  ConversationStatus status;

  /// 내 읽은 번호 뒤에 상대나 안내로 온 메시지의 수.
  int unreadCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSummaryModel &&
          other.contextLabel == contextLabel &&
          other.counterpart == counterpart &&
          other.id == id &&
          other.kind == kind &&
          other.lastMessage == lastMessage &&
          other.muted == muted &&
          other.section == section &&
          other.status == status &&
          other.unreadCount == unreadCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contextLabel.hashCode) +
      (counterpart.hashCode) +
      (id.hashCode) +
      (kind.hashCode) +
      (lastMessage == null ? 0 : lastMessage!.hashCode) +
      (muted.hashCode) +
      (section.hashCode) +
      (status.hashCode) +
      (unreadCount.hashCode);

  @override
  String toString() =>
      'ConversationSummaryModel[contextLabel=$contextLabel, counterpart=$counterpart, id=$id, kind=$kind, lastMessage=$lastMessage, muted=$muted, section=$section, status=$status, unreadCount=$unreadCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'contextLabel'] = this.contextLabel;
    json[r'counterpart'] = this.counterpart;
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    if (this.lastMessage != null) {
      json[r'lastMessage'] = this.lastMessage;
    } else {
      json[r'lastMessage'] = null;
    }
    json[r'muted'] = this.muted;
    json[r'section'] = this.section;
    json[r'status'] = this.status;
    json[r'unreadCount'] = this.unreadCount;
    return json;
  }

  /// Returns a new [ConversationSummaryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConversationSummaryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contextLabel'),
            'Required key "ConversationSummaryModel[contextLabel]" is missing from JSON.');
        assert(json[r'contextLabel'] != null,
            'Required key "ConversationSummaryModel[contextLabel]" has a null value in JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "ConversationSummaryModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "ConversationSummaryModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "ConversationSummaryModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ConversationSummaryModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "ConversationSummaryModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "ConversationSummaryModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'lastMessage'),
            'Required key "ConversationSummaryModel[lastMessage]" is missing from JSON.');
        assert(json.containsKey(r'muted'),
            'Required key "ConversationSummaryModel[muted]" is missing from JSON.');
        assert(json[r'muted'] != null,
            'Required key "ConversationSummaryModel[muted]" has a null value in JSON.');
        assert(json.containsKey(r'section'),
            'Required key "ConversationSummaryModel[section]" is missing from JSON.');
        assert(json[r'section'] != null,
            'Required key "ConversationSummaryModel[section]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ConversationSummaryModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ConversationSummaryModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'unreadCount'),
            'Required key "ConversationSummaryModel[unreadCount]" is missing from JSON.');
        assert(json[r'unreadCount'] != null,
            'Required key "ConversationSummaryModel[unreadCount]" has a null value in JSON.');
        return true;
      }());

      return ConversationSummaryModel(
        contextLabel: mapValueOfType<String>(json, r'contextLabel')!,
        counterpart:
            ConversationCounterpartModel.fromJson(json[r'counterpart'])!,
        id: mapValueOfType<String>(json, r'id')!,
        kind: CollaborationKind.fromJson(json[r'kind'])!,
        lastMessage:
            ConversationLastMessageModel.fromJson(json[r'lastMessage']),
        muted: mapValueOfType<bool>(json, r'muted')!,
        section: ConversationSection.fromJson(json[r'section'])!,
        status: ConversationStatus.fromJson(json[r'status'])!,
        unreadCount: mapValueOfType<int>(json, r'unreadCount')!,
      );
    }
    return null;
  }

  static List<ConversationSummaryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConversationSummaryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConversationSummaryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConversationSummaryModel> mapFromJson(dynamic json) {
    final map = <String, ConversationSummaryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConversationSummaryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConversationSummaryModel-objects as value to a dart map
  static Map<String, List<ConversationSummaryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ConversationSummaryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConversationSummaryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contextLabel',
    'counterpart',
    'id',
    'kind',
    'lastMessage',
    'muted',
    'section',
    'status',
    'unreadCount',
  };
}
