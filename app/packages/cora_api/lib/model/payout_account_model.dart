//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PayoutAccountModel {
  /// Returns a new [PayoutAccountModel] instance.
  PayoutAccountModel({
    required this.accountLast4,
    required this.bankCode,
    required this.bankFullName,
    required this.bankName,
    required this.holderName,
  });

  /// 계좌번호 뒤 4자리. 전체 번호는 응답에 나가지 않는다. 화면은 뒤 2자리만 보여 준다.
  String accountLast4;

  String bankCode;

  /// 계좌 화면에 보이는 은행 이름. 예: 국민은행
  String bankFullName;

  /// 고르는 목록에 쓰는 은행 이름. 예: 국민
  String bankName;

  String holderName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayoutAccountModel &&
          other.accountLast4 == accountLast4 &&
          other.bankCode == bankCode &&
          other.bankFullName == bankFullName &&
          other.bankName == bankName &&
          other.holderName == holderName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accountLast4.hashCode) +
      (bankCode.hashCode) +
      (bankFullName.hashCode) +
      (bankName.hashCode) +
      (holderName.hashCode);

  @override
  String toString() =>
      'PayoutAccountModel[accountLast4=$accountLast4, bankCode=$bankCode, bankFullName=$bankFullName, bankName=$bankName, holderName=$holderName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'accountLast4'] = this.accountLast4;
    json[r'bankCode'] = this.bankCode;
    json[r'bankFullName'] = this.bankFullName;
    json[r'bankName'] = this.bankName;
    json[r'holderName'] = this.holderName;
    return json;
  }

  /// Returns a new [PayoutAccountModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PayoutAccountModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accountLast4'),
            'Required key "PayoutAccountModel[accountLast4]" is missing from JSON.');
        assert(json[r'accountLast4'] != null,
            'Required key "PayoutAccountModel[accountLast4]" has a null value in JSON.');
        assert(json.containsKey(r'bankCode'),
            'Required key "PayoutAccountModel[bankCode]" is missing from JSON.');
        assert(json[r'bankCode'] != null,
            'Required key "PayoutAccountModel[bankCode]" has a null value in JSON.');
        assert(json.containsKey(r'bankFullName'),
            'Required key "PayoutAccountModel[bankFullName]" is missing from JSON.');
        assert(json[r'bankFullName'] != null,
            'Required key "PayoutAccountModel[bankFullName]" has a null value in JSON.');
        assert(json.containsKey(r'bankName'),
            'Required key "PayoutAccountModel[bankName]" is missing from JSON.');
        assert(json[r'bankName'] != null,
            'Required key "PayoutAccountModel[bankName]" has a null value in JSON.');
        assert(json.containsKey(r'holderName'),
            'Required key "PayoutAccountModel[holderName]" is missing from JSON.');
        assert(json[r'holderName'] != null,
            'Required key "PayoutAccountModel[holderName]" has a null value in JSON.');
        return true;
      }());

      return PayoutAccountModel(
        accountLast4: mapValueOfType<String>(json, r'accountLast4')!,
        bankCode: mapValueOfType<String>(json, r'bankCode')!,
        bankFullName: mapValueOfType<String>(json, r'bankFullName')!,
        bankName: mapValueOfType<String>(json, r'bankName')!,
        holderName: mapValueOfType<String>(json, r'holderName')!,
      );
    }
    return null;
  }

  static List<PayoutAccountModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PayoutAccountModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PayoutAccountModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PayoutAccountModel> mapFromJson(dynamic json) {
    final map = <String, PayoutAccountModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PayoutAccountModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PayoutAccountModel-objects as value to a dart map
  static Map<String, List<PayoutAccountModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PayoutAccountModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PayoutAccountModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'accountLast4',
    'bankCode',
    'bankFullName',
    'bankName',
    'holderName',
  };
}
