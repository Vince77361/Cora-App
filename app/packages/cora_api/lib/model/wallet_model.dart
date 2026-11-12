//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class WalletModel {
  /// Returns a new [WalletModel] instance.
  WalletModel({
    required this.account,
    this.entries = const [],
    required this.heldAmount,
    required this.nextPayout,
    required this.receivedThisMonth,
  });

  /// 등록 전이면 null.
  WalletAccountModel? account;

  /// 기준 시각 최신순. 식사권 줄은 같은 협업의 돈 줄 바로 아래.
  List<WalletEntryModel> entries;

  /// 지금 Cora가 보관 중인 내 협업들의 금액 합(원).
  int heldAmount;

  /// 지급 예정이 없으면 null.
  WalletNextPayoutModel? nextPayout;

  /// 이번 달(한국 시간) 송금이 끝난 지급의 합(원).
  int receivedThisMonth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletModel &&
          other.account == account &&
          _deepEquality.equals(other.entries, entries) &&
          other.heldAmount == heldAmount &&
          other.nextPayout == nextPayout &&
          other.receivedThisMonth == receivedThisMonth;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (account == null ? 0 : account!.hashCode) +
      (entries.hashCode) +
      (heldAmount.hashCode) +
      (nextPayout == null ? 0 : nextPayout!.hashCode) +
      (receivedThisMonth.hashCode);

  @override
  String toString() =>
      'WalletModel[account=$account, entries=$entries, heldAmount=$heldAmount, nextPayout=$nextPayout, receivedThisMonth=$receivedThisMonth]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.account != null) {
      json[r'account'] = this.account;
    } else {
      json[r'account'] = null;
    }
    json[r'entries'] = this.entries;
    json[r'heldAmount'] = this.heldAmount;
    if (this.nextPayout != null) {
      json[r'nextPayout'] = this.nextPayout;
    } else {
      json[r'nextPayout'] = null;
    }
    json[r'receivedThisMonth'] = this.receivedThisMonth;
    return json;
  }

  /// Returns a new [WalletModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WalletModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'account'),
            'Required key "WalletModel[account]" is missing from JSON.');
        assert(json.containsKey(r'entries'),
            'Required key "WalletModel[entries]" is missing from JSON.');
        assert(json[r'entries'] != null,
            'Required key "WalletModel[entries]" has a null value in JSON.');
        assert(json.containsKey(r'heldAmount'),
            'Required key "WalletModel[heldAmount]" is missing from JSON.');
        assert(json[r'heldAmount'] != null,
            'Required key "WalletModel[heldAmount]" has a null value in JSON.');
        assert(json.containsKey(r'nextPayout'),
            'Required key "WalletModel[nextPayout]" is missing from JSON.');
        assert(json.containsKey(r'receivedThisMonth'),
            'Required key "WalletModel[receivedThisMonth]" is missing from JSON.');
        assert(json[r'receivedThisMonth'] != null,
            'Required key "WalletModel[receivedThisMonth]" has a null value in JSON.');
        return true;
      }());

      return WalletModel(
        account: WalletAccountModel.fromJson(json[r'account']),
        entries: WalletEntryModel.listFromJson(json[r'entries']),
        heldAmount: mapValueOfType<int>(json, r'heldAmount')!,
        nextPayout: WalletNextPayoutModel.fromJson(json[r'nextPayout']),
        receivedThisMonth: mapValueOfType<int>(json, r'receivedThisMonth')!,
      );
    }
    return null;
  }

  static List<WalletModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WalletModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WalletModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WalletModel> mapFromJson(dynamic json) {
    final map = <String, WalletModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WalletModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WalletModel-objects as value to a dart map
  static Map<String, List<WalletModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WalletModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WalletModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'account',
    'entries',
    'heldAmount',
    'nextPayout',
    'receivedThisMonth',
  };
}
