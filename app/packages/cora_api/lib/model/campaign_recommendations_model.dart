//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CampaignRecommendationsModel {
  /// Returns a new [CampaignRecommendationsModel] instance.
  CampaignRecommendationsModel({
    this.cards = const [],
    required this.day,
    required this.total,
  });

  List<CampaignListCardModel> cards;

  DateTime day;

  /// 오늘 목록의 전체 수(이미 결정한 카드 포함).
  int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignRecommendationsModel &&
          _deepEquality.equals(other.cards, cards) &&
          other.day == day &&
          other.total == total;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cards.hashCode) + (day.hashCode) + (total.hashCode);

  @override
  String toString() =>
      'CampaignRecommendationsModel[cards=$cards, day=$day, total=$total]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cards'] = this.cards;
    json[r'day'] = _dateFormatter.format(this.day);
    json[r'total'] = this.total;
    return json;
  }

  /// Returns a new [CampaignRecommendationsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CampaignRecommendationsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cards'),
            'Required key "CampaignRecommendationsModel[cards]" is missing from JSON.');
        assert(json[r'cards'] != null,
            'Required key "CampaignRecommendationsModel[cards]" has a null value in JSON.');
        assert(json.containsKey(r'day'),
            'Required key "CampaignRecommendationsModel[day]" is missing from JSON.');
        assert(json[r'day'] != null,
            'Required key "CampaignRecommendationsModel[day]" has a null value in JSON.');
        assert(json.containsKey(r'total'),
            'Required key "CampaignRecommendationsModel[total]" is missing from JSON.');
        assert(json[r'total'] != null,
            'Required key "CampaignRecommendationsModel[total]" has a null value in JSON.');
        return true;
      }());

      return CampaignRecommendationsModel(
        cards: CampaignListCardModel.listFromJson(json[r'cards']),
        day: mapDateTime(json, r'day', r'')!,
        total: mapValueOfType<int>(json, r'total')!,
      );
    }
    return null;
  }

  static List<CampaignRecommendationsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignRecommendationsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignRecommendationsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CampaignRecommendationsModel> mapFromJson(dynamic json) {
    final map = <String, CampaignRecommendationsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CampaignRecommendationsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CampaignRecommendationsModel-objects as value to a dart map
  static Map<String, List<CampaignRecommendationsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CampaignRecommendationsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CampaignRecommendationsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cards',
    'day',
    'total',
  };
}
