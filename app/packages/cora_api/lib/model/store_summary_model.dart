//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreSummaryModel {
  /// Returns a new [StoreSummaryModel] instance.
  StoreSummaryModel({
    required this.category,
    required this.coverPhotoUrl,
    required this.defaultTerms,
    required this.id,
    required this.industry,
    required this.name,
    required this.neighborhood,
    required this.regionSido,
    required this.regionSigungu,
  });

  String? category;

  String? coverPhotoUrl;

  OfferTermsModel defaultTerms;

  String id;

  IndustryCategory industry;

  String name;

  String? neighborhood;

  String? regionSido;

  String? regionSigungu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreSummaryModel &&
          other.category == category &&
          other.coverPhotoUrl == coverPhotoUrl &&
          other.defaultTerms == defaultTerms &&
          other.id == id &&
          other.industry == industry &&
          other.name == name &&
          other.neighborhood == neighborhood &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (category == null ? 0 : category!.hashCode) +
      (coverPhotoUrl == null ? 0 : coverPhotoUrl!.hashCode) +
      (defaultTerms.hashCode) +
      (id.hashCode) +
      (industry.hashCode) +
      (name.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode);

  @override
  String toString() =>
      'StoreSummaryModel[category=$category, coverPhotoUrl=$coverPhotoUrl, defaultTerms=$defaultTerms, id=$id, industry=$industry, name=$name, neighborhood=$neighborhood, regionSido=$regionSido, regionSigungu=$regionSigungu]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.coverPhotoUrl != null) {
      json[r'coverPhotoUrl'] = this.coverPhotoUrl;
    } else {
      json[r'coverPhotoUrl'] = null;
    }
    json[r'defaultTerms'] = this.defaultTerms;
    json[r'id'] = this.id;
    json[r'industry'] = this.industry;
    json[r'name'] = this.name;
    if (this.neighborhood != null) {
      json[r'neighborhood'] = this.neighborhood;
    } else {
      json[r'neighborhood'] = null;
    }
    if (this.regionSido != null) {
      json[r'regionSido'] = this.regionSido;
    } else {
      json[r'regionSido'] = null;
    }
    if (this.regionSigungu != null) {
      json[r'regionSigungu'] = this.regionSigungu;
    } else {
      json[r'regionSigungu'] = null;
    }
    return json;
  }

  /// Returns a new [StoreSummaryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreSummaryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'category'),
            'Required key "StoreSummaryModel[category]" is missing from JSON.');
        assert(json.containsKey(r'coverPhotoUrl'),
            'Required key "StoreSummaryModel[coverPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'defaultTerms'),
            'Required key "StoreSummaryModel[defaultTerms]" is missing from JSON.');
        assert(json[r'defaultTerms'] != null,
            'Required key "StoreSummaryModel[defaultTerms]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "StoreSummaryModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "StoreSummaryModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'industry'),
            'Required key "StoreSummaryModel[industry]" is missing from JSON.');
        assert(json[r'industry'] != null,
            'Required key "StoreSummaryModel[industry]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "StoreSummaryModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "StoreSummaryModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'neighborhood'),
            'Required key "StoreSummaryModel[neighborhood]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "StoreSummaryModel[regionSido]" is missing from JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "StoreSummaryModel[regionSigungu]" is missing from JSON.');
        return true;
      }());

      return StoreSummaryModel(
        category: mapValueOfType<String>(json, r'category'),
        coverPhotoUrl: mapValueOfType<String>(json, r'coverPhotoUrl'),
        defaultTerms: OfferTermsModel.fromJson(json[r'defaultTerms'])!,
        id: mapValueOfType<String>(json, r'id')!,
        industry: IndustryCategory.fromJson(json[r'industry'])!,
        name: mapValueOfType<String>(json, r'name')!,
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
      );
    }
    return null;
  }

  static List<StoreSummaryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreSummaryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreSummaryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreSummaryModel> mapFromJson(dynamic json) {
    final map = <String, StoreSummaryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreSummaryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreSummaryModel-objects as value to a dart map
  static Map<String, List<StoreSummaryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreSummaryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreSummaryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'coverPhotoUrl',
    'defaultTerms',
    'id',
    'industry',
    'name',
    'neighborhood',
    'regionSido',
    'regionSigungu',
  };
}
