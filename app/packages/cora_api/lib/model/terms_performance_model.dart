//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TermsPerformanceModel {
  /// Returns a new [TermsPerformanceModel] instance.
  TermsPerformanceModel({
    required this.cap,
    required this.ratePer1000,
  });

  /// 조회수 수당 상한(원).
  int cap;

  /// 조회수 단가(1,000회당 원).
  int ratePer1000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermsPerformanceModel &&
          other.cap == cap &&
          other.ratePer1000 == ratePer1000;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cap.hashCode) + (ratePer1000.hashCode);

  @override
  String toString() =>
      'TermsPerformanceModel[cap=$cap, ratePer1000=$ratePer1000]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cap'] = this.cap;
    json[r'ratePer1000'] = this.ratePer1000;
    return json;
  }

  /// Returns a new [TermsPerformanceModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TermsPerformanceModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'cap'),
            'Required key "TermsPerformanceModel[cap]" is missing from JSON.');
        assert(json[r'cap'] != null,
            'Required key "TermsPerformanceModel[cap]" has a null value in JSON.');
        assert(json.containsKey(r'ratePer1000'),
            'Required key "TermsPerformanceModel[ratePer1000]" is missing from JSON.');
        assert(json[r'ratePer1000'] != null,
            'Required key "TermsPerformanceModel[ratePer1000]" has a null value in JSON.');
        return true;
      }());

      return TermsPerformanceModel(
        cap: mapValueOfType<int>(json, r'cap')!,
        ratePer1000: mapValueOfType<int>(json, r'ratePer1000')!,
      );
    }
    return null;
  }

  static List<TermsPerformanceModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsPerformanceModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsPerformanceModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TermsPerformanceModel> mapFromJson(dynamic json) {
    final map = <String, TermsPerformanceModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TermsPerformanceModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TermsPerformanceModel-objects as value to a dart map
  static Map<String, List<TermsPerformanceModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TermsPerformanceModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TermsPerformanceModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cap',
    'ratePer1000',
  };
}
