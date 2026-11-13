//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RewardConfigModel {
  /// Returns a new [RewardConfigModel] instance.
  RewardConfigModel({
    required this.countingDays,
    required this.fixedCash,
    required this.perViewCap,
    required this.usageRightsDefault,
    required this.viewRate,
    required this.voucher,
  });

  /// 게시 뒤 조회수를 재는 기간(일).
  int countingDays;

  FixedCashRangeModel fixedCash;

  /// 조회수 수당 상한(원).
  RewardRangeModel perViewCap;

  UsageRights usageRightsDefault;

  /// 1,000회당 원.
  RewardRangeModel viewRate;

  VoucherDefaultsModel voucher;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardConfigModel &&
          other.countingDays == countingDays &&
          other.fixedCash == fixedCash &&
          other.perViewCap == perViewCap &&
          other.usageRightsDefault == usageRightsDefault &&
          other.viewRate == viewRate &&
          other.voucher == voucher;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (countingDays.hashCode) +
      (fixedCash.hashCode) +
      (perViewCap.hashCode) +
      (usageRightsDefault.hashCode) +
      (viewRate.hashCode) +
      (voucher.hashCode);

  @override
  String toString() =>
      'RewardConfigModel[countingDays=$countingDays, fixedCash=$fixedCash, perViewCap=$perViewCap, usageRightsDefault=$usageRightsDefault, viewRate=$viewRate, voucher=$voucher]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'countingDays'] = this.countingDays;
    json[r'fixedCash'] = this.fixedCash;
    json[r'perViewCap'] = this.perViewCap;
    json[r'usageRightsDefault'] = this.usageRightsDefault;
    json[r'viewRate'] = this.viewRate;
    json[r'voucher'] = this.voucher;
    return json;
  }

  /// Returns a new [RewardConfigModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RewardConfigModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'countingDays'),
            'Required key "RewardConfigModel[countingDays]" is missing from JSON.');
        assert(json[r'countingDays'] != null,
            'Required key "RewardConfigModel[countingDays]" has a null value in JSON.');
        assert(json.containsKey(r'fixedCash'),
            'Required key "RewardConfigModel[fixedCash]" is missing from JSON.');
        assert(json[r'fixedCash'] != null,
            'Required key "RewardConfigModel[fixedCash]" has a null value in JSON.');
        assert(json.containsKey(r'perViewCap'),
            'Required key "RewardConfigModel[perViewCap]" is missing from JSON.');
        assert(json[r'perViewCap'] != null,
            'Required key "RewardConfigModel[perViewCap]" has a null value in JSON.');
        assert(json.containsKey(r'usageRightsDefault'),
            'Required key "RewardConfigModel[usageRightsDefault]" is missing from JSON.');
        assert(json[r'usageRightsDefault'] != null,
            'Required key "RewardConfigModel[usageRightsDefault]" has a null value in JSON.');
        assert(json.containsKey(r'viewRate'),
            'Required key "RewardConfigModel[viewRate]" is missing from JSON.');
        assert(json[r'viewRate'] != null,
            'Required key "RewardConfigModel[viewRate]" has a null value in JSON.');
        assert(json.containsKey(r'voucher'),
            'Required key "RewardConfigModel[voucher]" is missing from JSON.');
        assert(json[r'voucher'] != null,
            'Required key "RewardConfigModel[voucher]" has a null value in JSON.');
        return true;
      }());

      return RewardConfigModel(
        countingDays: mapValueOfType<int>(json, r'countingDays')!,
        fixedCash: FixedCashRangeModel.fromJson(json[r'fixedCash'])!,
        perViewCap: RewardRangeModel.fromJson(json[r'perViewCap'])!,
        usageRightsDefault: UsageRights.fromJson(json[r'usageRightsDefault'])!,
        viewRate: RewardRangeModel.fromJson(json[r'viewRate'])!,
        voucher: VoucherDefaultsModel.fromJson(json[r'voucher'])!,
      );
    }
    return null;
  }

  static List<RewardConfigModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RewardConfigModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RewardConfigModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RewardConfigModel> mapFromJson(dynamic json) {
    final map = <String, RewardConfigModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RewardConfigModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RewardConfigModel-objects as value to a dart map
  static Map<String, List<RewardConfigModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RewardConfigModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RewardConfigModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'countingDays',
    'fixedCash',
    'perViewCap',
    'usageRightsDefault',
    'viewRate',
    'voucher',
  };
}
