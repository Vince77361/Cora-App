//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ContractModel {
  /// Returns a new [ContractModel] instance.
  ContractModel({
    required this.brandConsentedAt,
    required this.brandName,
    required this.concludedAt,
    required this.creatorConsentedAt,
    required this.creatorName,
    this.myConsentTexts = const [],
    required this.quote,
    required this.status,
    required this.terms,
    required this.termsVersion,
    required this.voidedNotice,
  });

  /// 결제가 승인돼 체결될 때 채워진다.
  DateTime? brandConsentedAt;

  String brandName;

  DateTime? concludedAt;

  DateTime? creatorConsentedAt;

  String creatorName;

  /// 내 쪽 확인란 세 줄. 동의할 때 이 문구를 그대로 보낸다(다르면 400). 계약할 수 없는 상태면 빈 배열.
  List<String> myConsentTexts;

  /// 브랜드에게만, 동의하면 결제할 금액(크리에이터 동의 뒤 결제 전). 서버가 계약 사본에서 계산한 값이다.
  PaymentQuoteModel? quote;

  /// NOT_READY = 양쪽이 같은 판본을 확인하기 전(미리 보기), AWAITING_CREATOR = 합의됨·크리에이터 동의 전, AWAITING_BRAND = 크리에이터 동의 뒤·브랜드 동의(결제) 전, PAYING = 브랜드가 결제 중(결제창을 연 지 60분 안), CONCLUDED = 결제가 승인돼 체결됨.
  ContractProgress status;

  /// 조건. 계약 행이 있으면 동의할 때 만든 사본이고, 없으면 최신 판본(미리 보기)이다.
  TermsVersionModel? terms;

  /// 계약이 담은(미리 보기면 최신) 판본 번호. 판본이 없으면 null.
  int? termsVersion;

  /// 내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다(앱이 \"조건이 바뀌어 동의가 취소됐어요.\" 띠를 보여 준다).
  bool voidedNotice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractModel &&
          other.brandConsentedAt == brandConsentedAt &&
          other.brandName == brandName &&
          other.concludedAt == concludedAt &&
          other.creatorConsentedAt == creatorConsentedAt &&
          other.creatorName == creatorName &&
          _deepEquality.equals(other.myConsentTexts, myConsentTexts) &&
          other.quote == quote &&
          other.status == status &&
          other.terms == terms &&
          other.termsVersion == termsVersion &&
          other.voidedNotice == voidedNotice;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (brandConsentedAt == null ? 0 : brandConsentedAt!.hashCode) +
      (brandName.hashCode) +
      (concludedAt == null ? 0 : concludedAt!.hashCode) +
      (creatorConsentedAt == null ? 0 : creatorConsentedAt!.hashCode) +
      (creatorName.hashCode) +
      (myConsentTexts.hashCode) +
      (quote == null ? 0 : quote!.hashCode) +
      (status.hashCode) +
      (terms == null ? 0 : terms!.hashCode) +
      (termsVersion == null ? 0 : termsVersion!.hashCode) +
      (voidedNotice.hashCode);

  @override
  String toString() =>
      'ContractModel[brandConsentedAt=$brandConsentedAt, brandName=$brandName, concludedAt=$concludedAt, creatorConsentedAt=$creatorConsentedAt, creatorName=$creatorName, myConsentTexts=$myConsentTexts, quote=$quote, status=$status, terms=$terms, termsVersion=$termsVersion, voidedNotice=$voidedNotice]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.brandConsentedAt != null) {
      json[r'brandConsentedAt'] =
          this.brandConsentedAt!.toUtc().toIso8601String();
    } else {
      json[r'brandConsentedAt'] = null;
    }
    json[r'brandName'] = this.brandName;
    if (this.concludedAt != null) {
      json[r'concludedAt'] = this.concludedAt!.toUtc().toIso8601String();
    } else {
      json[r'concludedAt'] = null;
    }
    if (this.creatorConsentedAt != null) {
      json[r'creatorConsentedAt'] =
          this.creatorConsentedAt!.toUtc().toIso8601String();
    } else {
      json[r'creatorConsentedAt'] = null;
    }
    json[r'creatorName'] = this.creatorName;
    json[r'myConsentTexts'] = this.myConsentTexts;
    if (this.quote != null) {
      json[r'quote'] = this.quote;
    } else {
      json[r'quote'] = null;
    }
    json[r'status'] = this.status;
    if (this.terms != null) {
      json[r'terms'] = this.terms;
    } else {
      json[r'terms'] = null;
    }
    if (this.termsVersion != null) {
      json[r'termsVersion'] = this.termsVersion;
    } else {
      json[r'termsVersion'] = null;
    }
    json[r'voidedNotice'] = this.voidedNotice;
    return json;
  }

  /// Returns a new [ContractModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContractModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'brandConsentedAt'),
            'Required key "ContractModel[brandConsentedAt]" is missing from JSON.');
        assert(json.containsKey(r'brandName'),
            'Required key "ContractModel[brandName]" is missing from JSON.');
        assert(json[r'brandName'] != null,
            'Required key "ContractModel[brandName]" has a null value in JSON.');
        assert(json.containsKey(r'concludedAt'),
            'Required key "ContractModel[concludedAt]" is missing from JSON.');
        assert(json.containsKey(r'creatorConsentedAt'),
            'Required key "ContractModel[creatorConsentedAt]" is missing from JSON.');
        assert(json.containsKey(r'creatorName'),
            'Required key "ContractModel[creatorName]" is missing from JSON.');
        assert(json[r'creatorName'] != null,
            'Required key "ContractModel[creatorName]" has a null value in JSON.');
        assert(json.containsKey(r'myConsentTexts'),
            'Required key "ContractModel[myConsentTexts]" is missing from JSON.');
        assert(json[r'myConsentTexts'] != null,
            'Required key "ContractModel[myConsentTexts]" has a null value in JSON.');
        assert(json.containsKey(r'quote'),
            'Required key "ContractModel[quote]" is missing from JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ContractModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ContractModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "ContractModel[terms]" is missing from JSON.');
        assert(json.containsKey(r'termsVersion'),
            'Required key "ContractModel[termsVersion]" is missing from JSON.');
        assert(json.containsKey(r'voidedNotice'),
            'Required key "ContractModel[voidedNotice]" is missing from JSON.');
        assert(json[r'voidedNotice'] != null,
            'Required key "ContractModel[voidedNotice]" has a null value in JSON.');
        return true;
      }());

      return ContractModel(
        brandConsentedAt: mapDateTime(json, r'brandConsentedAt', r''),
        brandName: mapValueOfType<String>(json, r'brandName')!,
        concludedAt: mapDateTime(json, r'concludedAt', r''),
        creatorConsentedAt: mapDateTime(json, r'creatorConsentedAt', r''),
        creatorName: mapValueOfType<String>(json, r'creatorName')!,
        myConsentTexts: json[r'myConsentTexts'] is Iterable
            ? (json[r'myConsentTexts'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        quote: PaymentQuoteModel.fromJson(json[r'quote']),
        status: ContractProgress.fromJson(json[r'status'])!,
        terms: TermsVersionModel.fromJson(json[r'terms']),
        termsVersion: mapValueOfType<int>(json, r'termsVersion'),
        voidedNotice: mapValueOfType<bool>(json, r'voidedNotice')!,
      );
    }
    return null;
  }

  static List<ContractModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContractModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContractModel> mapFromJson(dynamic json) {
    final map = <String, ContractModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContractModel-objects as value to a dart map
  static Map<String, List<ContractModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContractModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContractModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'brandConsentedAt',
    'brandName',
    'concludedAt',
    'creatorConsentedAt',
    'creatorName',
    'myConsentTexts',
    'quote',
    'status',
    'terms',
    'termsVersion',
    'voidedNotice',
  };
}
