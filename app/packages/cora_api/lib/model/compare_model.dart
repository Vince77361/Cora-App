//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CompareModel {
  /// Returns a new [CompareModel] instance.
  CompareModel({
    this.differs = const [],
    this.sides = const [],
  });

  /// 두 후보의 보이는 값이 다른 줄(앞에 점을 붙인다).
  List<CompareField> differs;

  List<CompareSideModel> sides;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompareModel &&
          _deepEquality.equals(other.differs, differs) &&
          _deepEquality.equals(other.sides, sides);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (differs.hashCode) + (sides.hashCode);

  @override
  String toString() => 'CompareModel[differs=$differs, sides=$sides]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'differs'] = this.differs;
    json[r'sides'] = this.sides;
    return json;
  }

  /// Returns a new [CompareModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CompareModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'differs'),
            'Required key "CompareModel[differs]" is missing from JSON.');
        assert(json[r'differs'] != null,
            'Required key "CompareModel[differs]" has a null value in JSON.');
        assert(json.containsKey(r'sides'),
            'Required key "CompareModel[sides]" is missing from JSON.');
        assert(json[r'sides'] != null,
            'Required key "CompareModel[sides]" has a null value in JSON.');
        return true;
      }());

      return CompareModel(
        differs: CompareField.listFromJson(json[r'differs']),
        sides: CompareSideModel.listFromJson(json[r'sides']),
      );
    }
    return null;
  }

  static List<CompareModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CompareModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CompareModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CompareModel> mapFromJson(dynamic json) {
    final map = <String, CompareModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CompareModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CompareModel-objects as value to a dart map
  static Map<String, List<CompareModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CompareModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CompareModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'differs',
    'sides',
  };
}
