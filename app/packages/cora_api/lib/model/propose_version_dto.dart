//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposeVersionDto {
  /// Returns a new [ProposeVersionDto] instance.
  ProposeVersionDto({
    required this.format,
    this.idea,
    this.principles = const [],
    required this.reward,
    this.seriesId,
    this.usageRights,
  });

  ContentFormat format;

  /// 내 방식의 한 줄 설명. 크리에이터만 쓴다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? idea;

  /// 내가 지키는 원칙. 최대 3개, 각 10자까지. 크리에이터만 쓴다.
  List<String> principles;

  RewardInputDto reward;

  /// 내 시리즈의 id. 이름·형식·설명이 판본에 사본으로 들어간다. 크리에이터만 쓴다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? seriesId;

  /// 없으면 앞 판본의 사용권.
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
      other is ProposeVersionDto &&
          other.format == format &&
          other.idea == idea &&
          _deepEquality.equals(other.principles, principles) &&
          other.reward == reward &&
          other.seriesId == seriesId &&
          other.usageRights == usageRights;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) +
      (idea == null ? 0 : idea!.hashCode) +
      (principles.hashCode) +
      (reward.hashCode) +
      (seriesId == null ? 0 : seriesId!.hashCode) +
      (usageRights == null ? 0 : usageRights!.hashCode);

  @override
  String toString() =>
      'ProposeVersionDto[format=$format, idea=$idea, principles=$principles, reward=$reward, seriesId=$seriesId, usageRights=$usageRights]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    if (this.idea != null) {
      json[r'idea'] = this.idea;
    } else {
      json[r'idea'] = null;
    }
    json[r'principles'] = this.principles;
    json[r'reward'] = this.reward;
    if (this.seriesId != null) {
      json[r'seriesId'] = this.seriesId;
    } else {
      json[r'seriesId'] = null;
    }
    if (this.usageRights != null) {
      json[r'usageRights'] = this.usageRights;
    } else {
      json[r'usageRights'] = null;
    }
    return json;
  }

  /// Returns a new [ProposeVersionDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposeVersionDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "ProposeVersionDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "ProposeVersionDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'reward'),
            'Required key "ProposeVersionDto[reward]" is missing from JSON.');
        assert(json[r'reward'] != null,
            'Required key "ProposeVersionDto[reward]" has a null value in JSON.');
        return true;
      }());

      return ProposeVersionDto(
        format: ContentFormat.fromJson(json[r'format'])!,
        idea: mapValueOfType<String>(json, r'idea'),
        principles: json[r'principles'] is Iterable
            ? (json[r'principles'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        reward: RewardInputDto.fromJson(json[r'reward'])!,
        seriesId: mapValueOfType<String>(json, r'seriesId'),
        usageRights: UsageRights.fromJson(json[r'usageRights']),
      );
    }
    return null;
  }

  static List<ProposeVersionDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposeVersionDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposeVersionDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposeVersionDto> mapFromJson(dynamic json) {
    final map = <String, ProposeVersionDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposeVersionDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposeVersionDto-objects as value to a dart map
  static Map<String, List<ProposeVersionDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposeVersionDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposeVersionDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'format',
    'reward',
  };
}
