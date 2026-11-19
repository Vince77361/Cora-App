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
    required this.source_,
    required this.totalNew,
  });

  /// 점수 높은 순 최대 3명.
  List<RecommendedApplicantModel> items;

  /// APPLICANTS = 이 가게에 지원 중인 사람 중에서, ALL = 지원자가 없어 Cora 크리에이터 전체에서 뽑았다.
  RecommendedSource source_;

  /// 지원 중인 새 지원자 수. ALL이면 보여 줄 지원자가 없다(보통 0, 지원 줄은 있는데 프로필이 모두 지워졌으면 0보다 클 수 있다). 홈은 이 수가 아니라 source로 가른다.
  int totalNew;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendedApplicantsModel &&
          _deepEquality.equals(other.items, items) &&
          other.source_ == source_ &&
          other.totalNew == totalNew;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (items.hashCode) + (source_.hashCode) + (totalNew.hashCode);

  @override
  String toString() =>
      'RecommendedApplicantsModel[items=$items, source_=$source_, totalNew=$totalNew]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'items'] = this.items;
    json[r'source'] = this.source_;
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
        assert(json.containsKey(r'source'),
            'Required key "RecommendedApplicantsModel[source]" is missing from JSON.');
        assert(json[r'source'] != null,
            'Required key "RecommendedApplicantsModel[source]" has a null value in JSON.');
        assert(json.containsKey(r'totalNew'),
            'Required key "RecommendedApplicantsModel[totalNew]" is missing from JSON.');
        assert(json[r'totalNew'] != null,
            'Required key "RecommendedApplicantsModel[totalNew]" has a null value in JSON.');
        return true;
      }());

      return RecommendedApplicantsModel(
        items: RecommendedApplicantModel.listFromJson(json[r'items']),
        source_: RecommendedSource.fromJson(json[r'source'])!,
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
    'source',
    'totalNew',
  };
}
