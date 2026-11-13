//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RecommendedApplicantModel {
  /// Returns a new [RecommendedApplicantModel] instance.
  RecommendedApplicantModel({
    required this.applicationId,
    required this.creator,
    required this.pitch,
    this.reasons = const [],
  });

  String applicationId;

  CreatorSummaryModel creator;

  /// 지원할 때 붙인 한 줄. 없으면 null.
  String? pitch;

  /// 추천 이유. 점수에 쓴 사실만 담는다.
  List<String> reasons;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendedApplicantModel &&
          other.applicationId == applicationId &&
          other.creator == creator &&
          other.pitch == pitch &&
          _deepEquality.equals(other.reasons, reasons);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (applicationId.hashCode) +
      (creator.hashCode) +
      (pitch == null ? 0 : pitch!.hashCode) +
      (reasons.hashCode);

  @override
  String toString() =>
      'RecommendedApplicantModel[applicationId=$applicationId, creator=$creator, pitch=$pitch, reasons=$reasons]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'applicationId'] = this.applicationId;
    json[r'creator'] = this.creator;
    if (this.pitch != null) {
      json[r'pitch'] = this.pitch;
    } else {
      json[r'pitch'] = null;
    }
    json[r'reasons'] = this.reasons;
    return json;
  }

  /// Returns a new [RecommendedApplicantModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecommendedApplicantModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'applicationId'),
            'Required key "RecommendedApplicantModel[applicationId]" is missing from JSON.');
        assert(json[r'applicationId'] != null,
            'Required key "RecommendedApplicantModel[applicationId]" has a null value in JSON.');
        assert(json.containsKey(r'creator'),
            'Required key "RecommendedApplicantModel[creator]" is missing from JSON.');
        assert(json[r'creator'] != null,
            'Required key "RecommendedApplicantModel[creator]" has a null value in JSON.');
        assert(json.containsKey(r'pitch'),
            'Required key "RecommendedApplicantModel[pitch]" is missing from JSON.');
        assert(json.containsKey(r'reasons'),
            'Required key "RecommendedApplicantModel[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null,
            'Required key "RecommendedApplicantModel[reasons]" has a null value in JSON.');
        return true;
      }());

      return RecommendedApplicantModel(
        applicationId: mapValueOfType<String>(json, r'applicationId')!,
        creator: CreatorSummaryModel.fromJson(json[r'creator'])!,
        pitch: mapValueOfType<String>(json, r'pitch'),
        reasons: json[r'reasons'] is Iterable
            ? (json[r'reasons'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<RecommendedApplicantModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RecommendedApplicantModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecommendedApplicantModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecommendedApplicantModel> mapFromJson(dynamic json) {
    final map = <String, RecommendedApplicantModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecommendedApplicantModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecommendedApplicantModel-objects as value to a dart map
  static Map<String, List<RecommendedApplicantModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RecommendedApplicantModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecommendedApplicantModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'applicationId',
    'creator',
    'pitch',
    'reasons',
  };
}
