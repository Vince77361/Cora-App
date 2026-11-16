//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PrinciplesModel {
  /// Returns a new [PrinciplesModel] instance.
  PrinciplesModel({
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
      other is PrinciplesModel &&
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
      'PrinciplesModel[blockedIndustries=$blockedIndustries, faceOk=$faceOk, feeBand=$feeBand, fields=$fields, honestReview=$honestReview, scriptOk=$scriptOk, trialDays=$trialDays]';

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

  /// Returns a new [PrinciplesModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PrinciplesModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'blockedIndustries'),
            'Required key "PrinciplesModel[blockedIndustries]" is missing from JSON.');
        assert(json[r'blockedIndustries'] != null,
            'Required key "PrinciplesModel[blockedIndustries]" has a null value in JSON.');
        assert(json.containsKey(r'faceOk'),
            'Required key "PrinciplesModel[faceOk]" is missing from JSON.');
        assert(json[r'faceOk'] != null,
            'Required key "PrinciplesModel[faceOk]" has a null value in JSON.');
        assert(json.containsKey(r'feeBand'),
            'Required key "PrinciplesModel[feeBand]" is missing from JSON.');
        assert(json[r'feeBand'] != null,
            'Required key "PrinciplesModel[feeBand]" has a null value in JSON.');
        assert(json.containsKey(r'fields'),
            'Required key "PrinciplesModel[fields]" is missing from JSON.');
        assert(json[r'fields'] != null,
            'Required key "PrinciplesModel[fields]" has a null value in JSON.');
        assert(json.containsKey(r'honestReview'),
            'Required key "PrinciplesModel[honestReview]" is missing from JSON.');
        assert(json[r'honestReview'] != null,
            'Required key "PrinciplesModel[honestReview]" has a null value in JSON.');
        assert(json.containsKey(r'scriptOk'),
            'Required key "PrinciplesModel[scriptOk]" is missing from JSON.');
        assert(json[r'scriptOk'] != null,
            'Required key "PrinciplesModel[scriptOk]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "PrinciplesModel[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "PrinciplesModel[trialDays]" has a null value in JSON.');
        return true;
      }());

      return PrinciplesModel(
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

  static List<PrinciplesModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PrinciplesModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PrinciplesModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PrinciplesModel> mapFromJson(dynamic json) {
    final map = <String, PrinciplesModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PrinciplesModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PrinciplesModel-objects as value to a dart map
  static Map<String, List<PrinciplesModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PrinciplesModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PrinciplesModel.listFromJson(
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
