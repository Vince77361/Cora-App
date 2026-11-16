//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CampaignModel {
  /// Returns a new [CampaignModel] instance.
  CampaignModel({
    required this.budget,
    required this.fee,
    required this.format,
    required this.headline,
    required this.id,
    this.mustInclude = const [],
    this.notRequired = const [],
    required this.productProvided,
    required this.startFrom,
    required this.status,
    required this.trialDays,
  });

  /// 이 캠페인에 쓰려는 현금의 합(원). 브랜드만 보는 값이라 크리에이터가 받는 응답에는 넣지 않는다.
  int budget;

  /// 크리에이터 한 명에게 주는 현금 고정비의 기본값(원).
  int fee;

  ContentFormat format;

  String headline;

  String id;

  /// 꼭 담을 것. 줄마다 20자까지.
  List<String> mustInclude;

  /// 요구하지 않는 것.
  List<NotRequired> notRequired;

  bool productProvided;

  DateTime startFrom;

  CampaignStatus status;

  ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignModel &&
          other.budget == budget &&
          other.fee == fee &&
          other.format == format &&
          other.headline == headline &&
          other.id == id &&
          _deepEquality.equals(other.mustInclude, mustInclude) &&
          _deepEquality.equals(other.notRequired, notRequired) &&
          other.productProvided == productProvided &&
          other.startFrom == startFrom &&
          other.status == status &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (budget.hashCode) +
      (fee.hashCode) +
      (format.hashCode) +
      (headline.hashCode) +
      (id.hashCode) +
      (mustInclude.hashCode) +
      (notRequired.hashCode) +
      (productProvided.hashCode) +
      (startFrom.hashCode) +
      (status.hashCode) +
      (trialDays.hashCode);

  @override
  String toString() =>
      'CampaignModel[budget=$budget, fee=$fee, format=$format, headline=$headline, id=$id, mustInclude=$mustInclude, notRequired=$notRequired, productProvided=$productProvided, startFrom=$startFrom, status=$status, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'budget'] = this.budget;
    json[r'fee'] = this.fee;
    json[r'format'] = this.format;
    json[r'headline'] = this.headline;
    json[r'id'] = this.id;
    json[r'mustInclude'] = this.mustInclude;
    json[r'notRequired'] = this.notRequired;
    json[r'productProvided'] = this.productProvided;
    json[r'startFrom'] = _dateFormatter.format(this.startFrom);
    json[r'status'] = this.status;
    json[r'trialDays'] = this.trialDays;
    return json;
  }

  /// Returns a new [CampaignModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CampaignModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'budget'),
            'Required key "CampaignModel[budget]" is missing from JSON.');
        assert(json[r'budget'] != null,
            'Required key "CampaignModel[budget]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "CampaignModel[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "CampaignModel[fee]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "CampaignModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "CampaignModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CampaignModel[headline]" is missing from JSON.');
        assert(json[r'headline'] != null,
            'Required key "CampaignModel[headline]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "CampaignModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CampaignModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'mustInclude'),
            'Required key "CampaignModel[mustInclude]" is missing from JSON.');
        assert(json[r'mustInclude'] != null,
            'Required key "CampaignModel[mustInclude]" has a null value in JSON.');
        assert(json.containsKey(r'notRequired'),
            'Required key "CampaignModel[notRequired]" is missing from JSON.');
        assert(json[r'notRequired'] != null,
            'Required key "CampaignModel[notRequired]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "CampaignModel[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "CampaignModel[productProvided]" has a null value in JSON.');
        assert(json.containsKey(r'startFrom'),
            'Required key "CampaignModel[startFrom]" is missing from JSON.');
        assert(json[r'startFrom'] != null,
            'Required key "CampaignModel[startFrom]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "CampaignModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "CampaignModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "CampaignModel[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "CampaignModel[trialDays]" has a null value in JSON.');
        return true;
      }());

      return CampaignModel(
        budget: mapValueOfType<int>(json, r'budget')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        headline: mapValueOfType<String>(json, r'headline')!,
        id: mapValueOfType<String>(json, r'id')!,
        mustInclude: json[r'mustInclude'] is Iterable
            ? (json[r'mustInclude'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        notRequired: NotRequired.listFromJson(json[r'notRequired']),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
        startFrom: mapDateTime(json, r'startFrom', r'')!,
        status: CampaignStatus.fromJson(json[r'status'])!,
        trialDays: ProductTrialDays.fromJson(json[r'trialDays'])!,
      );
    }
    return null;
  }

  static List<CampaignModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CampaignModel> mapFromJson(dynamic json) {
    final map = <String, CampaignModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CampaignModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CampaignModel-objects as value to a dart map
  static Map<String, List<CampaignModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CampaignModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CampaignModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'budget',
    'fee',
    'format',
    'headline',
    'id',
    'mustInclude',
    'notRequired',
    'productProvided',
    'startFrom',
    'status',
    'trialDays',
  };
}
