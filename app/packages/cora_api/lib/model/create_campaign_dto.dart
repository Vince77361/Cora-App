//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreateCampaignDto {
  /// Returns a new [CreateCampaignDto] instance.
  CreateCampaignDto({
    required this.budget,
    required this.fee,
    required this.format,
    required this.headline,
    this.mustInclude = const [],
    this.notRequired = const [],
    required this.productProvided,
    required this.startFrom,
    required this.trialDays,
  });

  /// 캠페인 예산(원). 1만 원 단위, 제작비 이상.
  ///
  /// Minimum value: 10000
  /// Maximum value: 100000000
  int budget;

  /// 제작비(원). 1만 원 단위.
  ///
  /// Minimum value: 10000
  /// Maximum value: 10000000
  int fee;

  ContentFormat format;

  String headline;

  /// 꼭 담을 것. 최대 3줄, 줄마다 1~20자.
  List<String> mustInclude;

  /// 요구하지 않는 것.
  List<NotRequired> notRequired;

  bool productProvided;

  /// 시작 가능한 날(YYYY-MM-DD). 한국 시간 오늘 이후.
  DateTime startFrom;

  ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateCampaignDto &&
          other.budget == budget &&
          other.fee == fee &&
          other.format == format &&
          other.headline == headline &&
          _deepEquality.equals(other.mustInclude, mustInclude) &&
          _deepEquality.equals(other.notRequired, notRequired) &&
          other.productProvided == productProvided &&
          other.startFrom == startFrom &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (budget.hashCode) +
      (fee.hashCode) +
      (format.hashCode) +
      (headline.hashCode) +
      (mustInclude.hashCode) +
      (notRequired.hashCode) +
      (productProvided.hashCode) +
      (startFrom.hashCode) +
      (trialDays.hashCode);

  @override
  String toString() =>
      'CreateCampaignDto[budget=$budget, fee=$fee, format=$format, headline=$headline, mustInclude=$mustInclude, notRequired=$notRequired, productProvided=$productProvided, startFrom=$startFrom, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'budget'] = this.budget;
    json[r'fee'] = this.fee;
    json[r'format'] = this.format;
    json[r'headline'] = this.headline;
    json[r'mustInclude'] = this.mustInclude;
    json[r'notRequired'] = this.notRequired;
    json[r'productProvided'] = this.productProvided;
    json[r'startFrom'] = _dateFormatter.format(this.startFrom);
    json[r'trialDays'] = this.trialDays;
    return json;
  }

  /// Returns a new [CreateCampaignDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateCampaignDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'budget'),
            'Required key "CreateCampaignDto[budget]" is missing from JSON.');
        assert(json[r'budget'] != null,
            'Required key "CreateCampaignDto[budget]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "CreateCampaignDto[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "CreateCampaignDto[fee]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "CreateCampaignDto[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "CreateCampaignDto[format]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CreateCampaignDto[headline]" is missing from JSON.');
        assert(json[r'headline'] != null,
            'Required key "CreateCampaignDto[headline]" has a null value in JSON.');
        assert(json.containsKey(r'mustInclude'),
            'Required key "CreateCampaignDto[mustInclude]" is missing from JSON.');
        assert(json[r'mustInclude'] != null,
            'Required key "CreateCampaignDto[mustInclude]" has a null value in JSON.');
        assert(json.containsKey(r'notRequired'),
            'Required key "CreateCampaignDto[notRequired]" is missing from JSON.');
        assert(json[r'notRequired'] != null,
            'Required key "CreateCampaignDto[notRequired]" has a null value in JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "CreateCampaignDto[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "CreateCampaignDto[productProvided]" has a null value in JSON.');
        assert(json.containsKey(r'startFrom'),
            'Required key "CreateCampaignDto[startFrom]" is missing from JSON.');
        assert(json[r'startFrom'] != null,
            'Required key "CreateCampaignDto[startFrom]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "CreateCampaignDto[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "CreateCampaignDto[trialDays]" has a null value in JSON.');
        return true;
      }());

      return CreateCampaignDto(
        budget: mapValueOfType<int>(json, r'budget')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        headline: mapValueOfType<String>(json, r'headline')!,
        mustInclude: json[r'mustInclude'] is Iterable
            ? (json[r'mustInclude'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        notRequired: NotRequired.listFromJson(json[r'notRequired']),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
        startFrom: mapDateTime(json, r'startFrom', r'')!,
        trialDays: ProductTrialDays.fromJson(json[r'trialDays'])!,
      );
    }
    return null;
  }

  static List<CreateCampaignDto> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateCampaignDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateCampaignDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateCampaignDto> mapFromJson(dynamic json) {
    final map = <String, CreateCampaignDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateCampaignDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateCampaignDto-objects as value to a dart map
  static Map<String, List<CreateCampaignDto>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateCampaignDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateCampaignDto.listFromJson(
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
    'mustInclude',
    'notRequired',
    'productProvided',
    'startFrom',
    'trialDays',
  };
}
