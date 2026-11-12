//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class WalletNextPayoutModel {
  /// Returns a new [WalletNextPayoutModel] instance.
  WalletNextPayoutModel({
    required this.amount,
    required this.date,
  });

  /// 그날 한국 시간으로 나갈 지급의 합(원).
  int amount;

  /// 가장 이른 지급 예정일(한국 시간 YYYY-MM-DD). 지급은 수요일 10:00에 나간다.
  String date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletNextPayoutModel &&
          other.amount == amount &&
          other.date == date;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (amount.hashCode) + (date.hashCode);

  @override
  String toString() => 'WalletNextPayoutModel[amount=$amount, date=$date]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'amount'] = this.amount;
    json[r'date'] = this.date;
    return json;
  }

  /// Returns a new [WalletNextPayoutModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WalletNextPayoutModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'amount'),
            'Required key "WalletNextPayoutModel[amount]" is missing from JSON.');
        assert(json[r'amount'] != null,
            'Required key "WalletNextPayoutModel[amount]" has a null value in JSON.');
        assert(json.containsKey(r'date'),
            'Required key "WalletNextPayoutModel[date]" is missing from JSON.');
        assert(json[r'date'] != null,
            'Required key "WalletNextPayoutModel[date]" has a null value in JSON.');
        return true;
      }());

      return WalletNextPayoutModel(
        amount: mapValueOfType<int>(json, r'amount')!,
        date: mapValueOfType<String>(json, r'date')!,
      );
    }
    return null;
  }

  static List<WalletNextPayoutModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WalletNextPayoutModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WalletNextPayoutModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WalletNextPayoutModel> mapFromJson(dynamic json) {
    final map = <String, WalletNextPayoutModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WalletNextPayoutModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WalletNextPayoutModel-objects as value to a dart map
  static Map<String, List<WalletNextPayoutModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WalletNextPayoutModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WalletNextPayoutModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'date',
  };
}
