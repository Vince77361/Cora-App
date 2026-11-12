//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class UnreadCountModel {
  /// Returns a new [UnreadCountModel] instance.
  UnreadCountModel({
    required this.count,
  });

  /// 지금 역할의 읽지 않은 알림 수(최근 90일).
  num count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnreadCountModel && other.count == count;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (count.hashCode);

  @override
  String toString() => 'UnreadCountModel[count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [UnreadCountModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnreadCountModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'count'),
            'Required key "UnreadCountModel[count]" is missing from JSON.');
        assert(json[r'count'] != null,
            'Required key "UnreadCountModel[count]" has a null value in JSON.');
        return true;
      }());

      return UnreadCountModel(
        count: num.parse('${json[r'count']}'),
      );
    }
    return null;
  }

  static List<UnreadCountModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UnreadCountModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnreadCountModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnreadCountModel> mapFromJson(dynamic json) {
    final map = <String, UnreadCountModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnreadCountModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnreadCountModel-objects as value to a dart map
  static Map<String, List<UnreadCountModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UnreadCountModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnreadCountModel.listFromJson(
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
  };
}
