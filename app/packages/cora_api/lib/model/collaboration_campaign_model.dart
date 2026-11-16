//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationCampaignModel {
  /// Returns a new [CollaborationCampaignModel] instance.
  CollaborationCampaignModel({
    required this.brandName,
    required this.headline,
    required this.id,
  });

  /// 캠페인을 낸 브랜드의 이름.
  String brandName;

  /// 캠페인 한 줄.
  String headline;

  String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationCampaignModel &&
          other.brandName == brandName &&
          other.headline == headline &&
          other.id == id;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandName.hashCode) + (headline.hashCode) + (id.hashCode);

  @override
  String toString() =>
      'CollaborationCampaignModel[brandName=$brandName, headline=$headline, id=$id]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'brandName'] = this.brandName;
    json[r'headline'] = this.headline;
    json[r'id'] = this.id;
    return json;
  }

  /// Returns a new [CollaborationCampaignModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollaborationCampaignModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandName'),
            'Required key "CollaborationCampaignModel[brandName]" is missing from JSON.');
        assert(json[r'brandName'] != null,
            'Required key "CollaborationCampaignModel[brandName]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CollaborationCampaignModel[headline]" is missing from JSON.');
        assert(json[r'headline'] != null,
            'Required key "CollaborationCampaignModel[headline]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "CollaborationCampaignModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CollaborationCampaignModel[id]" has a null value in JSON.');
        return true;
      }());

      return CollaborationCampaignModel(
        brandName: mapValueOfType<String>(json, r'brandName')!,
        headline: mapValueOfType<String>(json, r'headline')!,
        id: mapValueOfType<String>(json, r'id')!,
      );
    }
    return null;
  }

  static List<CollaborationCampaignModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationCampaignModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationCampaignModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollaborationCampaignModel> mapFromJson(dynamic json) {
    final map = <String, CollaborationCampaignModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollaborationCampaignModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollaborationCampaignModel-objects as value to a dart map
  static Map<String, List<CollaborationCampaignModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CollaborationCampaignModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollaborationCampaignModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandName',
    'headline',
    'id',
  };
}
