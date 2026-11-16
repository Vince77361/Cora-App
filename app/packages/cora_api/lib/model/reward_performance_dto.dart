//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RewardPerformanceDto {
  /// Returns a new [RewardPerformanceDto] instance.
  RewardPerformanceDto({
    required this.cap,
    required this.ratePer1000,
  });

  /// 조회수 수당 상한(원).
  int cap;

  /// 조회수 단가(1,000회당 원). 500원 단위.
  int ratePer1000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardPerformanceDto &&
          other.cap == cap &&
          other.ratePer1000 == ratePer1000;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cap.hashCode) + (ratePer1000.hashCode);

  @override
  String toString() =>
      'RewardPerformanceDto[cap=$cap, ratePer1000=$ratePer1000]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cap'] = this.cap;
    json[r'ratePer1000'] = this.ratePer1000;
    return json;
  }

  /// Returns a new [RewardPerformanceDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RewardPerformanceDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cap'),
            'Required key "RewardPerformanceDto[cap]" is missing from JSON.');
        assert(json[r'cap'] != null,
            'Required key "RewardPerformanceDto[cap]" has a null value in JSON.');
        assert(json.containsKey(r'ratePer1000'),
            'Required key "RewardPerformanceDto[ratePer1000]" is missing from JSON.');
        assert(json[r'ratePer1000'] != null,
            'Required key "RewardPerformanceDto[ratePer1000]" has a null value in JSON.');
        return true;
      }());

      return RewardPerformanceDto(
        cap: mapValueOfType<int>(json, r'cap')!,
        ratePer1000: mapValueOfType<int>(json, r'ratePer1000')!,
      );
    }
    return null;
  }

  static List<RewardPerformanceDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RewardPerformanceDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RewardPerformanceDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RewardPerformanceDto> mapFromJson(dynamic json) {
    final map = <String, RewardPerformanceDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RewardPerformanceDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RewardPerformanceDto-objects as value to a dart map
  static Map<String, List<RewardPerformanceDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RewardPerformanceDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RewardPerformanceDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cap',
    'ratePer1000',
  };
}
