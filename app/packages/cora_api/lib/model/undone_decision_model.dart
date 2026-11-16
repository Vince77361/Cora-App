//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UndoneDecisionModel {
  /// Returns a new [UndoneDecisionModel] instance.
  UndoneDecisionModel({
    required this.targetId,
    required this.targetKind,
  });

  String targetId;

  SwipeTargetKind targetKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UndoneDecisionModel &&
          other.targetId == targetId &&
          other.targetKind == targetKind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (targetId.hashCode) + (targetKind.hashCode);

  @override
  String toString() =>
      'UndoneDecisionModel[targetId=$targetId, targetKind=$targetKind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'targetId'] = this.targetId;
    json[r'targetKind'] = this.targetKind;
    return json;
  }

  /// Returns a new [UndoneDecisionModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UndoneDecisionModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'targetId'),
            'Required key "UndoneDecisionModel[targetId]" is missing from JSON.');
        assert(json[r'targetId'] != null,
            'Required key "UndoneDecisionModel[targetId]" has a null value in JSON.');
        assert(json.containsKey(r'targetKind'),
            'Required key "UndoneDecisionModel[targetKind]" is missing from JSON.');
        assert(json[r'targetKind'] != null,
            'Required key "UndoneDecisionModel[targetKind]" has a null value in JSON.');
        return true;
      }());

      return UndoneDecisionModel(
        targetId: mapValueOfType<String>(json, r'targetId')!,
        targetKind: SwipeTargetKind.fromJson(json[r'targetKind'])!,
      );
    }
    return null;
  }

  static List<UndoneDecisionModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UndoneDecisionModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UndoneDecisionModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UndoneDecisionModel> mapFromJson(dynamic json) {
    final map = <String, UndoneDecisionModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UndoneDecisionModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UndoneDecisionModel-objects as value to a dart map
  static Map<String, List<UndoneDecisionModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UndoneDecisionModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UndoneDecisionModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'targetId',
    'targetKind',
  };
}
