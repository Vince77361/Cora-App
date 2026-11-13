//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ApplicantModel {
  /// Returns a new [ApplicantModel] instance.
  ApplicantModel({
    required this.applicationId,
    required this.appliedAt,
    required this.creator,
    required this.pitch,
  });

  String applicationId;

  /// 지원한 시각(ISO 8601).
  DateTime appliedAt;

  CreatorSummaryModel creator;

  /// 지원할 때 붙인 한 줄. 없으면 null.
  String? pitch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicantModel &&
          other.applicationId == applicationId &&
          other.appliedAt == appliedAt &&
          other.creator == creator &&
          other.pitch == pitch;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (applicationId.hashCode) +
      (appliedAt.hashCode) +
      (creator.hashCode) +
      (pitch == null ? 0 : pitch!.hashCode);

  @override
  String toString() =>
      'ApplicantModel[applicationId=$applicationId, appliedAt=$appliedAt, creator=$creator, pitch=$pitch]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'applicationId'] = this.applicationId;
    json[r'appliedAt'] = this.appliedAt.toUtc().toIso8601String();
    json[r'creator'] = this.creator;
    if (this.pitch != null) {
      json[r'pitch'] = this.pitch;
    } else {
      json[r'pitch'] = null;
    }
    return json;
  }

  /// Returns a new [ApplicantModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicantModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'applicationId'),
            'Required key "ApplicantModel[applicationId]" is missing from JSON.');
        assert(json[r'applicationId'] != null,
            'Required key "ApplicantModel[applicationId]" has a null value in JSON.');
        assert(json.containsKey(r'appliedAt'),
            'Required key "ApplicantModel[appliedAt]" is missing from JSON.');
        assert(json[r'appliedAt'] != null,
            'Required key "ApplicantModel[appliedAt]" has a null value in JSON.');
        assert(json.containsKey(r'creator'),
            'Required key "ApplicantModel[creator]" is missing from JSON.');
        assert(json[r'creator'] != null,
            'Required key "ApplicantModel[creator]" has a null value in JSON.');
        assert(json.containsKey(r'pitch'),
            'Required key "ApplicantModel[pitch]" is missing from JSON.');
        return true;
      }());

      return ApplicantModel(
        applicationId: mapValueOfType<String>(json, r'applicationId')!,
        appliedAt: mapDateTime(json, r'appliedAt', r'')!,
        creator: CreatorSummaryModel.fromJson(json[r'creator'])!,
        pitch: mapValueOfType<String>(json, r'pitch'),
      );
    }
    return null;
  }

  static List<ApplicantModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApplicantModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicantModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicantModel> mapFromJson(dynamic json) {
    final map = <String, ApplicantModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicantModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicantModel-objects as value to a dart map
  static Map<String, List<ApplicantModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ApplicantModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicantModel.listFromJson(
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
    'appliedAt',
    'creator',
    'pitch',
  };
}
