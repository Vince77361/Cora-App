//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class BrandProfileModel {
  /// Returns a new [BrandProfileModel] instance.
  BrandProfileModel({
    required this.industry,
    required this.name,
    required this.photoUrl,
    required this.tagline,
    required this.userId,
  });

  IndustryCategory industry;

  String name;

  String? photoUrl;

  String? tagline;

  String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandProfileModel &&
          other.industry == industry &&
          other.name == name &&
          other.photoUrl == photoUrl &&
          other.tagline == tagline &&
          other.userId == userId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (industry.hashCode) +
      (name.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (tagline == null ? 0 : tagline!.hashCode) +
      (userId.hashCode);

  @override
  String toString() =>
      'BrandProfileModel[industry=$industry, name=$name, photoUrl=$photoUrl, tagline=$tagline, userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'industry'] = this.industry;
    json[r'name'] = this.name;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    if (this.tagline != null) {
      json[r'tagline'] = this.tagline;
    } else {
      json[r'tagline'] = null;
    }
    json[r'userId'] = this.userId;
    return json;
  }

  /// Returns a new [BrandProfileModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BrandProfileModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'industry'),
            'Required key "BrandProfileModel[industry]" is missing from JSON.');
        assert(json[r'industry'] != null,
            'Required key "BrandProfileModel[industry]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "BrandProfileModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "BrandProfileModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "BrandProfileModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'tagline'),
            'Required key "BrandProfileModel[tagline]" is missing from JSON.');
        assert(json.containsKey(r'userId'),
            'Required key "BrandProfileModel[userId]" is missing from JSON.');
        assert(json[r'userId'] != null,
            'Required key "BrandProfileModel[userId]" has a null value in JSON.');
        return true;
      }());

      return BrandProfileModel(
        industry: IndustryCategory.fromJson(json[r'industry'])!,
        name: mapValueOfType<String>(json, r'name')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        tagline: mapValueOfType<String>(json, r'tagline'),
        userId: mapValueOfType<String>(json, r'userId')!,
      );
    }
    return null;
  }

  static List<BrandProfileModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BrandProfileModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BrandProfileModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BrandProfileModel> mapFromJson(dynamic json) {
    final map = <String, BrandProfileModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BrandProfileModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BrandProfileModel-objects as value to a dart map
  static Map<String, List<BrandProfileModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BrandProfileModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BrandProfileModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'industry',
    'name',
    'photoUrl',
    'tagline',
    'userId',
  };
}
