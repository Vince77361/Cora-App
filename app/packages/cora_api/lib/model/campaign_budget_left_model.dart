//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CampaignBudgetLeftModel {
  /// Returns a new [CampaignBudgetLeftModel] instance.
  CampaignBudgetLeftModel({
    required this.left,
    required this.over,
  });

  /// 남은 캠페인 예산(원). 음수가 되지 않고 0에서 멈춘다.
  int left;

  /// 확보액이 예산을 넘은 금액(원). 넘지 않았으면 0.
  int over;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignBudgetLeftModel &&
          other.left == left &&
          other.over == over;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (left.hashCode) + (over.hashCode);

  @override
  String toString() => 'CampaignBudgetLeftModel[left=$left, over=$over]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'left'] = this.left;
    json[r'over'] = this.over;
    return json;
  }

  /// Returns a new [CampaignBudgetLeftModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CampaignBudgetLeftModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'left'),
            'Required key "CampaignBudgetLeftModel[left]" is missing from JSON.');
        assert(json[r'left'] != null,
            'Required key "CampaignBudgetLeftModel[left]" has a null value in JSON.');
        assert(json.containsKey(r'over'),
            'Required key "CampaignBudgetLeftModel[over]" is missing from JSON.');
        assert(json[r'over'] != null,
            'Required key "CampaignBudgetLeftModel[over]" has a null value in JSON.');
        return true;
      }());

      return CampaignBudgetLeftModel(
        left: mapValueOfType<int>(json, r'left')!,
        over: mapValueOfType<int>(json, r'over')!,
      );
    }
    return null;
  }

  static List<CampaignBudgetLeftModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignBudgetLeftModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignBudgetLeftModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CampaignBudgetLeftModel> mapFromJson(dynamic json) {
    final map = <String, CampaignBudgetLeftModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CampaignBudgetLeftModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CampaignBudgetLeftModel-objects as value to a dart map
  static Map<String, List<CampaignBudgetLeftModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CampaignBudgetLeftModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CampaignBudgetLeftModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'left',
    'over',
  };
}
