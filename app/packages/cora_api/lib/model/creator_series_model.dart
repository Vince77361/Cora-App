//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CreatorSeriesModel {
  /// Returns a new [CreatorSeriesModel] instance.
  CreatorSeriesModel({
    required this.format,
    required this.id,
    required this.name,
    required this.note,
  });

  ContentFormat format;

  String id;

  String name;

  String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatorSeriesModel &&
          other.format == format &&
          other.id == id &&
          other.name == name &&
          other.note == note;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format.hashCode) +
      (id.hashCode) +
      (name.hashCode) +
      (note == null ? 0 : note!.hashCode);

  @override
  String toString() =>
      'CreatorSeriesModel[format=$format, id=$id, name=$name, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'format'] = this.format;
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [CreatorSeriesModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatorSeriesModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "CreatorSeriesModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "CreatorSeriesModel[format]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "CreatorSeriesModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CreatorSeriesModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'),
            'Required key "CreatorSeriesModel[name]" is missing from JSON.');
        assert(json[r'name'] != null,
            'Required key "CreatorSeriesModel[name]" has a null value in JSON.');
        assert(json.containsKey(r'note'),
            'Required key "CreatorSeriesModel[note]" is missing from JSON.');
        return true;
      }());

      return CreatorSeriesModel(
        format: ContentFormat.fromJson(json[r'format'])!,
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<CreatorSeriesModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreatorSeriesModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatorSeriesModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatorSeriesModel> mapFromJson(dynamic json) {
    final map = <String, CreatorSeriesModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatorSeriesModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatorSeriesModel-objects as value to a dart map
  static Map<String, List<CreatorSeriesModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreatorSeriesModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatorSeriesModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'format',
    'id',
    'name',
    'note',
  };
}
