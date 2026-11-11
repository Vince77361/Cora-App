//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreDetailModel {
  /// Returns a new [StoreDetailModel] instance.
  StoreDetailModel({
    required this.bestShootingTime,
    required this.category,
    required this.coverPhotoUrl,
    required this.defaultTerms,
    required this.hours,
    required this.id,
    required this.industry,
    required this.intro,
    required this.myApplicationStatus,
    required this.name,
    required this.neighborhood,
    required this.regionSido,
    required this.regionSigungu,
    required this.seats,
    required this.signatureMenu,
  });

  String? bestShootingTime;

  String? category;

  String? coverPhotoUrl;

  OfferTermsModel defaultTerms;

  String? hours;

  String id;

  IndustryCategory industry;

  String? intro;

  /// 내가 이 가게에 낸 지금 살아 있는 지원의 상태. 없으면 NONE.
  MyApplicationStatus myApplicationStatus;

  String name;

  String? neighborhood;

  String? regionSido;

  String? regionSigungu;

  String? seats;

  String? signatureMenu;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreDetailModel &&
          other.bestShootingTime == bestShootingTime &&
          other.category == category &&
          other.coverPhotoUrl == coverPhotoUrl &&
          other.defaultTerms == defaultTerms &&
          other.hours == hours &&
          other.id == id &&
          other.industry == industry &&
          other.intro == intro &&
          other.myApplicationStatus == myApplicationStatus &&
          other.name == name &&
          other.neighborhood == neighborhood &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu &&
          other.seats == seats &&
          other.signatureMenu == signatureMenu;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (bestShootingTime == null ? 0 : bestShootingTime!.hashCode) +
      (category == null ? 0 : category!.hashCode) +
      (coverPhotoUrl == null ? 0 : coverPhotoUrl!.hashCode) +
      (defaultTerms.hashCode) +
      (hours == null ? 0 : hours!.hashCode) +
      (id.hashCode) +
      (industry.hashCode) +
      (intro == null ? 0 : intro!.hashCode) +
      (myApplicationStatus.hashCode) +
      (name.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode) +
      (seats == null ? 0 : seats!.hashCode) +
      (signatureMenu == null ? 0 : signatureMenu!.hashCode);

  @override
  String toString() =>
      'StoreDetailModel[bestShootingTime=$bestShootingTime, category=$category, coverPhotoUrl=$coverPhotoUrl, defaultTerms=$defaultTerms, hours=$hours, id=$id, industry=$industry, intro=$intro, myApplicationStatus=$myApplicationStatus, name=$name, neighborhood=$neighborhood, regionSido=$regionSido, regionSigungu=$regionSigungu, seats=$seats, signatureMenu=$signatureMenu]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.bestShootingTime != null) {
      json[r'bestShootingTime'] = this.bestShootingTime;
    } else {
      json[r'bestShootingTime'] = null;
    }
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
    if (this.hours != null) {
      json[r'hours'] = this.hours;
    } else {
      json[r'hours'] = null;
    }
    json[r'id'] = this.id;
    json[r'industry'] = this.industry;
    if (this.intro != null) {
      json[r'intro'] = this.intro;
    } else {
      json[r'intro'] = null;
    }
    json[r'myApplicationStatus'] = this.myApplicationStatus;
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
    if (this.seats != null) {
      json[r'seats'] = this.seats;
    } else {
      json[r'seats'] = null;
    }
    if (this.signatureMenu != null) {
      json[r'signatureMenu'] = this.signatureMenu;
    } else {
      json[r'signatureMenu'] = null;
    }
    return json;
  }

  /// Returns a new [StoreDetailModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreDetailModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bestShootingTime'),
            'Required key "StoreDetailModel[bestShootingTime]" is missing from JSON.');
        assert(json.containsKey(r'category'),
            'Required key "StoreDetailModel[category]" is missing from JSON.');
        assert(json.containsKey(r'coverPhotoUrl'),
            'Required key "StoreDetailModel[coverPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'defaultTerms'),
            'Required key "StoreDetailModel[defaultTerms]" is missing from JSON.');
        assert(json[r'defaultTerms'] != null,
            'Required key "StoreDetailModel[defaultTerms]" has a null value in JSON.');
        assert(json.containsKey(r'hours'),
            'Required key "StoreDetailModel[hours]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "StoreDetailModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "StoreDetailModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'industry'),
            'Required key "StoreDetailModel[industry]" is missing from JSON.');
        assert(json[r'industry'] != null,
            'Required key "StoreDetailModel[industry]" has a null value in JSON.');
        assert(json.containsKey(r'intro'),
            'Required key "StoreDetailModel[intro]" is missing from JSON.');
        assert(json.containsKey(r'myApplicationStatus'),
            'Required key "StoreDetailModel[myApplicationStatus]" is missing from JSON.');
        assert(json[r'myApplicationStatus'] != null,
            'Required key "StoreDetailModel[myApplicationStatus]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "StoreDetailModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "StoreDetailModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'neighborhood'),
            'Required key "StoreDetailModel[neighborhood]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "StoreDetailModel[regionSido]" is missing from JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "StoreDetailModel[regionSigungu]" is missing from JSON.');
        assert(json.containsKey(r'seats'),
            'Required key "StoreDetailModel[seats]" is missing from JSON.');
        assert(json.containsKey(r'signatureMenu'),
            'Required key "StoreDetailModel[signatureMenu]" is missing from JSON.');
        return true;
      }());

      return StoreDetailModel(
        bestShootingTime: mapValueOfType<String>(json, r'bestShootingTime'),
        category: mapValueOfType<String>(json, r'category'),
        coverPhotoUrl: mapValueOfType<String>(json, r'coverPhotoUrl'),
        defaultTerms: OfferTermsModel.fromJson(json[r'defaultTerms'])!,
        hours: mapValueOfType<String>(json, r'hours'),
        id: mapValueOfType<String>(json, r'id')!,
        industry: IndustryCategory.fromJson(json[r'industry'])!,
        intro: mapValueOfType<String>(json, r'intro'),
        myApplicationStatus:
            MyApplicationStatus.fromJson(json[r'myApplicationStatus'])!,
        name: mapValueOfType<String>(json, r'name')!,
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
        seats: mapValueOfType<String>(json, r'seats'),
        signatureMenu: mapValueOfType<String>(json, r'signatureMenu'),
      );
    }
    return null;
  }

  static List<StoreDetailModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreDetailModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreDetailModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreDetailModel> mapFromJson(dynamic json) {
    final map = <String, StoreDetailModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreDetailModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreDetailModel-objects as value to a dart map
  static Map<String, List<StoreDetailModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreDetailModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreDetailModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bestShootingTime',
    'category',
    'coverPhotoUrl',
    'defaultTerms',
    'hours',
    'id',
    'industry',
    'intro',
    'myApplicationStatus',
    'name',
    'neighborhood',
    'regionSido',
    'regionSigungu',
    'seats',
    'signatureMenu',
  };
}
