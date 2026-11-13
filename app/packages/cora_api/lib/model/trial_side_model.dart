//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TrialSideModel {
  /// Returns a new [TrialSideModel] instance.
  TrialSideModel({
    required this.endsOn,
    required this.monthlyFee,
    required this.postCount,
    required this.spent,
  });

  /// 계약 종료일(한국 날짜, YYYY-MM-DD).
  String endsOn;

  /// 월 계약 금액(원).
  int monthlyFee;

  /// 석 달 동안 받은 글 수.
  int postCount;

  /// 석 달 동안 들어간 돈(원). 월 계약 금액 × 3.
  int spent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrialSideModel &&
          other.endsOn == endsOn &&
          other.monthlyFee == monthlyFee &&
          other.postCount == postCount &&
          other.spent == spent;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (endsOn.hashCode) +
      (monthlyFee.hashCode) +
      (postCount.hashCode) +
      (spent.hashCode);

  @override
  String toString() =>
      'TrialSideModel[endsOn=$endsOn, monthlyFee=$monthlyFee, postCount=$postCount, spent=$spent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'endsOn'] = this.endsOn;
    json[r'monthlyFee'] = this.monthlyFee;
    json[r'postCount'] = this.postCount;
    json[r'spent'] = this.spent;
    return json;
  }

  /// Returns a new [TrialSideModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrialSideModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'endsOn'),
            'Required key "TrialSideModel[endsOn]" is missing from JSON.');
        assert(json[r'endsOn'] != null,
            'Required key "TrialSideModel[endsOn]" has a null value in JSON.');
        assert(json.containsKey(r'monthlyFee'),
            'Required key "TrialSideModel[monthlyFee]" is missing from JSON.');
        assert(json[r'monthlyFee'] != null,
            'Required key "TrialSideModel[monthlyFee]" has a null value in JSON.');
        assert(json.containsKey(r'postCount'),
            'Required key "TrialSideModel[postCount]" is missing from JSON.');
        assert(json[r'postCount'] != null,
            'Required key "TrialSideModel[postCount]" has a null value in JSON.');
        assert(json.containsKey(r'spent'),
            'Required key "TrialSideModel[spent]" is missing from JSON.');
        assert(json[r'spent'] != null,
            'Required key "TrialSideModel[spent]" has a null value in JSON.');
        return true;
      }());

      return TrialSideModel(
        endsOn: mapValueOfType<String>(json, r'endsOn')!,
        monthlyFee: mapValueOfType<int>(json, r'monthlyFee')!,
        postCount: mapValueOfType<int>(json, r'postCount')!,
        spent: mapValueOfType<int>(json, r'spent')!,
      );
    }
    return null;
  }

  static List<TrialSideModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TrialSideModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrialSideModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrialSideModel> mapFromJson(dynamic json) {
    final map = <String, TrialSideModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrialSideModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrialSideModel-objects as value to a dart map
  static Map<String, List<TrialSideModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TrialSideModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrialSideModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'endsOn',
    'monthlyFee',
    'postCount',
    'spent',
  };
}
