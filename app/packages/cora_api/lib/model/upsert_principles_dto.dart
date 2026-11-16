//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UpsertPrinciplesDto {
  /// Returns a new [UpsertPrinciplesDto] instance.
  UpsertPrinciplesDto({
    this.blockedIndustries = const [],
    required this.faceOk,
    required this.feeBand,
    this.fields = const [],
    required this.honestReview,
    required this.scriptOk,
    required this.trialDays,
  });

  List<IndustryCategory> blockedIndustries;

  bool faceOk;

  FeeBand feeBand;

  List<IndustryCategory> fields;

  bool honestReview;

  bool scriptOk;

  ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpsertPrinciplesDto &&
          _deepEquality.equals(other.blockedIndustries, blockedIndustries) &&
          other.faceOk == faceOk &&
          other.feeBand == feeBand &&
          _deepEquality.equals(other.fields, fields) &&
          other.honestReview == honestReview &&
          other.scriptOk == scriptOk &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (blockedIndustries.hashCode) +
      (faceOk.hashCode) +
      (feeBand.hashCode) +
      (fields.hashCode) +
      (honestReview.hashCode) +
      (scriptOk.hashCode) +
      (trialDays.hashCode);

  @override
  String toString() =>
      'UpsertPrinciplesDto[blockedIndustries=$blockedIndustries, faceOk=$faceOk, feeBand=$feeBand, fields=$fields, honestReview=$honestReview, scriptOk=$scriptOk, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'blockedIndustries'] = this.blockedIndustries;
    json[r'faceOk'] = this.faceOk;
    json[r'feeBand'] = this.feeBand;
    json[r'fields'] = this.fields;
    json[r'honestReview'] = this.honestReview;
    json[r'scriptOk'] = this.scriptOk;
    json[r'trialDays'] = this.trialDays;
    return json;
  }

  /// Returns a new [UpsertPrinciplesDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpsertPrinciplesDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'blockedIndustries'),
            'Required key "UpsertPrinciplesDto[blockedIndustries]" is missing from JSON.');
        assert(json[r'blockedIndustries'] != null,
            'Required key "UpsertPrinciplesDto[blockedIndustries]" has a null value in JSON.');
        assert(json.containsKey(r'faceOk'),
            'Required key "UpsertPrinciplesDto[faceOk]" is missing from JSON.');
        assert(json[r'faceOk'] != null,
            'Required key "UpsertPrinciplesDto[faceOk]" has a null value in JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "UpsertPrinciplesDto[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "UpsertPrinciplesDto[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'fields'),
            'Required key "UpsertPrinciplesDto[fields]" is missing from JSON.');
        assert(json[r'fields'] != null,
            'Required key "UpsertPrinciplesDto[fields]" has a null value in JSON.');
        assert(json.containsKey(r'honestReview'),
            'Required key "UpsertPrinciplesDto[honestReview]" is missing from JSON.');
        assert(json[r'honestReview'] != null,
            'Required key "UpsertPrinciplesDto[honestReview]" has a null value in JSON.');
        assert(json.containsKey(r'scriptOk'),
            'Required key "UpsertPrinciplesDto[scriptOk]" is missing from JSON.');
        assert(json[r'scriptOk'] != null,
            'Required key "UpsertPrinciplesDto[scriptOk]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "UpsertPrinciplesDto[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "UpsertPrinciplesDto[trialDays]" has a null value in JSON.');
        return true;
      }());

      return UpsertPrinciplesDto(
        blockedIndustries:
            IndustryCategory.listFromJson(json[r'blockedIndustries']),
        faceOk: mapValueOfType<bool>(json, r'faceOk')!,
        feeBand: FeeBand.fromJson(json[r'feeBand'])!,
        fields: IndustryCategory.listFromJson(json[r'fields']),
        honestReview: mapValueOfType<bool>(json, r'honestReview')!,
        scriptOk: mapValueOfType<bool>(json, r'scriptOk')!,
        trialDays: ProductTrialDays.fromJson(json[r'trialDays'])!,
      );
    }
    return null;
  }

  static List<UpsertPrinciplesDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpsertPrinciplesDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpsertPrinciplesDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpsertPrinciplesDto> mapFromJson(dynamic json) {
    final map = <String, UpsertPrinciplesDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpsertPrinciplesDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpsertPrinciplesDto-objects as value to a dart map
  static Map<String, List<UpsertPrinciplesDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpsertPrinciplesDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpsertPrinciplesDto.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'blockedIndustries',
    'faceOk',
    'feeBand',
    'fields',
    'honestReview',
    'scriptOk',
    'trialDays',
  };
}
