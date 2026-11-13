//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FeeRatesModel {
  /// Returns a new [FeeRatesModel] instance.
  FeeRatesModel({
    required this.bid,
    required this.brandContract,
    required this.storeOffer,
  });

  /// 입찰 수수료율(%).
  int bid;

  /// 브랜드 계약 수수료율(%).
  int brandContract;

  /// 가게 오퍼 수수료율(%).
  int storeOffer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeRatesModel &&
          other.bid == bid &&
          other.brandContract == brandContract &&
          other.storeOffer == storeOffer;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (bid.hashCode) + (brandContract.hashCode) + (storeOffer.hashCode);

  @override
  String toString() =>
      'FeeRatesModel[bid=$bid, brandContract=$brandContract, storeOffer=$storeOffer]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'bid'] = this.bid;
    json[r'brandContract'] = this.brandContract;
    json[r'storeOffer'] = this.storeOffer;
    return json;
  }

  /// Returns a new [FeeRatesModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeeRatesModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bid'),
            'Required key "FeeRatesModel[bid]" is missing from JSON.');
        assert(json[r'bid'] != null,
            'Required key "FeeRatesModel[bid]" has a null value in JSON.');
        assert(json.containsKey(r'brandContract'),
            'Required key "FeeRatesModel[brandContract]" is missing from JSON.');
        assert(json[r'brandContract'] != null,
            'Required key "FeeRatesModel[brandContract]" has a null value in JSON.');
        assert(json.containsKey(r'storeOffer'),
            'Required key "FeeRatesModel[storeOffer]" is missing from JSON.');
        assert(json[r'storeOffer'] != null,
            'Required key "FeeRatesModel[storeOffer]" has a null value in JSON.');
        return true;
      }());

      return FeeRatesModel(
        bid: mapValueOfType<int>(json, r'bid')!,
        brandContract: mapValueOfType<int>(json, r'brandContract')!,
        storeOffer: mapValueOfType<int>(json, r'storeOffer')!,
      );
    }
    return null;
  }

  static List<FeeRatesModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FeeRatesModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeeRatesModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeeRatesModel> mapFromJson(dynamic json) {
    final map = <String, FeeRatesModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeeRatesModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeeRatesModel-objects as value to a dart map
  static Map<String, List<FeeRatesModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FeeRatesModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeeRatesModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bid',
    'brandContract',
    'storeOffer',
  };
}
