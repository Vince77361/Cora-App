//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SendOfferDto {
  /// Returns a new [SendOfferDto] instance.
  SendOfferDto({
    required this.creatorId,
    required this.format,
    required this.reward,
    this.usageRights,
  });

  /// 오퍼를 받을 크리에이터의 ID.
  String creatorId;

  ContentFormat format;

  RewardInputDto reward;

  /// 없으면 가게의 기본 사용권.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UsageRights? usageRights;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendOfferDto &&
          other.creatorId == creatorId &&
          other.format == format &&
          other.reward == reward &&
          other.usageRights == usageRights;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creatorId.hashCode) +
      (format.hashCode) +
      (reward.hashCode) +
      (usageRights == null ? 0 : usageRights!.hashCode);

  @override
  String toString() =>
      'SendOfferDto[creatorId=$creatorId, format=$format, reward=$reward, usageRights=$usageRights]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'creatorId'] = this.creatorId;
    json[r'format'] = this.format;
    json[r'reward'] = this.reward;
    if (this.usageRights != null) {
      json[r'usageRights'] = this.usageRights;
    } else {
      json[r'usageRights'] = null;
    }
    return json;
  }

  /// Returns a new [SendOfferDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SendOfferDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creatorId'),
            'Required key "SendOfferDto[creatorId]" is missing from JSON.');
        assert(json[r'creatorId'] != null,
            'Required key "SendOfferDto[creatorId]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "SendOfferDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "SendOfferDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'reward'),
            'Required key "SendOfferDto[reward]" is missing from JSON.');
        assert(json[r'reward'] != null,
            'Required key "SendOfferDto[reward]" has a null value in JSON.');
        return true;
      }());

      return SendOfferDto(
        creatorId: mapValueOfType<String>(json, r'creatorId')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        reward: RewardInputDto.fromJson(json[r'reward'])!,
        usageRights: UsageRights.fromJson(json[r'usageRights']),
      );
    }
    return null;
  }

  static List<SendOfferDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SendOfferDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SendOfferDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SendOfferDto> mapFromJson(dynamic json) {
    final map = <String, SendOfferDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SendOfferDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SendOfferDto-objects as value to a dart map
  static Map<String, List<SendOfferDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SendOfferDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SendOfferDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'creatorId',
    'format',
    'reward',
  };
}
