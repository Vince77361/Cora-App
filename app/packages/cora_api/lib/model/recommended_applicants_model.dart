//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RecommendedApplicantsModel {
  /// Returns a new [RecommendedApplicantsModel] instance.
  RecommendedApplicantsModel({
    this.items = const [],
    required this.totalNew,
  });

  /// 점수 높은 순 최대 3명. 추천에서 넘긴 지원은 뺀다.
  List<RecommendedApplicantModel> items;

  /// 지원 중인 새 지원자 수(추천에서 넘긴 사람도 센다).
  int totalNew;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendedApplicantsModel &&
          _deepEquality.equals(other.items, items) &&
          other.totalNew == totalNew;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (items.hashCode) + (totalNew.hashCode);

  @override
  String toString() =>
      'RecommendedApplicantsModel[items=$items, totalNew=$totalNew]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'items'] = this.items;
    json[r'totalNew'] = this.totalNew;
    return json;
  }

  /// Returns a new [RecommendedApplicantsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RecommendedApplicantsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'),
            'Required key "RecommendedApplicantsModel[items]" is missing from JSON.');
        assert(json[r'items'] != null,
            'Required key "RecommendedApplicantsModel[items]" has a null value in JSON.');
        assert(json.containsKey(r'totalNew'),
            'Required key "RecommendedApplicantsModel[totalNew]" is missing from JSON.');
        assert(json[r'totalNew'] != null,
            'Required key "RecommendedApplicantsModel[totalNew]" has a null value in JSON.');
        return true;
      }());

      return RecommendedApplicantsModel(
        items: RecommendedApplicantModel.listFromJson(json[r'items']),
        totalNew: mapValueOfType<int>(json, r'totalNew')!,
      );
    }
    return null;
  }

  static List<RecommendedApplicantsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RecommendedApplicantsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RecommendedApplicantsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RecommendedApplicantsModel> mapFromJson(dynamic json) {
    final map = <String, RecommendedApplicantsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RecommendedApplicantsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RecommendedApplicantsModel-objects as value to a dart map
  static Map<String, List<RecommendedApplicantsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RecommendedApplicantsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RecommendedApplicantsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'totalNew',
  };
}
