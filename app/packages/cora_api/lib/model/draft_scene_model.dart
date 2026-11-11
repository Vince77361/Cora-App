//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class DraftSceneModel {
  /// Returns a new [DraftSceneModel] instance.
  DraftSceneModel({
    required this.label,
    required this.text,
    required this.usesPhoto,
  });

  String label;

  String text;

  bool usesPhoto;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftSceneModel &&
          other.label == label &&
          other.text == text &&
          other.usesPhoto == usesPhoto;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (label.hashCode) + (text.hashCode) + (usesPhoto.hashCode);

  @override
  String toString() =>
      'DraftSceneModel[label=$label, text=$text, usesPhoto=$usesPhoto]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'label'] = this.label;
    json[r'text'] = this.text;
    json[r'usesPhoto'] = this.usesPhoto;
    return json;
  }

  /// Returns a new [DraftSceneModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DraftSceneModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'label'),
            'Required key "DraftSceneModel[label]" is missing from JSON.');
        assert(json[r'label'] != null,
            'Required key "DraftSceneModel[label]" has a null value in JSON.');
        assert(json.containsKey(r'text'),
            'Required key "DraftSceneModel[text]" is missing from JSON.');
        assert(json[r'text'] != null,
            'Required key "DraftSceneModel[text]" has a null value in JSON.');
        assert(json.containsKey(r'usesPhoto'),
            'Required key "DraftSceneModel[usesPhoto]" is missing from JSON.');
        assert(json[r'usesPhoto'] != null,
            'Required key "DraftSceneModel[usesPhoto]" has a null value in JSON.');
        return true;
      }());

      return DraftSceneModel(
        label: mapValueOfType<String>(json, r'label')!,
        text: mapValueOfType<String>(json, r'text')!,
        usesPhoto: mapValueOfType<bool>(json, r'usesPhoto')!,
      );
    }
    return null;
  }

  static List<DraftSceneModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DraftSceneModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DraftSceneModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DraftSceneModel> mapFromJson(dynamic json) {
    final map = <String, DraftSceneModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DraftSceneModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DraftSceneModel-objects as value to a dart map
  static Map<String, List<DraftSceneModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DraftSceneModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DraftSceneModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'label',
    'text',
    'usesPhoto',
  };
}
