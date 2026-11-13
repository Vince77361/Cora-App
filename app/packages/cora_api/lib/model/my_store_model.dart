//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MyStoreModel {
  /// Returns a new [MyStoreModel] instance.
  MyStoreModel({
    required this.bestShootingTime,
    required this.category,
    required this.coverPhotoUrl,
    this.customerPhrases = const [],
    required this.defaultTerms,
    required this.hours,
    required this.id,
    required this.industry,
    required this.intro,
    required this.name,
    required this.neighborhood,
    required this.onboardingStep,
    required this.publicUrl,
    required this.recruitLine,
    required this.regionSido,
    required this.regionSigungu,
    required this.seats,
    required this.signatureMenu,
    required this.slug,
    this.sourceLinks = const [],
    required this.status,
    this.tags = const [],
  });

  String? bestShootingTime;

  String? category;

  String? coverPhotoUrl;

  /// 손님들이 자주 한 말.
  List<String> customerPhrases;

  OfferTermsModel? defaultTerms;

  String? hours;

  String id;

  IndustryCategory industry;

  String? intro;

  String? name;

  String? neighborhood;

  StoreOnboardingStep onboardingStep;

  /// 공개 주소(cora.page/l/{slug}). 주소 이름이 없으면 null.
  String? publicUrl;

  String? recruitLine;

  String? regionSido;

  String? regionSigungu;

  String? seats;

  String? signatureMenu;

  /// 공개 주소 이름. 이름이 처음 생길 때 만들고 바꾸지 않는다.
  String? slug;

  List<StoreSourceLinkModel> sourceLinks;

  StoreStatus status;

  /// 꼬리표(# 없이).
  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyStoreModel &&
          other.bestShootingTime == bestShootingTime &&
          other.category == category &&
          other.coverPhotoUrl == coverPhotoUrl &&
          _deepEquality.equals(other.customerPhrases, customerPhrases) &&
          other.defaultTerms == defaultTerms &&
          other.hours == hours &&
          other.id == id &&
          other.industry == industry &&
          other.intro == intro &&
          other.name == name &&
          other.neighborhood == neighborhood &&
          other.onboardingStep == onboardingStep &&
          other.publicUrl == publicUrl &&
          other.recruitLine == recruitLine &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu &&
          other.seats == seats &&
          other.signatureMenu == signatureMenu &&
          other.slug == slug &&
          _deepEquality.equals(other.sourceLinks, sourceLinks) &&
          other.status == status &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (bestShootingTime == null ? 0 : bestShootingTime!.hashCode) +
      (category == null ? 0 : category!.hashCode) +
      (coverPhotoUrl == null ? 0 : coverPhotoUrl!.hashCode) +
      (customerPhrases.hashCode) +
      (defaultTerms == null ? 0 : defaultTerms!.hashCode) +
      (hours == null ? 0 : hours!.hashCode) +
      (id.hashCode) +
      (industry.hashCode) +
      (intro == null ? 0 : intro!.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (onboardingStep.hashCode) +
      (publicUrl == null ? 0 : publicUrl!.hashCode) +
      (recruitLine == null ? 0 : recruitLine!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode) +
      (seats == null ? 0 : seats!.hashCode) +
      (signatureMenu == null ? 0 : signatureMenu!.hashCode) +
      (slug == null ? 0 : slug!.hashCode) +
      (sourceLinks.hashCode) +
      (status.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'MyStoreModel[bestShootingTime=$bestShootingTime, category=$category, coverPhotoUrl=$coverPhotoUrl, customerPhrases=$customerPhrases, defaultTerms=$defaultTerms, hours=$hours, id=$id, industry=$industry, intro=$intro, name=$name, neighborhood=$neighborhood, onboardingStep=$onboardingStep, publicUrl=$publicUrl, recruitLine=$recruitLine, regionSido=$regionSido, regionSigungu=$regionSigungu, seats=$seats, signatureMenu=$signatureMenu, slug=$slug, sourceLinks=$sourceLinks, status=$status, tags=$tags]';

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
    json[r'customerPhrases'] = this.customerPhrases;
    if (this.defaultTerms != null) {
      json[r'defaultTerms'] = this.defaultTerms;
    } else {
      json[r'defaultTerms'] = null;
    }
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
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.neighborhood != null) {
      json[r'neighborhood'] = this.neighborhood;
    } else {
      json[r'neighborhood'] = null;
    }
    json[r'onboardingStep'] = this.onboardingStep;
    if (this.publicUrl != null) {
      json[r'publicUrl'] = this.publicUrl;
    } else {
      json[r'publicUrl'] = null;
    }
    if (this.recruitLine != null) {
      json[r'recruitLine'] = this.recruitLine;
    } else {
      json[r'recruitLine'] = null;
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
    if (this.slug != null) {
      json[r'slug'] = this.slug;
    } else {
      json[r'slug'] = null;
    }
    json[r'sourceLinks'] = this.sourceLinks;
    json[r'status'] = this.status;
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [MyStoreModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MyStoreModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bestShootingTime'),
            'Required key "MyStoreModel[bestShootingTime]" is missing from JSON.');
        assert(json.containsKey(r'category'),
            'Required key "MyStoreModel[category]" is missing from JSON.');
        assert(json.containsKey(r'coverPhotoUrl'),
            'Required key "MyStoreModel[coverPhotoUrl]" is missing from JSON.');
        assert(json.containsKey(r'customerPhrases'),
            'Required key "MyStoreModel[customerPhrases]" is missing from JSON.');
        assert(json[r'customerPhrases'] != null,
            'Required key "MyStoreModel[customerPhrases]" has a null value in JSON.');
        assert(json.containsKey(r'defaultTerms'),
            'Required key "MyStoreModel[defaultTerms]" is missing from JSON.');
        assert(json.containsKey(r'hours'),
            'Required key "MyStoreModel[hours]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "MyStoreModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "MyStoreModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'industry'),
            'Required key "MyStoreModel[industry]" is missing from JSON.');
        assert(json[r'industry'] != null,
            'Required key "MyStoreModel[industry]" has a null value in JSON.');
        assert(json.containsKey(r'intro'),
            'Required key "MyStoreModel[intro]" is missing from JSON.');
        assert(json.containsKey(r'name'),
            'Required key "MyStoreModel[name]" is missing from JSON.');
        assert(json.containsKey(r'neighborhood'),
            'Required key "MyStoreModel[neighborhood]" is missing from JSON.');
        assert(json.containsKey(r'onboardingStep'),
            'Required key "MyStoreModel[onboardingStep]" is missing from JSON.');
        assert(json[r'onboardingStep'] != null,
            'Required key "MyStoreModel[onboardingStep]" has a null value in JSON.');
        assert(json.containsKey(r'publicUrl'),
            'Required key "MyStoreModel[publicUrl]" is missing from JSON.');
        assert(json.containsKey(r'recruitLine'),
            'Required key "MyStoreModel[recruitLine]" is missing from JSON.');
        assert(json.containsKey(r'regionSido'),
            'Required key "MyStoreModel[regionSido]" is missing from JSON.');
        assert(json.containsKey(r'regionSigungu'),
            'Required key "MyStoreModel[regionSigungu]" is missing from JSON.');
        assert(json.containsKey(r'seats'),
            'Required key "MyStoreModel[seats]" is missing from JSON.');
        assert(json.containsKey(r'signatureMenu'),
            'Required key "MyStoreModel[signatureMenu]" is missing from JSON.');
        assert(json.containsKey(r'slug'),
            'Required key "MyStoreModel[slug]" is missing from JSON.');
        assert(json.containsKey(r'sourceLinks'),
            'Required key "MyStoreModel[sourceLinks]" is missing from JSON.');
        assert(json[r'sourceLinks'] != null,
            'Required key "MyStoreModel[sourceLinks]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "MyStoreModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "MyStoreModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "MyStoreModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "MyStoreModel[tags]" has a null value in JSON.');
        return true;
      }());

      return MyStoreModel(
        bestShootingTime: mapValueOfType<String>(json, r'bestShootingTime'),
        category: mapValueOfType<String>(json, r'category'),
        coverPhotoUrl: mapValueOfType<String>(json, r'coverPhotoUrl'),
        customerPhrases: json[r'customerPhrases'] is Iterable
            ? (json[r'customerPhrases'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        defaultTerms: OfferTermsModel.fromJson(json[r'defaultTerms']),
        hours: mapValueOfType<String>(json, r'hours'),
        id: mapValueOfType<String>(json, r'id')!,
        industry: IndustryCategory.fromJson(json[r'industry'])!,
        intro: mapValueOfType<String>(json, r'intro'),
        name: mapValueOfType<String>(json, r'name'),
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        onboardingStep: StoreOnboardingStep.fromJson(json[r'onboardingStep'])!,
        publicUrl: mapValueOfType<String>(json, r'publicUrl'),
        recruitLine: mapValueOfType<String>(json, r'recruitLine'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
        seats: mapValueOfType<String>(json, r'seats'),
        signatureMenu: mapValueOfType<String>(json, r'signatureMenu'),
        slug: mapValueOfType<String>(json, r'slug'),
        sourceLinks: StoreSourceLinkModel.listFromJson(json[r'sourceLinks']),
        status: StoreStatus.fromJson(json[r'status'])!,
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<MyStoreModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MyStoreModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MyStoreModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MyStoreModel> mapFromJson(dynamic json) {
    final map = <String, MyStoreModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MyStoreModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MyStoreModel-objects as value to a dart map
  static Map<String, List<MyStoreModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MyStoreModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MyStoreModel.listFromJson(
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
    'customerPhrases',
    'defaultTerms',
    'hours',
    'id',
    'industry',
    'intro',
    'name',
    'neighborhood',
    'onboardingStep',
    'publicUrl',
    'recruitLine',
    'regionSido',
    'regionSigungu',
    'seats',
    'signatureMenu',
    'slug',
    'sourceLinks',
    'status',
    'tags',
  };
}
