//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationStepModel {
  /// Returns a new [CollaborationStepModel] instance.
  CollaborationStepModel({
    required this.at,
    required this.key,
    required this.state,
  });

  /// 그 단계가 끝난 시각. 기록이 없는 단계(방문·촬영)와 끝나지 않은 단계는 null.
  DateTime? at;

  /// 오퍼 수락, 가게 결제, 방문·촬영, 링크 제출, 조회수 집계 후 지급. 항상 이 다섯 개가 이 순서로 온다.
  CollaborationStepKey key;

  /// DONE: 끝남, NOW: 지금 하는 단계, TODO: 아직. 끝난 협업에는 NOW가 없다.
  CollaborationStepState state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationStepModel &&
          other.at == at &&
          other.key == key &&
          other.state == state;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (at == null ? 0 : at!.hashCode) + (key.hashCode) + (state.hashCode);

  @override
  String toString() => 'CollaborationStepModel[at=$at, key=$key, state=$state]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.at != null) {
      json[r'at'] = this.at!.toUtc().toIso8601String();
    } else {
      json[r'at'] = null;
    }
    json[r'key'] = this.key;
    json[r'state'] = this.state;
    return json;
  }

  /// Returns a new [CollaborationStepModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollaborationStepModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'at'),
            'Required key "CollaborationStepModel[at]" is missing from JSON.');
        assert(json.containsKey(r'key'),
            'Required key "CollaborationStepModel[key]" is missing from JSON.');
        assert(json[r'key'] != null,
            'Required key "CollaborationStepModel[key]" has a null value in JSON.');
        assert(json.containsKey(r'state'),
            'Required key "CollaborationStepModel[state]" is missing from JSON.');
        assert(json[r'state'] != null,
            'Required key "CollaborationStepModel[state]" has a null value in JSON.');
        return true;
      }());

      return CollaborationStepModel(
        at: mapDateTime(json, r'at', r''),
        key: CollaborationStepKey.fromJson(json[r'key'])!,
        state: CollaborationStepState.fromJson(json[r'state'])!,
      );
    }
    return null;
  }

  static List<CollaborationStepModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationStepModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationStepModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollaborationStepModel> mapFromJson(dynamic json) {
    final map = <String, CollaborationStepModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollaborationStepModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollaborationStepModel-objects as value to a dart map
  static Map<String, List<CollaborationStepModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CollaborationStepModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollaborationStepModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'at',
    'key',
    'state',
  };
}
