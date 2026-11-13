//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TrialInfoDto {
  /// Returns a new [TrialInfoDto] instance.
  TrialInfoDto({
    required this.endsOn,
    required this.monthlyFee,
    required this.postCount,
  });

  /// 계약 종료일(한국 날짜, YYYY-MM-DD).
  String endsOn;

  /// 월 계약 금액(원).
  ///
  /// Minimum value: 1
  /// Maximum value: 100000000
  num monthlyFee;

  /// 석 달 동안 받은 글 수.
  ///
  /// Minimum value: 1
  /// Maximum value: 1000
  num postCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrialInfoDto &&
          other.endsOn == endsOn &&
          other.monthlyFee == monthlyFee &&
          other.postCount == postCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (endsOn.hashCode) + (monthlyFee.hashCode) + (postCount.hashCode);

  @override
  String toString() =>
      'TrialInfoDto[endsOn=$endsOn, monthlyFee=$monthlyFee, postCount=$postCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'endsOn'] = this.endsOn;
    json[r'monthlyFee'] = this.monthlyFee;
    json[r'postCount'] = this.postCount;
    return json;
  }

  /// Returns a new [TrialInfoDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrialInfoDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'endsOn'),
            'Required key "TrialInfoDto[endsOn]" is missing from JSON.');
        assert(json[r'endsOn'] != null,
            'Required key "TrialInfoDto[endsOn]" has a null value in JSON.');
        assert(json.containsKey(r'monthlyFee'),
            'Required key "TrialInfoDto[monthlyFee]" is missing from JSON.');
        assert(json[r'monthlyFee'] != null,
            'Required key "TrialInfoDto[monthlyFee]" has a null value in JSON.');
        assert(json.containsKey(r'postCount'),
            'Required key "TrialInfoDto[postCount]" is missing from JSON.');
        assert(json[r'postCount'] != null,
            'Required key "TrialInfoDto[postCount]" has a null value in JSON.');
        return true;
      }());

      return TrialInfoDto(
        endsOn: mapValueOfType<String>(json, r'endsOn')!,
        monthlyFee: num.parse('${json[r'monthlyFee']}'),
        postCount: num.parse('${json[r'postCount']}'),
      );
    }
    return null;
  }

  static List<TrialInfoDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TrialInfoDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrialInfoDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrialInfoDto> mapFromJson(dynamic json) {
    final map = <String, TrialInfoDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrialInfoDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrialInfoDto-objects as value to a dart map
  static Map<String, List<TrialInfoDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TrialInfoDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrialInfoDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'endsOn',
    'monthlyFee',
    'postCount',
  };
}
