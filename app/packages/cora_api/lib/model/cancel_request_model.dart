//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CancelRequestModel {
  /// Returns a new [CancelRequestModel] instance.
  CancelRequestModel({
    required this.expiresAt,
    required this.id,
    required this.requestedByMe,
  });

  /// 이 시각까지 답이 없으면 요청이 사라진다(ISO 8601).
  DateTime expiresAt;

  String id;

  /// 내가 보낸 요청이면 true(사장님), 받은 요청이면 false(크리에이터).
  bool requestedByMe;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelRequestModel &&
          other.expiresAt == expiresAt &&
          other.id == id &&
          other.requestedByMe == requestedByMe;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (expiresAt.hashCode) + (id.hashCode) + (requestedByMe.hashCode);

  @override
  String toString() =>
      'CancelRequestModel[expiresAt=$expiresAt, id=$id, requestedByMe=$requestedByMe]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    json[r'id'] = this.id;
    json[r'requestedByMe'] = this.requestedByMe;
    return json;
  }

  /// Returns a new [CancelRequestModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CancelRequestModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'expiresAt'),
            'Required key "CancelRequestModel[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null,
            'Required key "CancelRequestModel[expiresAt]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "CancelRequestModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CancelRequestModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'requestedByMe'),
            'Required key "CancelRequestModel[requestedByMe]" is missing from JSON.');
        assert(json[r'requestedByMe'] != null,
            'Required key "CancelRequestModel[requestedByMe]" has a null value in JSON.');
        return true;
      }());

      return CancelRequestModel(
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
        id: mapValueOfType<String>(json, r'id')!,
        requestedByMe: mapValueOfType<bool>(json, r'requestedByMe')!,
      );
    }
    return null;
  }

  static List<CancelRequestModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CancelRequestModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CancelRequestModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CancelRequestModel> mapFromJson(dynamic json) {
    final map = <String, CancelRequestModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CancelRequestModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CancelRequestModel-objects as value to a dart map
  static Map<String, List<CancelRequestModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CancelRequestModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CancelRequestModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'expiresAt',
    'id',
    'requestedByMe',
  };
}
