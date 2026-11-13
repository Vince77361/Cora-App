//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TrialComparisonModel {
  /// Returns a new [TrialComparisonModel] instance.
  TrialComparisonModel({
    required this.cora,
    required this.trial,
  });

  CoraSideModel cora;

  TrialSideModel trial;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrialComparisonModel &&
          other.cora == cora &&
          other.trial == trial;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cora.hashCode) + (trial.hashCode);

  @override
  String toString() => 'TrialComparisonModel[cora=$cora, trial=$trial]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cora'] = this.cora;
    json[r'trial'] = this.trial;
    return json;
  }

  /// Returns a new [TrialComparisonModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrialComparisonModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cora'),
            'Required key "TrialComparisonModel[cora]" is missing from JSON.');
        assert(json[r'cora'] != null,
            'Required key "TrialComparisonModel[cora]" has a null value in JSON.');
        assert(json.containsKey(r'trial'),
            'Required key "TrialComparisonModel[trial]" is missing from JSON.');
        assert(json[r'trial'] != null,
            'Required key "TrialComparisonModel[trial]" has a null value in JSON.');
        return true;
      }());

      return TrialComparisonModel(
        cora: CoraSideModel.fromJson(json[r'cora'])!,
        trial: TrialSideModel.fromJson(json[r'trial'])!,
      );
    }
    return null;
  }

  static List<TrialComparisonModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TrialComparisonModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrialComparisonModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrialComparisonModel> mapFromJson(dynamic json) {
    final map = <String, TrialComparisonModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrialComparisonModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrialComparisonModel-objects as value to a dart map
  static Map<String, List<TrialComparisonModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TrialComparisonModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrialComparisonModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cora',
    'trial',
  };
}
