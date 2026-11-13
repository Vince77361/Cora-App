//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class FixedCashRangeModel {
  /// Returns a new [FixedCashRangeModel] instance.
  FixedCashRangeModel({
    required this.maxByCommissioner,
    this.presets = const [],
    required this.step,
  });

  FixedCashMaxModel maxByCommissioner;

  List<int> presets;

  int step;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedCashRangeModel &&
          other.maxByCommissioner == maxByCommissioner &&
          _deepEquality.equals(other.presets, presets) &&
          other.step == step;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (maxByCommissioner.hashCode) + (presets.hashCode) + (step.hashCode);

  @override
  String toString() =>
      'FixedCashRangeModel[maxByCommissioner=$maxByCommissioner, presets=$presets, step=$step]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'maxByCommissioner'] = this.maxByCommissioner;
    json[r'presets'] = this.presets;
    json[r'step'] = this.step;
    return json;
  }

  /// Returns a new [FixedCashRangeModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FixedCashRangeModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'maxByCommissioner'),
            'Required key "FixedCashRangeModel[maxByCommissioner]" is missing from JSON.');
        assert(json[r'maxByCommissioner'] != null,
            'Required key "FixedCashRangeModel[maxByCommissioner]" has a null value in JSON.');
        assert(json.containsKey(r'presets'),
            'Required key "FixedCashRangeModel[presets]" is missing from JSON.');
        assert(json[r'presets'] != null,
            'Required key "FixedCashRangeModel[presets]" has a null value in JSON.');
        assert(json.containsKey(r'step'),
            'Required key "FixedCashRangeModel[step]" is missing from JSON.');
        assert(json[r'step'] != null,
            'Required key "FixedCashRangeModel[step]" has a null value in JSON.');
        return true;
      }());

      return FixedCashRangeModel(
        maxByCommissioner:
            FixedCashMaxModel.fromJson(json[r'maxByCommissioner'])!,
        presets: json[r'presets'] is Iterable
            ? (json[r'presets'] as Iterable).cast<int>().toList(growable: false)
            : const [],
        step: mapValueOfType<int>(json, r'step')!,
      );
    }
    return null;
  }

  static List<FixedCashRangeModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FixedCashRangeModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FixedCashRangeModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FixedCashRangeModel> mapFromJson(dynamic json) {
    final map = <String, FixedCashRangeModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FixedCashRangeModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FixedCashRangeModel-objects as value to a dart map
  static Map<String, List<FixedCashRangeModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FixedCashRangeModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FixedCashRangeModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'maxByCommissioner',
    'presets',
    'step',
  };
}
