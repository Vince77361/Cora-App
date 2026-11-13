//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class OfferVersionSeriesModel {
  /// Returns a new [OfferVersionSeriesModel] instance.
  OfferVersionSeriesModel({
    required this.format,
    required this.name,
    required this.note,
  });

  ContentFormat? format;

  String? name;

  String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferVersionSeriesModel &&
          other.format == format &&
          other.name == name &&
          other.note == note;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (format == null ? 0 : format!.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (note == null ? 0 : note!.hashCode);

  @override
  String toString() =>
      'OfferVersionSeriesModel[format=$format, name=$name, note=$note]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.format != null) {
      json[r'format'] = this.format;
    } else {
      json[r'format'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.note != null) {
      json[r'note'] = this.note;
    } else {
      json[r'note'] = null;
    }
    return json;
  }

  /// Returns a new [OfferVersionSeriesModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OfferVersionSeriesModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'format'),
            'Required key "OfferVersionSeriesModel[format]" is missing from JSON.');
        assert(json.containsKey(r'name'),
            'Required key "OfferVersionSeriesModel[name]" is missing from JSON.');
        assert(json.containsKey(r'note'),
            'Required key "OfferVersionSeriesModel[note]" is missing from JSON.');
        return true;
      }());

      return OfferVersionSeriesModel(
        format: ContentFormat.fromJson(json[r'format']),
        name: mapValueOfType<String>(json, r'name'),
        note: mapValueOfType<String>(json, r'note'),
      );
    }
    return null;
  }

  static List<OfferVersionSeriesModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OfferVersionSeriesModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OfferVersionSeriesModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OfferVersionSeriesModel> mapFromJson(dynamic json) {
    final map = <String, OfferVersionSeriesModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OfferVersionSeriesModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OfferVersionSeriesModel-objects as value to a dart map
  static Map<String, List<OfferVersionSeriesModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OfferVersionSeriesModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OfferVersionSeriesModel.listFromJson(
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
    'name',
    'note',
  };
}
