//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpdateStoreDto {
  /// Returns a new [UpdateStoreDto] instance.
  UpdateStoreDto({
    this.bestShootingTime,
    this.category,
    this.coverPhotoPath,
    this.customerPhrases = const [],
    this.hours,
    this.industry,
    this.intro,
    this.name,
    this.neighborhood,
    this.recruitLine,
    this.regionSido,
    this.regionSigungu,
    this.seats,
    this.signatureMenu,
    this.tags = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? bestShootingTime;

  /// 표시용 업종(예: 라멘집).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverPhotoPath;

  /// 손님들이 자주 한 말. 최대 3개, 각 20자.
  List<String> customerPhrases;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? hours;

  /// 업종 분류(공통 모델 3장).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  IndustryCategory? industry;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? intro;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// 표시용 동네(예: 성수동).
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? neighborhood;

  /// 크리에이터에게 보이는 모집 한 줄. 빈 문자열이면 지운다.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? recruitLine;

  /// 시·도 고정 목록(SIDO_LIST) 중 하나.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? regionSido;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? regionSigungu;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? seats;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? signatureMenu;

  /// 꼬리표(# 없이). 최대 5개, 각 10자.
  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateStoreDto &&
          other.bestShootingTime == bestShootingTime &&
          other.category == category &&
          other.coverPhotoPath == coverPhotoPath &&
          _deepEquality.equals(other.customerPhrases, customerPhrases) &&
          other.hours == hours &&
          other.industry == industry &&
          other.intro == intro &&
          other.name == name &&
          other.neighborhood == neighborhood &&
          other.recruitLine == recruitLine &&
          other.regionSido == regionSido &&
          other.regionSigungu == regionSigungu &&
          other.seats == seats &&
          other.signatureMenu == signatureMenu &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (bestShootingTime == null ? 0 : bestShootingTime!.hashCode) +
      (category == null ? 0 : category!.hashCode) +
      (coverPhotoPath == null ? 0 : coverPhotoPath!.hashCode) +
      (customerPhrases.hashCode) +
      (hours == null ? 0 : hours!.hashCode) +
      (industry == null ? 0 : industry!.hashCode) +
      (intro == null ? 0 : intro!.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (neighborhood == null ? 0 : neighborhood!.hashCode) +
      (recruitLine == null ? 0 : recruitLine!.hashCode) +
      (regionSido == null ? 0 : regionSido!.hashCode) +
      (regionSigungu == null ? 0 : regionSigungu!.hashCode) +
      (seats == null ? 0 : seats!.hashCode) +
      (signatureMenu == null ? 0 : signatureMenu!.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'UpdateStoreDto[bestShootingTime=$bestShootingTime, category=$category, coverPhotoPath=$coverPhotoPath, customerPhrases=$customerPhrases, hours=$hours, industry=$industry, intro=$intro, name=$name, neighborhood=$neighborhood, recruitLine=$recruitLine, regionSido=$regionSido, regionSigungu=$regionSigungu, seats=$seats, signatureMenu=$signatureMenu, tags=$tags]';

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
    if (this.coverPhotoPath != null) {
      json[r'coverPhotoPath'] = this.coverPhotoPath;
    } else {
      json[r'coverPhotoPath'] = null;
    }
    json[r'customerPhrases'] = this.customerPhrases;
    if (this.hours != null) {
      json[r'hours'] = this.hours;
    } else {
      json[r'hours'] = null;
    }
    if (this.industry != null) {
      json[r'industry'] = this.industry;
    } else {
      json[r'industry'] = null;
    }
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
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [UpdateStoreDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateStoreDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateStoreDto(
        bestShootingTime: mapValueOfType<String>(json, r'bestShootingTime'),
        category: mapValueOfType<String>(json, r'category'),
        coverPhotoPath: mapValueOfType<String>(json, r'coverPhotoPath'),
        customerPhrases: json[r'customerPhrases'] is Iterable
            ? (json[r'customerPhrases'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        hours: mapValueOfType<String>(json, r'hours'),
        industry: IndustryCategory.fromJson(json[r'industry']),
        intro: mapValueOfType<String>(json, r'intro'),
        name: mapValueOfType<String>(json, r'name'),
        neighborhood: mapValueOfType<String>(json, r'neighborhood'),
        recruitLine: mapValueOfType<String>(json, r'recruitLine'),
        regionSido: mapValueOfType<String>(json, r'regionSido'),
        regionSigungu: mapValueOfType<String>(json, r'regionSigungu'),
        seats: mapValueOfType<String>(json, r'seats'),
        signatureMenu: mapValueOfType<String>(json, r'signatureMenu'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<UpdateStoreDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpdateStoreDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateStoreDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateStoreDto> mapFromJson(dynamic json) {
    final map = <String, UpdateStoreDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateStoreDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateStoreDto-objects as value to a dart map
  static Map<String, List<UpdateStoreDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpdateStoreDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateStoreDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
