//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class RewardRangeModel {
  /// Returns a new [RewardRangeModel] instance.
  RewardRangeModel({
    required this.default_,
    required this.max,
    required this.min,
    required this.step,
  });

  int default_;

  int max;

  int min;

  int step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardRangeModel &&
          other.default_ == default_ &&
          other.max == max &&
          other.min == min &&
          other.step == step;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (default_.hashCode) + (max.hashCode) + (min.hashCode) + (step.hashCode);

  @override
  String toString() =>
      'RewardRangeModel[default_=$default_, max=$max, min=$min, step=$step]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'default'] = this.default_;
    json[r'max'] = this.max;
    json[r'min'] = this.min;
    json[r'step'] = this.step;
    return json;
  }

  /// Returns a new [RewardRangeModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RewardRangeModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'default'),
            'Required key "RewardRangeModel[default]" is missing from JSON.');
        assert(json[r'default'] != null,
            'Required key "RewardRangeModel[default]" has a null value in JSON.');
        assert(json.containsKey(r'max'),
            'Required key "RewardRangeModel[max]" is missing from JSON.');
        assert(json[r'max'] != null,
            'Required key "RewardRangeModel[max]" has a null value in JSON.');
        assert(json.containsKey(r'min'),
            'Required key "RewardRangeModel[min]" is missing from JSON.');
        assert(json[r'min'] != null,
            'Required key "RewardRangeModel[min]" has a null value in JSON.');
        assert(json.containsKey(r'step'),
            'Required key "RewardRangeModel[step]" is missing from JSON.');
        assert(json[r'step'] != null,
            'Required key "RewardRangeModel[step]" has a null value in JSON.');
        return true;
      }());

      return RewardRangeModel(
        default_: mapValueOfType<int>(json, r'default')!,
        max: mapValueOfType<int>(json, r'max')!,
        min: mapValueOfType<int>(json, r'min')!,
        step: mapValueOfType<int>(json, r'step')!,
      );
    }
    return null;
  }

  static List<RewardRangeModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RewardRangeModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RewardRangeModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RewardRangeModel> mapFromJson(dynamic json) {
    final map = <String, RewardRangeModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RewardRangeModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RewardRangeModel-objects as value to a dart map
  static Map<String, List<RewardRangeModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RewardRangeModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RewardRangeModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'default',
    'max',
    'min',
    'step',
  };
}
