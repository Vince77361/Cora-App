//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorConsentDto {
  /// Returns a new [CreatorConsentDto] instance.
  CreatorConsentDto({
    this.accepted = const [],
    required this.termsVersion,
  });

  /// 사용자가 확인한 세 줄. 서버가 만든 문구(myConsentTexts)와 정확히 같아야 한다.
  List<String> accepted;

  /// 동의하려는 판본 번호. 최신이 아니면 409 STALE_VERSION(latestVersion).
  int termsVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorConsentDto &&
          _deepEquality.equals(other.accepted, accepted) &&
          other.termsVersion == termsVersion;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accepted.hashCode) + (termsVersion.hashCode);

  @override
  String toString() =>
      'CreatorConsentDto[accepted=$accepted, termsVersion=$termsVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'accepted'] = this.accepted;
    json[r'termsVersion'] = this.termsVersion;
    return json;
  }

  /// Returns a new [CreatorConsentDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorConsentDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accepted'),
            'Required key "CreatorConsentDto[accepted]" is missing from JSON.');
        assert(json[r'accepted'] != null,
            'Required key "CreatorConsentDto[accepted]" has a null value in JSON.');
        assert(json.containsKey(r'termsVersion'),
            'Required key "CreatorConsentDto[termsVersion]" is missing from JSON.');
        assert(json[r'termsVersion'] != null,
            'Required key "CreatorConsentDto[termsVersion]" has a null value in JSON.');
        return true;
      }());

      return CreatorConsentDto(
        accepted: json[r'accepted'] is Iterable
            ? (json[r'accepted'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        termsVersion: mapValueOfType<int>(json, r'termsVersion')!,
      );
    }
    return null;
  }

  static List<CreatorConsentDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorConsentDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorConsentDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorConsentDto> mapFromJson(dynamic json) {
    final map = <String, CreatorConsentDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorConsentDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorConsentDto-objects as value to a dart map
  static Map<String, List<CreatorConsentDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorConsentDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorConsentDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accepted',
    'termsVersion',
  };
}
