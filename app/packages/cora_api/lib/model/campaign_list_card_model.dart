//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CampaignListCardModel {
  /// Returns a new [CampaignListCardModel] instance.
  CampaignListCardModel({
    this.brandName,
    this.brandTagline,
    this.campaignId,
    this.fee,
    required this.headline,
    required this.kind,
    this.otherSido,
    this.photoUrl,
    this.productProvided,
    this.reasons = const [],
    this.rewardLine,
    this.store,
    this.tags = const [],
  });

  /// CAMPAIGN만.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? brandName;

  /// CAMPAIGN만.
  String? brandTagline;

  /// CAMPAIGN만.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? campaignId;

  /// CAMPAIGN만.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? fee;

  /// 캠페인이면 캠페인 한 줄, 가게면 소개의 첫 문장.
  String headline;

  CampaignListCardKind kind;

  /// STORE만. 내 활동 지역과 시·도가 다르면 가게의 시·도.
  String? otherSido;

  /// CAMPAIGN만.
  String? photoUrl;

  /// CAMPAIGN만.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? productProvided;

  /// CAMPAIGN만. 크리에이터의 협업 원칙과 겹치는 규칙.
  List<MatchReason> reasons;

  /// STORE만. 보상 세 요소를 \" + \"로 이은 짧은 글.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? rewardLine;

  /// STORE만.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  StoreSummaryModel? store;

  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignListCardModel &&
          other.brandName == brandName &&
          other.brandTagline == brandTagline &&
          other.campaignId == campaignId &&
          other.fee == fee &&
          other.headline == headline &&
          other.kind == kind &&
          other.otherSido == otherSido &&
          other.photoUrl == photoUrl &&
          other.productProvided == productProvided &&
          _deepEquality.equals(other.reasons, reasons) &&
          other.rewardLine == rewardLine &&
          other.store == store &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandName == null ? 0 : brandName!.hashCode) +
      (brandTagline == null ? 0 : brandTagline!.hashCode) +
      (campaignId == null ? 0 : campaignId!.hashCode) +
      (fee == null ? 0 : fee!.hashCode) +
      (headline.hashCode) +
      (kind.hashCode) +
      (otherSido == null ? 0 : otherSido!.hashCode) +
      (photoUrl == null ? 0 : photoUrl!.hashCode) +
      (productProvided == null ? 0 : productProvided!.hashCode) +
      (reasons.hashCode) +
      (rewardLine == null ? 0 : rewardLine!.hashCode) +
      (store == null ? 0 : store!.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'CampaignListCardModel[brandName=$brandName, brandTagline=$brandTagline, campaignId=$campaignId, fee=$fee, headline=$headline, kind=$kind, otherSido=$otherSido, photoUrl=$photoUrl, productProvided=$productProvided, reasons=$reasons, rewardLine=$rewardLine, store=$store, tags=$tags]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.brandName != null) {
      json[r'brandName'] = this.brandName;
    } else {
      json[r'brandName'] = null;
    }
    if (this.brandTagline != null) {
      json[r'brandTagline'] = this.brandTagline;
    } else {
      json[r'brandTagline'] = null;
    }
    if (this.campaignId != null) {
      json[r'campaignId'] = this.campaignId;
    } else {
      json[r'campaignId'] = null;
    }
    if (this.fee != null) {
      json[r'fee'] = this.fee;
    } else {
      json[r'fee'] = null;
    }
    json[r'headline'] = this.headline;
    json[r'kind'] = this.kind;
    if (this.otherSido != null) {
      json[r'otherSido'] = this.otherSido;
    } else {
      json[r'otherSido'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photoUrl'] = this.photoUrl;
    } else {
      json[r'photoUrl'] = null;
    }
    if (this.productProvided != null) {
      json[r'productProvided'] = this.productProvided;
    } else {
      json[r'productProvided'] = null;
    }
    json[r'reasons'] = this.reasons;
    if (this.rewardLine != null) {
      json[r'rewardLine'] = this.rewardLine;
    } else {
      json[r'rewardLine'] = null;
    }
    if (this.store != null) {
      json[r'store'] = this.store;
    } else {
      json[r'store'] = null;
    }
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [CampaignListCardModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CampaignListCardModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'headline'),
            'Required key "CampaignListCardModel[headline]" is missing from JSON.');
        assert(json[r'headline'] != null,
            'Required key "CampaignListCardModel[headline]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "CampaignListCardModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "CampaignListCardModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'tags'),
            'Required key "CampaignListCardModel[tags]" is missing from JSON.');
        assert(json[r'tags'] != null,
            'Required key "CampaignListCardModel[tags]" has a null value in JSON.');
        return true;
      }());

      return CampaignListCardModel(
        brandName: mapValueOfType<String>(json, r'brandName'),
        brandTagline: mapValueOfType<String>(json, r'brandTagline'),
        campaignId: mapValueOfType<String>(json, r'campaignId'),
        fee: mapValueOfType<int>(json, r'fee'),
        headline: mapValueOfType<String>(json, r'headline')!,
        kind: CampaignListCardKind.fromJson(json[r'kind'])!,
        otherSido: mapValueOfType<String>(json, r'otherSido'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl'),
        productProvided: mapValueOfType<bool>(json, r'productProvided'),
        reasons: MatchReason.listFromJson(json[r'reasons']),
        rewardLine: mapValueOfType<String>(json, r'rewardLine'),
        store: StoreSummaryModel.fromJson(json[r'store']),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<CampaignListCardModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CampaignListCardModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CampaignListCardModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CampaignListCardModel> mapFromJson(dynamic json) {
    final map = <String, CampaignListCardModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CampaignListCardModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CampaignListCardModel-objects as value to a dart map
  static Map<String, List<CampaignListCardModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CampaignListCardModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CampaignListCardModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'headline',
    'kind',
    'tags',
  };
}
