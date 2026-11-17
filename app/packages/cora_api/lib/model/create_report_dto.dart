//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreateReportDto {
  /// Returns a new [CreateReportDto] instance.
  CreateReportDto({
    this.detail,
    required this.reason,
    required this.targetId,
    required this.targetKind,
  });

  /// 자세한 내용(선택, 500자까지).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? detail;

  /// SPAM 광고·스팸, ABUSE 부적절한 말, FRAUD 사기 의심, OTHER 기타.
  ReportReason reason;

  /// 사용자 또는 대화방의 id. 내 방이나 그 상대가 아니면 404다(형식이 틀려도 같다).
  String targetId;

  /// USER는 내가 참가한 방의 상대, CONVERSATION은 내가 참가한 방이다.
  ReportTargetKind targetKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateReportDto &&
          other.detail == detail &&
          other.reason == reason &&
          other.targetId == targetId &&
          other.targetKind == targetKind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (detail == null ? 0 : detail!.hashCode) +
      (reason.hashCode) +
      (targetId.hashCode) +
      (targetKind.hashCode);

  @override
  String toString() =>
      'CreateReportDto[detail=$detail, reason=$reason, targetId=$targetId, targetKind=$targetKind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.detail != null) {
      json[r'detail'] = this.detail;
    } else {
      json[r'detail'] = null;
    }
    json[r'reason'] = this.reason;
    json[r'targetId'] = this.targetId;
    json[r'targetKind'] = this.targetKind;
    return json;
  }

  /// Returns a new [CreateReportDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateReportDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'reason'),
            'Required key "CreateReportDto[reason]" is missing from JSON.');
        assert(json[r'reason'] != null,
            'Required key "CreateReportDto[reason]" has a null value in JSON.');
        assert(json.containsKey(r'targetId'),
            'Required key "CreateReportDto[targetId]" is missing from JSON.');
        assert(json[r'targetId'] != null,
            'Required key "CreateReportDto[targetId]" has a null value in JSON.');
        assert(json.containsKey(r'targetKind'),
            'Required key "CreateReportDto[targetKind]" is missing from JSON.');
        assert(json[r'targetKind'] != null,
            'Required key "CreateReportDto[targetKind]" has a null value in JSON.');
        return true;
      }());

      return CreateReportDto(
        detail: mapValueOfType<String>(json, r'detail'),
        reason: ReportReason.fromJson(json[r'reason'])!,
        targetId: mapValueOfType<String>(json, r'targetId')!,
        targetKind: ReportTargetKind.fromJson(json[r'targetKind'])!,
      );
    }
    return null;
  }

  static List<CreateReportDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateReportDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateReportDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateReportDto> mapFromJson(dynamic json) {
    final map = <String, CreateReportDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateReportDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateReportDto-objects as value to a dart map
  static Map<String, List<CreateReportDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateReportDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateReportDto.listFromJson(
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
    'targetId',
    'targetKind',
  };
}
