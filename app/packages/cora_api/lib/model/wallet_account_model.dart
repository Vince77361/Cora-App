//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class WalletAccountModel {
  /// Returns a new [WalletAccountModel] instance.
  WalletAccountModel({
    required this.accountLast4,
    required this.bankFullName,
    required this.bankName,
    required this.holderName,
  });

  /// 계좌번호 뒤 4자리. 전체 번호는 나가지 않는다.
  String accountLast4;

  /// 화면에 보이는 은행 이름. 예: 국민은행
  String bankFullName;

  /// 짧은 은행 이름. 예: 국민
  String bankName;

  String holderName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletAccountModel &&
          other.accountLast4 == accountLast4 &&
          other.bankFullName == bankFullName &&
          other.bankName == bankName &&
          other.holderName == holderName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accountLast4.hashCode) +
      (bankFullName.hashCode) +
      (bankName.hashCode) +
      (holderName.hashCode);

  @override
  String toString() =>
      'WalletAccountModel[accountLast4=$accountLast4, bankFullName=$bankFullName, bankName=$bankName, holderName=$holderName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'accountLast4'] = this.accountLast4;
    json[r'bankFullName'] = this.bankFullName;
    json[r'bankName'] = this.bankName;
    json[r'holderName'] = this.holderName;
    return json;
  }

  /// Returns a new [WalletAccountModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WalletAccountModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'accountLast4'),
            'Required key "WalletAccountModel[accountLast4]" is missing from JSON.');
        assert(json[r'accountLast4'] != null,
            'Required key "WalletAccountModel[accountLast4]" has a null value in JSON.');
        assert(json.containsKey(r'bankFullName'),
            'Required key "WalletAccountModel[bankFullName]" is missing from JSON.');
        assert(json[r'bankFullName'] != null,
            'Required key "WalletAccountModel[bankFullName]" has a null value in JSON.');
        assert(json.containsKey(r'bankName'),
            'Required key "WalletAccountModel[bankName]" is missing from JSON.');
        assert(json[r'bankName'] != null,
            'Required key "WalletAccountModel[bankName]" has a null value in JSON.');
        assert(json.containsKey(r'holderName'),
            'Required key "WalletAccountModel[holderName]" is missing from JSON.');
        assert(json[r'holderName'] != null,
            'Required key "WalletAccountModel[holderName]" has a null value in JSON.');
        return true;
      }());

      return WalletAccountModel(
        accountLast4: mapValueOfType<String>(json, r'accountLast4')!,
        bankFullName: mapValueOfType<String>(json, r'bankFullName')!,
        bankName: mapValueOfType<String>(json, r'bankName')!,
        holderName: mapValueOfType<String>(json, r'holderName')!,
      );
    }
    return null;
  }

  static List<WalletAccountModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WalletAccountModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WalletAccountModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WalletAccountModel> mapFromJson(dynamic json) {
    final map = <String, WalletAccountModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WalletAccountModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WalletAccountModel-objects as value to a dart map
  static Map<String, List<WalletAccountModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WalletAccountModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WalletAccountModel.listFromJson(
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
    'bankFullName',
    'bankName',
    'holderName',
  };
}
