//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class AppConfigModel {
  /// Returns a new [AppConfigModel] instance.
  AppConfigModel({
    required this.feeRates,
    required this.reward,
  });

  FeeRatesModel feeRates;

  RewardConfigModel reward;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigModel &&
          other.feeRates == feeRates &&
          other.reward == reward;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (feeRates.hashCode) + (reward.hashCode);

  @override
  String toString() => 'AppConfigModel[feeRates=$feeRates, reward=$reward]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'feeRates'] = this.feeRates;
    json[r'reward'] = this.reward;
    return json;
  }

  /// Returns a new [AppConfigModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppConfigModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'feeRates'),
            'Required key "AppConfigModel[feeRates]" is missing from JSON.');
        assert(json[r'feeRates'] != null,
            'Required key "AppConfigModel[feeRates]" has a null value in JSON.');
        assert(json.containsKey(r'reward'),
            'Required key "AppConfigModel[reward]" is missing from JSON.');
        assert(json[r'reward'] != null,
            'Required key "AppConfigModel[reward]" has a null value in JSON.');
        return true;
      }());

      return AppConfigModel(
        feeRates: FeeRatesModel.fromJson(json[r'feeRates'])!,
        reward: RewardConfigModel.fromJson(json[r'reward'])!,
      );
    }
    return null;
  }

  static List<AppConfigModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AppConfigModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppConfigModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppConfigModel> mapFromJson(dynamic json) {
    final map = <String, AppConfigModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppConfigModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppConfigModel-objects as value to a dart map
  static Map<String, List<AppConfigModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AppConfigModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppConfigModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'feeRates',
    'reward',
  };
}
