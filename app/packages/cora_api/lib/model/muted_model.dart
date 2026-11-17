//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class MutedModel {
  /// Returns a new [MutedModel] instance.
  MutedModel({
    required this.muted,
  });

  bool muted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MutedModel && other.muted == muted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (muted.hashCode);

  @override
  String toString() => 'MutedModel[muted=$muted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'muted'] = this.muted;
    return json;
  }

  /// Returns a new [MutedModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MutedModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'muted'),
            'Required key "MutedModel[muted]" is missing from JSON.');
        assert(json[r'muted'] != null,
            'Required key "MutedModel[muted]" has a null value in JSON.');
        return true;
      }());

      return MutedModel(
        muted: mapValueOfType<bool>(json, r'muted')!,
      );
    }
    return null;
  }

  static List<MutedModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MutedModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MutedModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MutedModel> mapFromJson(dynamic json) {
    final map = <String, MutedModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MutedModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MutedModel-objects as value to a dart map
  static Map<String, List<MutedModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MutedModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MutedModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'muted',
  };
}
