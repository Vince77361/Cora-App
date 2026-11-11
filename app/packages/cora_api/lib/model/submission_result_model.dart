//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SubmissionResultModel {
  /// Returns a new [SubmissionResultModel] instance.
  SubmissionResultModel({
    required this.collaborationId,
    required this.stage,
  });

  String collaborationId;

  /// 제출 뒤의 단계. 조회수 보상이 있으면 COUNTING, 식사권만 있으면 SETTLED.
  CollaborationStage stage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmissionResultModel &&
          other.collaborationId == collaborationId &&
          other.stage == stage;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId.hashCode) + (stage.hashCode);

  @override
  String toString() =>
      'SubmissionResultModel[collaborationId=$collaborationId, stage=$stage]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'collaborationId'] = this.collaborationId;
    json[r'stage'] = this.stage;
    return json;
  }

  /// Returns a new [SubmissionResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubmissionResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "SubmissionResultModel[collaborationId]" is missing from JSON.');
        assert(json[r'collaborationId'] != null,
            'Required key "SubmissionResultModel[collaborationId]" has a null value in JSON.');
        assert(json.containsKey(r'stage'),
            'Required key "SubmissionResultModel[stage]" is missing from JSON.');
        assert(json[r'stage'] != null,
            'Required key "SubmissionResultModel[stage]" has a null value in JSON.');
        return true;
      }());

      return SubmissionResultModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId')!,
        stage: CollaborationStage.fromJson(json[r'stage'])!,
      );
    }
    return null;
  }

  static List<SubmissionResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SubmissionResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubmissionResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubmissionResultModel> mapFromJson(dynamic json) {
    final map = <String, SubmissionResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubmissionResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubmissionResultModel-objects as value to a dart map
  static Map<String, List<SubmissionResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SubmissionResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubmissionResultModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'collaborationId',
    'stage',
  };
}
