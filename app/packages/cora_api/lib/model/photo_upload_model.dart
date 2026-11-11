//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class PhotoUploadModel {
  /// Returns a new [PhotoUploadModel] instance.
  PhotoUploadModel({
    required this.path,
    required this.uploadUrl,
  });

  String path;

  String uploadUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoUploadModel &&
          other.path == path &&
          other.uploadUrl == uploadUrl;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (path.hashCode) + (uploadUrl.hashCode);

  @override
  String toString() => 'PhotoUploadModel[path=$path, uploadUrl=$uploadUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'path'] = this.path;
    json[r'uploadUrl'] = this.uploadUrl;
    return json;
  }

  /// Returns a new [PhotoUploadModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PhotoUploadModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'path'),
            'Required key "PhotoUploadModel[path]" is missing from JSON.');
        assert(json[r'path'] != null,
            'Required key "PhotoUploadModel[path]" has a null value in JSON.');
        assert(json.containsKey(r'uploadUrl'),
            'Required key "PhotoUploadModel[uploadUrl]" is missing from JSON.');
        assert(json[r'uploadUrl'] != null,
            'Required key "PhotoUploadModel[uploadUrl]" has a null value in JSON.');
        return true;
      }());

      return PhotoUploadModel(
        path: mapValueOfType<String>(json, r'path')!,
        uploadUrl: mapValueOfType<String>(json, r'uploadUrl')!,
      );
    }
    return null;
  }

  static List<PhotoUploadModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PhotoUploadModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PhotoUploadModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PhotoUploadModel> mapFromJson(dynamic json) {
    final map = <String, PhotoUploadModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PhotoUploadModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PhotoUploadModel-objects as value to a dart map
  static Map<String, List<PhotoUploadModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PhotoUploadModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PhotoUploadModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'path',
    'uploadUrl',
  };
}
