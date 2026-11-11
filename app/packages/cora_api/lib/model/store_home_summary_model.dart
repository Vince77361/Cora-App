//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreHomeSummaryModel {
  /// Returns a new [StoreHomeSummaryModel] instance.
  StoreHomeSummaryModel({
    required this.inProgress,
    required this.newApplications,
    required this.sentOffers,
  });

  /// 수락된 오퍼.
  int inProgress;

  /// 아직 오퍼를 보내지 않은 지원.
  int newApplications;

  /// 답을 기다리는 보낸 오퍼.
  int sentOffers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreHomeSummaryModel &&
          other.inProgress == inProgress &&
          other.newApplications == newApplications &&
          other.sentOffers == sentOffers;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (inProgress.hashCode) +
      (newApplications.hashCode) +
      (sentOffers.hashCode);

  @override
  String toString() =>
      'StoreHomeSummaryModel[inProgress=$inProgress, newApplications=$newApplications, sentOffers=$sentOffers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'inProgress'] = this.inProgress;
    json[r'newApplications'] = this.newApplications;
    json[r'sentOffers'] = this.sentOffers;
    return json;
  }

  /// Returns a new [StoreHomeSummaryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreHomeSummaryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'inProgress'),
            'Required key "StoreHomeSummaryModel[inProgress]" is missing from JSON.');
        assert(json[r'inProgress'] != null,
            'Required key "StoreHomeSummaryModel[inProgress]" has a null value in JSON.');
        assert(json.containsKey(r'newApplications'),
            'Required key "StoreHomeSummaryModel[newApplications]" is missing from JSON.');
        assert(json[r'newApplications'] != null,
            'Required key "StoreHomeSummaryModel[newApplications]" has a null value in JSON.');
        assert(json.containsKey(r'sentOffers'),
            'Required key "StoreHomeSummaryModel[sentOffers]" is missing from JSON.');
        assert(json[r'sentOffers'] != null,
            'Required key "StoreHomeSummaryModel[sentOffers]" has a null value in JSON.');
        return true;
      }());

      return StoreHomeSummaryModel(
        inProgress: mapValueOfType<int>(json, r'inProgress')!,
        newApplications: mapValueOfType<int>(json, r'newApplications')!,
        sentOffers: mapValueOfType<int>(json, r'sentOffers')!,
      );
    }
    return null;
  }

  static List<StoreHomeSummaryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreHomeSummaryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreHomeSummaryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreHomeSummaryModel> mapFromJson(dynamic json) {
    final map = <String, StoreHomeSummaryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreHomeSummaryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreHomeSummaryModel-objects as value to a dart map
  static Map<String, List<StoreHomeSummaryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreHomeSummaryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreHomeSummaryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'inProgress',
    'newApplications',
    'sentOffers',
  };
}
