//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class OfferTermsModel {
  /// Returns a new [OfferTermsModel] instance.
  OfferTermsModel({
    required this.fixedCash,
    required this.format,
    required this.maxCashBurden,
    required this.perViewCap,
    required this.pieces,
    required this.settlementMethod,
    required this.usageRights,
    required this.viewRatePerThousand,
    required this.voucherName,
    required this.voucherPeople,
    required this.voucherValue,
  });

  /// 고정 현금(원). 없으면 0.
  int fixedCash;

  ContentFormat format;

  /// 최대 현금 부담. 고정 현금 + 조회수 수당 상한이다.
  int maxCashBurden;

  /// 조회수 수당 상한(원). 수당이 없으면 null.
  int? perViewCap;

  /// 콘텐츠 편 수. 오퍼는 지금 한 편이다.
  int pieces;

  SettlementMethod settlementMethod;

  UsageRights usageRights;

  /// 조회수 수당 단가. 1,000회당 원이다. 수당이 없으면 null.
  int? viewRatePerThousand;

  String? voucherName;

  int? voucherPeople;

  int? voucherValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferTermsModel &&
          other.fixedCash == fixedCash &&
          other.format == format &&
          other.maxCashBurden == maxCashBurden &&
          other.perViewCap == perViewCap &&
          other.pieces == pieces &&
          other.settlementMethod == settlementMethod &&
          other.usageRights == usageRights &&
          other.viewRatePerThousand == viewRatePerThousand &&
          other.voucherName == voucherName &&
          other.voucherPeople == voucherPeople &&
          other.voucherValue == voucherValue;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (fixedCash.hashCode) +
      (format.hashCode) +
      (maxCashBurden.hashCode) +
      (perViewCap == null ? 0 : perViewCap!.hashCode) +
      (pieces.hashCode) +
      (settlementMethod.hashCode) +
      (usageRights.hashCode) +
      (viewRatePerThousand == null ? 0 : viewRatePerThousand!.hashCode) +
      (voucherName == null ? 0 : voucherName!.hashCode) +
      (voucherPeople == null ? 0 : voucherPeople!.hashCode) +
      (voucherValue == null ? 0 : voucherValue!.hashCode);

  @override
  String toString() =>
      'OfferTermsModel[fixedCash=$fixedCash, format=$format, maxCashBurden=$maxCashBurden, perViewCap=$perViewCap, pieces=$pieces, settlementMethod=$settlementMethod, usageRights=$usageRights, viewRatePerThousand=$viewRatePerThousand, voucherName=$voucherName, voucherPeople=$voucherPeople, voucherValue=$voucherValue]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'fixedCash'] = this.fixedCash;
    json[r'format'] = this.format;
    json[r'maxCashBurden'] = this.maxCashBurden;
    if (this.perViewCap != null) {
      json[r'perViewCap'] = this.perViewCap;
    } else {
      json[r'perViewCap'] = null;
    }
    json[r'pieces'] = this.pieces;
    json[r'settlementMethod'] = this.settlementMethod;
    json[r'usageRights'] = this.usageRights;
    if (this.viewRatePerThousand != null) {
      json[r'viewRatePerThousand'] = this.viewRatePerThousand;
    } else {
      json[r'viewRatePerThousand'] = null;
    }
    if (this.voucherName != null) {
      json[r'voucherName'] = this.voucherName;
    } else {
      json[r'voucherName'] = null;
    }
    if (this.voucherPeople != null) {
      json[r'voucherPeople'] = this.voucherPeople;
    } else {
      json[r'voucherPeople'] = null;
    }
    if (this.voucherValue != null) {
      json[r'voucherValue'] = this.voucherValue;
    } else {
      json[r'voucherValue'] = null;
    }
    return json;
  }

  /// Returns a new [OfferTermsModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OfferTermsModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'fixedCash'),
            'Required key "OfferTermsModel[fixedCash]" is missing from JSON.');
        assert(json[r'fixedCash'] != null,
            'Required key "OfferTermsModel[fixedCash]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "OfferTermsModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "OfferTermsModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'maxCashBurden'),
            'Required key "OfferTermsModel[maxCashBurden]" is missing from JSON.');
        assert(json[r'maxCashBurden'] != null,
            'Required key "OfferTermsModel[maxCashBurden]" has a null value in JSON.');
        assert(json.containsKey(r'perViewCap'),
            'Required key "OfferTermsModel[perViewCap]" is missing from JSON.');
        assert(json.containsKey(r'pieces'),
            'Required key "OfferTermsModel[pieces]" is missing from JSON.');
        assert(json[r'pieces'] != null,
            'Required key "OfferTermsModel[pieces]" has a null value in JSON.');
        assert(json.containsKey(r'settlementMethod'),
            'Required key "OfferTermsModel[settlementMethod]" is missing from JSON.');
        assert(json[r'settlementMethod'] != null,
            'Required key "OfferTermsModel[settlementMethod]" has a null value in JSON.');
        assert(json.containsKey(r'usageRights'),
            'Required key "OfferTermsModel[usageRights]" is missing from JSON.');
        assert(json[r'usageRights'] != null,
            'Required key "OfferTermsModel[usageRights]" has a null value in JSON.');
        assert(json.containsKey(r'viewRatePerThousand'),
            'Required key "OfferTermsModel[viewRatePerThousand]" is missing from JSON.');
        assert(json.containsKey(r'voucherName'),
            'Required key "OfferTermsModel[voucherName]" is missing from JSON.');
        assert(json.containsKey(r'voucherPeople'),
            'Required key "OfferTermsModel[voucherPeople]" is missing from JSON.');
        assert(json.containsKey(r'voucherValue'),
            'Required key "OfferTermsModel[voucherValue]" is missing from JSON.');
        return true;
      }());

      return OfferTermsModel(
        fixedCash: mapValueOfType<int>(json, r'fixedCash')!,
        format: ContentFormat.fromJson(json[r'format'])!,
        maxCashBurden: mapValueOfType<int>(json, r'maxCashBurden')!,
        perViewCap: mapValueOfType<int>(json, r'perViewCap'),
        pieces: mapValueOfType<int>(json, r'pieces')!,
        settlementMethod: SettlementMethod.fromJson(json[r'settlementMethod'])!,
        usageRights: UsageRights.fromJson(json[r'usageRights'])!,
        viewRatePerThousand: mapValueOfType<int>(json, r'viewRatePerThousand'),
        voucherName: mapValueOfType<String>(json, r'voucherName'),
        voucherPeople: mapValueOfType<int>(json, r'voucherPeople'),
        voucherValue: mapValueOfType<int>(json, r'voucherValue'),
      );
    }
    return null;
  }

  static List<OfferTermsModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferTermsModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferTermsModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OfferTermsModel> mapFromJson(dynamic json) {
    final map = <String, OfferTermsModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OfferTermsModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OfferTermsModel-objects as value to a dart map
  static Map<String, List<OfferTermsModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OfferTermsModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OfferTermsModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fixedCash',
    'format',
    'maxCashBurden',
    'perViewCap',
    'pieces',
    'settlementMethod',
    'usageRights',
    'viewRatePerThousand',
    'voucherName',
    'voucherPeople',
    'voucherValue',
  };
}
