//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ContentCountModel {
  /// Returns a new [ContentCountModel] instance.
  ContentCountModel({
    required this.count,
    required this.format,
  });

  int count;

  ContentFormat format;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentCountModel &&
          other.count == count &&
          other.format == format;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (count.hashCode) + (format.hashCode);

  @override
  String toString() => 'ContentCountModel[count=$count, format=$format]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'count'] = this.count;
    json[r'format'] = this.format;
    return json;
  }

  /// Returns a new [ContentCountModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContentCountModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'count'),
            'Required key "ContentCountModel[count]" is missing from JSON.');
        assert(json[r'count'] != null,
            'Required key "ContentCountModel[count]" has a null value in JSON.');
        assert(json.containsKey(r'format'),
            'Required key "ContentCountModel[format]" is missing from JSON.');
        assert(json[r'format'] != null,
            'Required key "ContentCountModel[format]" has a null value in JSON.');
        return true;
      }());

      return ContentCountModel(
        count: mapValueOfType<int>(json, r'count')!,
        format: ContentFormat.fromJson(json[r'format'])!,
      );
    }
    return null;
  }

  static List<ContentCountModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentCountModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentCountModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContentCountModel> mapFromJson(dynamic json) {
    final map = <String, ContentCountModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContentCountModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContentCountModel-objects as value to a dart map
  static Map<String, List<ContentCountModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContentCountModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContentCountModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'count',
    'format',
  };
}
