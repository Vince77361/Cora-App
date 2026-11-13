//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class DisputeViewReportDto {
  /// Returns a new [DisputeViewReportDto] instance.
  DisputeViewReportDto({
    required this.reason,
  });

  /// 이의 사유. 앞뒤 공백을 뺀 글자 수가 1~200자여야 한다.
  String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisputeViewReportDto && other.reason == reason;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (reason.hashCode);

  @override
  String toString() => 'DisputeViewReportDto[reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'reason'] = this.reason;
    return json;
  }

  /// Returns a new [DisputeViewReportDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DisputeViewReportDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reason'),
            'Required key "DisputeViewReportDto[reason]" is missing from JSON.');
        assert(json[r'reason'] != null,
            'Required key "DisputeViewReportDto[reason]" has a null value in JSON.');
        return true;
      }());

      return DisputeViewReportDto(
        reason: mapValueOfType<String>(json, r'reason')!,
      );
    }
    return null;
  }

  static List<DisputeViewReportDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DisputeViewReportDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DisputeViewReportDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DisputeViewReportDto> mapFromJson(dynamic json) {
    final map = <String, DisputeViewReportDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DisputeViewReportDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DisputeViewReportDto-objects as value to a dart map
  static Map<String, List<DisputeViewReportDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DisputeViewReportDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DisputeViewReportDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'reason',
  };
}
