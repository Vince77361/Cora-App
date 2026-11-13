//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CoraSideModel {
  /// Returns a new [CoraSideModel] instance.
  CoraSideModel({
    required this.averageMultiplierTenths,
    this.contentByFormat = const [],
    required this.offerCount,
    required this.spent,
  });

  /// 평소 대비 배수(10배 한 정수, 26 = 2.6배)의 평균, 소수 첫째 자리까지 내림. 배수가 있는 협업이 없으면 null.
  int? averageMultiplierTenths;

  /// 형식별 생긴 콘텐츠 수. 0편인 형식은 없다.
  List<ContentCountModel> contentByFormat;

  /// 끝난 협업 수(오퍼 건수).
  int offerCount;

  /// 들어간 돈(원). 끝난 협업의 크리에이터 지급액과 수수료의 합.
  int spent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoraSideModel &&
          other.averageMultiplierTenths == averageMultiplierTenths &&
          _deepEquality.equals(other.contentByFormat, contentByFormat) &&
          other.offerCount == offerCount &&
          other.spent == spent;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (averageMultiplierTenths == null
          ? 0
          : averageMultiplierTenths!.hashCode) +
      (contentByFormat.hashCode) +
      (offerCount.hashCode) +
      (spent.hashCode);

  @override
  String toString() =>
      'CoraSideModel[averageMultiplierTenths=$averageMultiplierTenths, contentByFormat=$contentByFormat, offerCount=$offerCount, spent=$spent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.averageMultiplierTenths != null) {
      json[r'averageMultiplierTenths'] = this.averageMultiplierTenths;
    } else {
      json[r'averageMultiplierTenths'] = null;
    }
    json[r'contentByFormat'] = this.contentByFormat;
    json[r'offerCount'] = this.offerCount;
    json[r'spent'] = this.spent;
    return json;
  }

  /// Returns a new [CoraSideModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CoraSideModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'averageMultiplierTenths'),
            'Required key "CoraSideModel[averageMultiplierTenths]" is missing from JSON.');
        assert(json.containsKey(r'contentByFormat'),
            'Required key "CoraSideModel[contentByFormat]" is missing from JSON.');
        assert(json[r'contentByFormat'] != null,
            'Required key "CoraSideModel[contentByFormat]" has a null value in JSON.');
        assert(json.containsKey(r'offerCount'),
            'Required key "CoraSideModel[offerCount]" is missing from JSON.');
        assert(json[r'offerCount'] != null,
            'Required key "CoraSideModel[offerCount]" has a null value in JSON.');
        assert(json.containsKey(r'spent'),
            'Required key "CoraSideModel[spent]" is missing from JSON.');
        assert(json[r'spent'] != null,
            'Required key "CoraSideModel[spent]" has a null value in JSON.');
        return true;
      }());

      return CoraSideModel(
        averageMultiplierTenths:
            mapValueOfType<int>(json, r'averageMultiplierTenths'),
        contentByFormat:
            ContentCountModel.listFromJson(json[r'contentByFormat']),
        offerCount: mapValueOfType<int>(json, r'offerCount')!,
        spent: mapValueOfType<int>(json, r'spent')!,
      );
    }
    return null;
  }

  static List<CoraSideModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CoraSideModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CoraSideModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CoraSideModel> mapFromJson(dynamic json) {
    final map = <String, CoraSideModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CoraSideModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CoraSideModel-objects as value to a dart map
  static Map<String, List<CoraSideModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CoraSideModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CoraSideModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'averageMultiplierTenths',
    'contentByFormat',
    'offerCount',
    'spent',
  };
}
