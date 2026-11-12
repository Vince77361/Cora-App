//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class NotificationSettingsModel {
  /// Returns a new [NotificationSettingsModel] instance.
  NotificationSettingsModel({
    required this.enabledCount,
    required this.messages,
    required this.mutualInterest,
    required this.offers,
    required this.quietHours,
    required this.recommendations,
    required this.settlement,
  });

  /// 다섯 스위치 가운데 켜진 수(E4의 \"{n}개 켜짐\").
  num enabledCount;

  /// 대화 메시지.
  bool messages;

  /// 서로 관심.
  bool mutualInterest;

  /// 새 오퍼와 제안.
  bool offers;

  QuietHours quietHours;

  /// 추천 소식. 처음 값은 꺼짐.
  bool recommendations;

  /// 정산(지급 예정, 지급 완료).
  bool settlement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsModel &&
          other.enabledCount == enabledCount &&
          other.messages == messages &&
          other.mutualInterest == mutualInterest &&
          other.offers == offers &&
          other.quietHours == quietHours &&
          other.recommendations == recommendations &&
          other.settlement == settlement;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabledCount.hashCode) +
      (messages.hashCode) +
      (mutualInterest.hashCode) +
      (offers.hashCode) +
      (quietHours.hashCode) +
      (recommendations.hashCode) +
      (settlement.hashCode);

  @override
  String toString() =>
      'NotificationSettingsModel[enabledCount=$enabledCount, messages=$messages, mutualInterest=$mutualInterest, offers=$offers, quietHours=$quietHours, recommendations=$recommendations, settlement=$settlement]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabledCount'] = this.enabledCount;
    json[r'messages'] = this.messages;
    json[r'mutualInterest'] = this.mutualInterest;
    json[r'offers'] = this.offers;
    json[r'quietHours'] = this.quietHours;
    json[r'recommendations'] = this.recommendations;
    json[r'settlement'] = this.settlement;
    return json;
  }

  /// Returns a new [NotificationSettingsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationSettingsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'enabledCount'),
            'Required key "NotificationSettingsModel[enabledCount]" is missing from JSON.');
        assert(json[r'enabledCount'] != null,
            'Required key "NotificationSettingsModel[enabledCount]" has a null value in JSON.');
        assert(json.containsKey(r'messages'),
            'Required key "NotificationSettingsModel[messages]" is missing from JSON.');
        assert(json[r'messages'] != null,
            'Required key "NotificationSettingsModel[messages]" has a null value in JSON.');
        assert(json.containsKey(r'mutualInterest'),
            'Required key "NotificationSettingsModel[mutualInterest]" is missing from JSON.');
        assert(json[r'mutualInterest'] != null,
            'Required key "NotificationSettingsModel[mutualInterest]" has a null value in JSON.');
        assert(json.containsKey(r'offers'),
            'Required key "NotificationSettingsModel[offers]" is missing from JSON.');
        assert(json[r'offers'] != null,
            'Required key "NotificationSettingsModel[offers]" has a null value in JSON.');
        assert(json.containsKey(r'quietHours'),
            'Required key "NotificationSettingsModel[quietHours]" is missing from JSON.');
        assert(json[r'quietHours'] != null,
            'Required key "NotificationSettingsModel[quietHours]" has a null value in JSON.');
        assert(json.containsKey(r'recommendations'),
            'Required key "NotificationSettingsModel[recommendations]" is missing from JSON.');
        assert(json[r'recommendations'] != null,
            'Required key "NotificationSettingsModel[recommendations]" has a null value in JSON.');
        assert(json.containsKey(r'settlement'),
            'Required key "NotificationSettingsModel[settlement]" is missing from JSON.');
        assert(json[r'settlement'] != null,
            'Required key "NotificationSettingsModel[settlement]" has a null value in JSON.');
        return true;
      }());

      return NotificationSettingsModel(
        enabledCount: num.parse('${json[r'enabledCount']}'),
        messages: mapValueOfType<bool>(json, r'messages')!,
        mutualInterest: mapValueOfType<bool>(json, r'mutualInterest')!,
        offers: mapValueOfType<bool>(json, r'offers')!,
        quietHours: QuietHours.fromJson(json[r'quietHours'])!,
        recommendations: mapValueOfType<bool>(json, r'recommendations')!,
        settlement: mapValueOfType<bool>(json, r'settlement')!,
      );
    }
    return null;
  }

  static List<NotificationSettingsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationSettingsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationSettingsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationSettingsModel> mapFromJson(dynamic json) {
    final map = <String, NotificationSettingsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationSettingsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationSettingsModel-objects as value to a dart map
  static Map<String, List<NotificationSettingsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<NotificationSettingsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationSettingsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabledCount',
    'messages',
    'mutualInterest',
    'offers',
    'quietHours',
    'recommendations',
    'settlement',
  };
}
