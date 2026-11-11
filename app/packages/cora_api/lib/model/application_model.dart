//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ApplicationModel {
  /// Returns a new [ApplicationModel] instance.
  ApplicationModel({
    required this.id,
    required this.status,
    required this.storeId,
  });

  String id;

  ApplicationStatus status;

  String storeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationModel &&
          other.id == id &&
          other.status == status &&
          other.storeId == storeId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (status.hashCode) + (storeId.hashCode);

  @override
  String toString() =>
      'ApplicationModel[id=$id, status=$status, storeId=$storeId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'status'] = this.status;
    json[r'storeId'] = this.storeId;
    return json;
  }

  /// Returns a new [ApplicationModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApplicationModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'),
            'Required key "ApplicationModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ApplicationModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ApplicationModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ApplicationModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'storeId'),
            'Required key "ApplicationModel[storeId]" is missing from JSON.');
        assert(json[r'storeId'] != null,
            'Required key "ApplicationModel[storeId]" has a null value in JSON.');
        return true;
      }());

      return ApplicationModel(
        id: mapValueOfType<String>(json, r'id')!,
        status: ApplicationStatus.fromJson(json[r'status'])!,
        storeId: mapValueOfType<String>(json, r'storeId')!,
      );
    }
    return null;
  }

  static List<ApplicationModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApplicationModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApplicationModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApplicationModel> mapFromJson(dynamic json) {
    final map = <String, ApplicationModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApplicationModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApplicationModel-objects as value to a dart map
  static Map<String, List<ApplicationModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ApplicationModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApplicationModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'storeId',
  };
}
