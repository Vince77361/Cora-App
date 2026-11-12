//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpdateNotificationSettingsDto {
  /// Returns a new [UpdateNotificationSettingsDto] instance.
  UpdateNotificationSettingsDto({
    required this.messages,
    required this.mutualInterest,
    required this.offers,
    required this.quietHours,
    required this.recommendations,
    required this.settlement,
  });

  bool messages;

  bool mutualInterest;

  bool offers;

  QuietHours quietHours;

  bool recommendations;

  bool settlement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateNotificationSettingsDto &&
          other.messages == messages &&
          other.mutualInterest == mutualInterest &&
          other.offers == offers &&
          other.quietHours == quietHours &&
          other.recommendations == recommendations &&
          other.settlement == settlement;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (messages.hashCode) +
      (mutualInterest.hashCode) +
      (offers.hashCode) +
      (quietHours.hashCode) +
      (recommendations.hashCode) +
      (settlement.hashCode);

  @override
  String toString() =>
      'UpdateNotificationSettingsDto[messages=$messages, mutualInterest=$mutualInterest, offers=$offers, quietHours=$quietHours, recommendations=$recommendations, settlement=$settlement]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'messages'] = this.messages;
    json[r'mutualInterest'] = this.mutualInterest;
    json[r'offers'] = this.offers;
    json[r'quietHours'] = this.quietHours;
    json[r'recommendations'] = this.recommendations;
    json[r'settlement'] = this.settlement;
    return json;
  }

  /// Returns a new [UpdateNotificationSettingsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateNotificationSettingsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'messages'),
            'Required key "UpdateNotificationSettingsDto[messages]" is missing from JSON.');
        assert(json[r'messages'] != null,
            'Required key "UpdateNotificationSettingsDto[messages]" has a null value in JSON.');
        assert(json.containsKey(r'mutualInterest'),
            'Required key "UpdateNotificationSettingsDto[mutualInterest]" is missing from JSON.');
        assert(json[r'mutualInterest'] != null,
            'Required key "UpdateNotificationSettingsDto[mutualInterest]" has a null value in JSON.');
        assert(json.containsKey(r'offers'),
            'Required key "UpdateNotificationSettingsDto[offers]" is missing from JSON.');
        assert(json[r'offers'] != null,
            'Required key "UpdateNotificationSettingsDto[offers]" has a null value in JSON.');
        assert(json.containsKey(r'quietHours'),
            'Required key "UpdateNotificationSettingsDto[quietHours]" is missing from JSON.');
        assert(json[r'quietHours'] != null,
            'Required key "UpdateNotificationSettingsDto[quietHours]" has a null value in JSON.');
        assert(json.containsKey(r'recommendations'),
            'Required key "UpdateNotificationSettingsDto[recommendations]" is missing from JSON.');
        assert(json[r'recommendations'] != null,
            'Required key "UpdateNotificationSettingsDto[recommendations]" has a null value in JSON.');
        assert(json.containsKey(r'settlement'),
            'Required key "UpdateNotificationSettingsDto[settlement]" is missing from JSON.');
        assert(json[r'settlement'] != null,
            'Required key "UpdateNotificationSettingsDto[settlement]" has a null value in JSON.');
        return true;
      }());

      return UpdateNotificationSettingsDto(
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

  static List<UpdateNotificationSettingsDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateNotificationSettingsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateNotificationSettingsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateNotificationSettingsDto> mapFromJson(dynamic json) {
    final map = <String, UpdateNotificationSettingsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateNotificationSettingsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateNotificationSettingsDto-objects as value to a dart map
  static Map<String, List<UpdateNotificationSettingsDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateNotificationSettingsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateNotificationSettingsDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'messages',
    'mutualInterest',
    'offers',
    'quietHours',
    'recommendations',
    'settlement',
  };
}
