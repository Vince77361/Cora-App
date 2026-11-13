//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SetDefaultTermsDto {
  /// Returns a new [SetDefaultTermsDto] instance.
  SetDefaultTermsDto({
    required this.format,
    required this.reward,
    this.usageRights,
  });

  ContentFormat format;

  RewardInputDto reward;

  /// 없으면 STORE_REPOST_3M.
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
      other is SetDefaultTermsDto &&
          other.format == format &&
          other.reward == reward &&
          other.usageRights == usageRights;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) +
      (reward.hashCode) +
      (usageRights == null ? 0 : usageRights!.hashCode);

  @override
  String toString() =>
      'SetDefaultTermsDto[format=$format, reward=$reward, usageRights=$usageRights]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    json[r'reward'] = this.reward;
    if (this.usageRights != null) {
      json[r'usageRights'] = this.usageRights;
    } else {
      json[r'usageRights'] = null;
    }
    return json;
  }

  /// Returns a new [SetDefaultTermsDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SetDefaultTermsDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "SetDefaultTermsDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "SetDefaultTermsDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'reward'),
            'Required key "SetDefaultTermsDto[reward]" is missing from JSON.');
        assert(json[r'reward'] != null,
            'Required key "SetDefaultTermsDto[reward]" has a null value in JSON.');
        return true;
      }());

      return SetDefaultTermsDto(
        format: ContentFormat.fromJson(json[r'format'])!,
        reward: RewardInputDto.fromJson(json[r'reward'])!,
        usageRights: UsageRights.fromJson(json[r'usageRights']),
      );
    }
    return null;
  }

  static List<SetDefaultTermsDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SetDefaultTermsDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SetDefaultTermsDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SetDefaultTermsDto> mapFromJson(dynamic json) {
    final map = <String, SetDefaultTermsDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SetDefaultTermsDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SetDefaultTermsDto-objects as value to a dart map
  static Map<String, List<SetDefaultTermsDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SetDefaultTermsDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SetDefaultTermsDto.listFromJson(
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
