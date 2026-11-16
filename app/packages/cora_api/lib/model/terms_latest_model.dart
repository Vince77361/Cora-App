//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TermsLatestModel {
  /// Returns a new [TermsLatestModel] instance.
  TermsLatestModel({
    this.fields = const [],
    required this.followers,
    required this.mine,
    required this.myTurn,
    required this.needsInstagram,
    required this.notice,
    this.reasons = const [],
    required this.terms,
    required this.trialDays,
  });

  /// 크리에이터가 협업 원칙에서 고른 분야의 이름표(고른 순서). 원칙이 없으면 빈 배열.
  List<String> fields;

  /// 크리에이터가 연동한 인스타그램의 팔로워 수. 연동이 없으면 null.
  int? followers;

  /// 최신 판본을 내가 냈다.
  bool mine;

  /// 최신 판본을 내가 아직 확인하지 않았다.
  bool myTurn;

  /// 내가 크리에이터이고, 성과 추가가 켜져 있고, 형식이 릴스나 카드뉴스이고, 인스타그램이 연동돼 있지 않다.
  bool needsInstagram;

  /// 크리에이터의 협업 원칙에서 만든 안내 줄. 해당하는 것이 없으면 null.
  String? notice;

  /// 크리에이터의 협업 원칙과 캠페인이 겹치는 규칙.
  List<MatchReason> reasons;

  TermsVersionModel terms;

  /// 캠페인의 제품 사용 기간.
  ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermsLatestModel &&
          _deepEquality.equals(other.fields, fields) &&
          other.followers == followers &&
          other.mine == mine &&
          other.myTurn == myTurn &&
          other.needsInstagram == needsInstagram &&
          other.notice == notice &&
          _deepEquality.equals(other.reasons, reasons) &&
          other.terms == terms &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (fields.hashCode) +
      (followers == null ? 0 : followers!.hashCode) +
      (mine.hashCode) +
      (myTurn.hashCode) +
      (needsInstagram.hashCode) +
      (notice == null ? 0 : notice!.hashCode) +
      (reasons.hashCode) +
      (terms.hashCode) +
      (trialDays.hashCode);

  @override
  String toString() =>
      'TermsLatestModel[fields=$fields, followers=$followers, mine=$mine, myTurn=$myTurn, needsInstagram=$needsInstagram, notice=$notice, reasons=$reasons, terms=$terms, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'fields'] = this.fields;
    if (this.followers != null) {
      json[r'followers'] = this.followers;
    } else {
      json[r'followers'] = null;
    }
    json[r'mine'] = this.mine;
    json[r'myTurn'] = this.myTurn;
    json[r'needsInstagram'] = this.needsInstagram;
    if (this.notice != null) {
      json[r'notice'] = this.notice;
    } else {
      json[r'notice'] = null;
    }
    json[r'reasons'] = this.reasons;
    json[r'terms'] = this.terms;
    json[r'trialDays'] = this.trialDays;
    return json;
  }

  /// Returns a new [TermsLatestModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TermsLatestModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fields'),
            'Required key "TermsLatestModel[fields]" is missing from JSON.');
        assert(json[r'fields'] != null,
            'Required key "TermsLatestModel[fields]" has a null value in JSON.');
        assert(json.containsKey(r'followers'),
            'Required key "TermsLatestModel[followers]" is missing from JSON.');
        assert(json.containsKey(r'mine'),
            'Required key "TermsLatestModel[mine]" is missing from JSON.');
        assert(json[r'mine'] != null,
            'Required key "TermsLatestModel[mine]" has a null value in JSON.');
        assert(json.containsKey(r'myTurn'),
            'Required key "TermsLatestModel[myTurn]" is missing from JSON.');
        assert(json[r'myTurn'] != null,
            'Required key "TermsLatestModel[myTurn]" has a null value in JSON.');
        assert(json.containsKey(r'needsInstagram'),
            'Required key "TermsLatestModel[needsInstagram]" is missing from JSON.');
        assert(json[r'needsInstagram'] != null,
            'Required key "TermsLatestModel[needsInstagram]" has a null value in JSON.');
        assert(json.containsKey(r'notice'),
            'Required key "TermsLatestModel[notice]" is missing from JSON.');
        assert(json.containsKey(r'reasons'),
            'Required key "TermsLatestModel[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null,
            'Required key "TermsLatestModel[reasons]" has a null value in JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "TermsLatestModel[terms]" is missing from JSON.');
        assert(json[r'terms'] != null,
            'Required key "TermsLatestModel[terms]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "TermsLatestModel[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "TermsLatestModel[trialDays]" has a null value in JSON.');
        return true;
      }());

      return TermsLatestModel(
        fields: json[r'fields'] is Iterable
            ? (json[r'fields'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        followers: mapValueOfType<int>(json, r'followers'),
        mine: mapValueOfType<bool>(json, r'mine')!,
        myTurn: mapValueOfType<bool>(json, r'myTurn')!,
        needsInstagram: mapValueOfType<bool>(json, r'needsInstagram')!,
        notice: mapValueOfType<String>(json, r'notice'),
        reasons: MatchReason.listFromJson(json[r'reasons']),
        terms: TermsVersionModel.fromJson(json[r'terms'])!,
        trialDays: ProductTrialDays.fromJson(json[r'trialDays'])!,
      );
    }
    return null;
  }

  static List<TermsLatestModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsLatestModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsLatestModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TermsLatestModel> mapFromJson(dynamic json) {
    final map = <String, TermsLatestModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TermsLatestModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TermsLatestModel-objects as value to a dart map
  static Map<String, List<TermsLatestModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TermsLatestModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TermsLatestModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fields',
    'followers',
    'mine',
    'myTurn',
    'needsInstagram',
    'notice',
    'reasons',
    'terms',
    'trialDays',
  };
}
