//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorSummaryModel {
  /// Returns a new [CreatorSummaryModel] instance.
  CreatorSummaryModel({
    required this.contentFocus,
    required this.displayName,
    required this.photoUrl,
    required this.regionSido,
    required this.regionSigungu,
    required this.userId,
  });

  String? contentFocus;

  String displayName;

  String? photoUrl;

  String regionSido;

  String? regionSigungu;

  String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorSummaryModel &&
          other.contentFocus == contentFocus &&
          other.displayName == displayName &&
          other.photoUrl == photoUrl &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu &&
          other.userId == userId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (contentFocus == null ? 0 : contentFocus!.hashCode) +
      (displayName.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (regionSido.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode) +
      (userId.hashCode);

  @override
  String toString() =>
      'CreatorSummaryModel[contentFocus=$contentFocus, displayName=$displayName, photoUrl=$photoUrl, regionSido=$regionSido, regionSigungu=$regionSigungu, userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentFocus != null) {
      json[r'contentFocus'] = this.contentFocus;
    } else {
      json[r'contentFocus'] = null;
    }
    json[r'displayName'] = this.displayName;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'regionSido'] = this.regionSido;
    if (this.regionSigungu != null) {
      json[r'regionSigungu'] = this.regionSigungu;
    } else {
      json[r'regionSigungu'] = null;
    }
    json[r'userId'] = this.userId;
    return json;
  }

  /// Returns a new [CreatorSummaryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorSummaryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'contentFocus'),
            'Required key "CreatorSummaryModel[contentFocus]" is missing from JSON.');
        assert(json.containsKey(r'displayName'),
            'Required key "CreatorSummaryModel[displayName]" is missing from JSON.');
        assert(json[r'displayName'] != null,
            'Required key "CreatorSummaryModel[displayName]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CreatorSummaryModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "CreatorSummaryModel[regionSido]" is missing from JSON.');
        assert(json[r'regionSido'] != null,
            'Required key "CreatorSummaryModel[regionSido]" has a null value in JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "CreatorSummaryModel[regionSigungu]" is missing from JSON.');
        assert(json.containsKey(r'userId'),
            'Required key "CreatorSummaryModel[userId]" is missing from JSON.');
        assert(json[r'userId'] != null,
            'Required key "CreatorSummaryModel[userId]" has a null value in JSON.');
        return true;
      }());

      return CreatorSummaryModel(
        contentFocus: mapValueOfType<String>(json, r'contentFocus'),
        displayName: mapValueOfType<String>(json, r'displayName')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        regionSido: mapValueOfType<String>(json, r'regionSido')!,
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<CreatorSummaryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorSummaryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorSummaryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorSummaryModel> mapFromJson(dynamic json) {
    final map = <String, CreatorSummaryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorSummaryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorSummaryModel-objects as value to a dart map
  static Map<String, List<CreatorSummaryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorSummaryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorSummaryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contentFocus',
    'displayName',
    'photoUrl',
    'regionSido',
    'regionSigungu',
    'userId',
  };
}
