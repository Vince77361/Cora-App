//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PutDecisionDto {
  /// Returns a new [PutDecisionDto] instance.
  PutDecisionDto({
    required this.decision,
    this.note,
    this.proposal,
    required this.targetId,
    required this.targetKind,
  });

  SwipeDecisionKind decision;

  /// LIKE에 붙이는 글. 크리에이터는 40자(조건 버전의 제목), 브랜드는 100자(좋아한 점).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? note;

  /// 브랜드의 LIKE에만 붙인다(크리에이터가 보내면 400). 이미 LIKE인 결정에 다시 보내면 값만 덮어쓴다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  BrandProposalDto? proposal;

  /// 크리에이터(사용자) 또는 캠페인의 id.
  String targetId;

  /// 브랜드는 CREATOR만, 크리에이터는 CAMPAIGN만 보낸다.
  DecisionTargetKind targetKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutDecisionDto &&
          other.decision == decision &&
          other.note == note &&
          other.proposal == proposal &&
          other.targetId == targetId &&
          other.targetKind == targetKind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (decision.hashCode) +
      (note == null ? 0 : note!.hashCode) +
      (proposal == null ? 0 : proposal!.hashCode) +
      (targetId.hashCode) +
      (targetKind.hashCode);

  @override
  String toString() =>
      'PutDecisionDto[decision=$decision, note=$note, proposal=$proposal, targetId=$targetId, targetKind=$targetKind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'decision'] = this.decision;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    if (this.proposal != null) {
      json[r'proposal'] = this.proposal;
    } else {
      json[r'proposal'] = null;
    }
    json[r'targetId'] = this.targetId;
    json[r'targetKind'] = this.targetKind;
    return json;
  }

  /// Returns a new [PutDecisionDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PutDecisionDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'decision'),
            'Required key "PutDecisionDto[decision]" is missing from JSON.');
        assert(json[r'decision'] != null,
            'Required key "PutDecisionDto[decision]" has a null value in JSON.');
        assert(json.containsKey(r'targetId'),
            'Required key "PutDecisionDto[targetId]" is missing from JSON.');
        assert(json[r'targetId'] != null,
            'Required key "PutDecisionDto[targetId]" has a null value in JSON.');
        assert(json.containsKey(r'targetKind'),
            'Required key "PutDecisionDto[targetKind]" is missing from JSON.');
        assert(json[r'targetKind'] != null,
            'Required key "PutDecisionDto[targetKind]" has a null value in JSON.');
        return true;
      }());

      return PutDecisionDto(
        decision: SwipeDecisionKind.fromJson(json[r'decision'])!,
        note: mapValueOfType<String>(json, r'note'),
        proposal: BrandProposalDto.fromJson(json[r'proposal']),
        targetId: mapValueOfType<String>(json, r'targetId')!,
        targetKind: DecisionTargetKind.fromJson(json[r'targetKind'])!,
      );
    }
    return null;
  }

  static List<PutDecisionDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PutDecisionDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PutDecisionDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PutDecisionDto> mapFromJson(dynamic json) {
    final map = <String, PutDecisionDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PutDecisionDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PutDecisionDto-objects as value to a dart map
  static Map<String, List<PutDecisionDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PutDecisionDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PutDecisionDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'decision',
    'targetId',
    'targetKind',
  };
}
