//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CampaignDetailModel {
  /// Returns a new [CampaignDetailModel] instance.
  CampaignDetailModel({
    required this.brandName,
    required this.brandTagline,
    required this.campaignId,
    required this.fee,
    required this.headline,
    required this.kind,
    this.mustInclude = const [],
    required this.myDecision,
    this.notRequired = const [],
    required this.overlapCount,
    required this.photoUrl,
    required this.productProvided,
    this.reasons = const [],
    required this.startFrom,
    this.tags = const [],
    required this.trialDays,
  });

  String brandName;

  String? brandTagline;

  String campaignId;

  int fee;

  String headline;

  CampaignDetailModelKindEnum kind;

  /// 꼭 담을 것.
  List<String> mustInclude;

  /// 내가 저장한 결정(하트 또는 저장). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다.
  SavedDecision? myDecision;

  /// 요구하지 않는 것.
  List<NotRequired> notRequired;

  /// \"내 협업 원칙과 N개가 겹쳐요\"의 N(reasons의 개수).
  int overlapCount;

  String? photoUrl;

  bool productProvided;

  /// 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다.
  List<MatchReason> reasons;

  /// 시작 가능한 날.
  DateTime startFrom;

  List<String> tags;

  ProductTrialDays trialDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignDetailModel &&
          other.brandName == brandName &&
          other.brandTagline == brandTagline &&
          other.campaignId == campaignId &&
          other.fee == fee &&
          other.headline == headline &&
          other.kind == kind &&
          _deepEquality.equals(other.mustInclude, mustInclude) &&
          other.myDecision == myDecision &&
          _deepEquality.equals(other.notRequired, notRequired) &&
          other.overlapCount == overlapCount &&
          other.photoUrl == photoUrl &&
          other.productProvided == productProvided &&
          _deepEquality.equals(other.reasons, reasons) &&
          other.startFrom == startFrom &&
          _deepEquality.equals(other.tags, tags) &&
          other.trialDays == trialDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandName.hashCode) +
      (brandTagline == null ? 0 : brandTagline!.hashCode) +
      (campaignId.hashCode) +
      (fee.hashCode) +
      (headline.hashCode) +
      (kind.hashCode) +
      (mustInclude.hashCode) +
      (myDecision == null ? 0 : myDecision!.hashCode) +
      (notRequired.hashCode) +
      (overlapCount.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (productProvided.hashCode) +
      (reasons.hashCode) +
      (startFrom.hashCode) +
      (tags.hashCode) +
      (trialDays.hashCode);

  @override
  String toString() =>
      'CampaignDetailModel[brandName=$brandName, brandTagline=$brandTagline, campaignId=$campaignId, fee=$fee, headline=$headline, kind=$kind, mustInclude=$mustInclude, myDecision=$myDecision, notRequired=$notRequired, overlapCount=$overlapCount, photoUrl=$photoUrl, productProvided=$productProvided, reasons=$reasons, startFrom=$startFrom, tags=$tags, trialDays=$trialDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'brandName'] = this.brandName;
    if (this.brandTagline != null) {
      json[r'brandTagline'] = this.brandTagline;
    } else {
      json[r'brandTagline'] = null;
    }
    json[r'campaignId'] = this.campaignId;
    json[r'fee'] = this.fee;
    json[r'headline'] = this.headline;
    json[r'kind'] = this.kind;
    json[r'mustInclude'] = this.mustInclude;
    if (this.myDecision != null) {
      json[r'myDecision'] = this.myDecision;
    } else {
      json[r'myDecision'] = null;
    }
    json[r'notRequired'] = this.notRequired;
    json[r'overlapCount'] = this.overlapCount;
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    json[r'productProvided'] = this.productProvided;
    json[r'reasons'] = this.reasons;
    json[r'startFrom'] = _dateFormatter.format(this.startFrom);
    json[r'tags'] = this.tags;
    json[r'trialDays'] = this.trialDays;
    return json;
  }

  /// Returns a new [CampaignDetailModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CampaignDetailModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandName'),
            'Required key "CampaignDetailModel[brandName]" is missing from JSON.');
        assert(json[r'brandName'] != null,
            'Required key "CampaignDetailModel[brandName]" has a null value in JSON.');
        assert(json.containsKey(r'brandTagline'),
            'Required key "CampaignDetailModel[brandTagline]" is missing from JSON.');
        assert(json.containsKey(r'campaignId'),
            'Required key "CampaignDetailModel[campaignId]" is missing from JSON.');
        assert(json[r'campaignId'] != null,
            'Required key "CampaignDetailModel[campaignId]" has a null value in JSON.');
        assert(json.containsKey(r'fee'),
            'Required key "CampaignDetailModel[fee]" is missing from JSON.');
        assert(json[r'fee'] != null,
            'Required key "CampaignDetailModel[fee]" has a null value in JSON.');
        assert(json.containsKey(r'headline'),
            'Required key "CampaignDetailModel[headline]" is missing from JSON.');
        assert(json[r'headline'] != null,
            'Required key "CampaignDetailModel[headline]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "CampaignDetailModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "CampaignDetailModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'mustInclude'),
            'Required key "CampaignDetailModel[mustInclude]" is missing from JSON.');
        assert(json[r'mustInclude'] != null,
            'Required key "CampaignDetailModel[mustInclude]" has a null value in JSON.');
        assert(json.containsKey(r'myDecision'),
            'Required key "CampaignDetailModel[myDecision]" is missing from JSON.');
        assert(json.containsKey(r'notRequired'),
            'Required key "CampaignDetailModel[notRequired]" is missing from JSON.');
        assert(json[r'notRequired'] != null,
            'Required key "CampaignDetailModel[notRequired]" has a null value in JSON.');
        assert(json.containsKey(r'overlapCount'),
            'Required key "CampaignDetailModel[overlapCount]" is missing from JSON.');
        assert(json[r'overlapCount'] != null,
            'Required key "CampaignDetailModel[overlapCount]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'),
            'Required key "CampaignDetailModel[photoUrl]" is missing from JSON.');
        assert(json.containsKey(r'productProvided'),
            'Required key "CampaignDetailModel[productProvided]" is missing from JSON.');
        assert(json[r'productProvided'] != null,
            'Required key "CampaignDetailModel[productProvided]" has a null value in JSON.');
        assert(json.containsKey(r'reasons'),
            'Required key "CampaignDetailModel[reasons]" is missing from JSON.');
        assert(json[r'reasons'] != null,
            'Required key "CampaignDetailModel[reasons]" has a null value in JSON.');
        assert(json.containsKey(r'startFrom'),
            'Required key "CampaignDetailModel[startFrom]" is missing from JSON.');
        assert(json[r'startFrom'] != null,
            'Required key "CampaignDetailModel[startFrom]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "CampaignDetailModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "CampaignDetailModel[tags]" has a null value in JSON.');
        assert(json.containsKey(r'trialDays'),
            'Required key "CampaignDetailModel[trialDays]" is missing from JSON.');
        assert(json[r'trialDays'] != null,
            'Required key "CampaignDetailModel[trialDays]" has a null value in JSON.');
        return true;
      }());

      return CampaignDetailModel(
        brandName: mapValueOfType<String>(json, r'brandName')!,
        brandTagline: mapValueOfType<String>(json, r'brandTagline'),
        campaignId: mapValueOfType<String>(json, r'campaignId')!,
        fee: mapValueOfType<int>(json, r'fee')!,
        headline: mapValueOfType<String>(json, r'headline')!,
        kind: CampaignDetailModelKindEnum.fromJson(json[r'kind'])!,
        mustInclude: json[r'mustInclude'] is Iterable
            ? (json[r'mustInclude'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        myDecision: SavedDecision.fromJson(json[r'myDecision']),
        notRequired: NotRequired.listFromJson(json[r'notRequired']),
        overlapCount: mapValueOfType<int>(json, r'overlapCount')!,
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        productProvided: mapValueOfType<bool>(json, r'productProvided')!,
        reasons: MatchReason.listFromJson(json[r'reasons']),
        startFrom: mapDateTime(json, r'startFrom', r'')!,
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        trialDays: ProductTrialDays.fromJson(json[r'trialDays'])!,
      );
    }
    return null;
  }

  static List<CampaignDetailModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignDetailModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignDetailModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CampaignDetailModel> mapFromJson(dynamic json) {
    final map = <String, CampaignDetailModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CampaignDetailModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CampaignDetailModel-objects as value to a dart map
  static Map<String, List<CampaignDetailModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CampaignDetailModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CampaignDetailModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandName',
    'brandTagline',
    'campaignId',
    'fee',
    'headline',
    'kind',
    'mustInclude',
    'myDecision',
    'notRequired',
    'overlapCount',
    'photoUrl',
    'productProvided',
    'reasons',
    'startFrom',
    'tags',
    'trialDays',
  };
}

enum CampaignDetailModelKindEnum {
  CAMPAIGN._(r'CAMPAIGN'),
  ;

  /// Instantiate a new enum with the provided value.
  const CampaignDetailModelKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [CampaignDetailModelKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static CampaignDetailModelKindEnum? fromJson(dynamic value) =>
      CampaignDetailModelKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [CampaignDetailModelKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<CampaignDetailModelKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignDetailModelKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignDetailModelKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CampaignDetailModelKindEnum] to String,
/// and [decode] dynamic data back to [CampaignDetailModelKindEnum].
class CampaignDetailModelKindEnumTypeTransformer {
  factory CampaignDetailModelKindEnumTypeTransformer() =>
      _instance ??= const CampaignDetailModelKindEnumTypeTransformer._();

  const CampaignDetailModelKindEnumTypeTransformer._();

  String encode(CampaignDetailModelKindEnum data) => data._value;

  /// Returns the instance of [CampaignDetailModelKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CampaignDetailModelKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is CampaignDetailModelKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'CAMPAIGN':
          return CampaignDetailModelKindEnum.CAMPAIGN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static CampaignDetailModelKindEnumTypeTransformer? _instance;
}
