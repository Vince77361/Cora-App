//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class AnalyzeStoreLinksResultModel {
  /// Returns a new [AnalyzeStoreLinksResultModel] instance.
  AnalyzeStoreLinksResultModel({
    required this.analysisFailed,
    required this.store,
  });

  bool analysisFailed;

  MyStoreModel store;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzeStoreLinksResultModel &&
          other.analysisFailed == analysisFailed &&
          other.store == store;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (analysisFailed.hashCode) + (store.hashCode);

  @override
  String toString() =>
      'AnalyzeStoreLinksResultModel[analysisFailed=$analysisFailed, store=$store]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'analysisFailed'] = this.analysisFailed;
    json[r'store'] = this.store;
    return json;
  }

  /// Returns a new [AnalyzeStoreLinksResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyzeStoreLinksResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'analysisFailed'),
            'Required key "AnalyzeStoreLinksResultModel[analysisFailed]" is missing from JSON.');
        assert(json[r'analysisFailed'] != null,
            'Required key "AnalyzeStoreLinksResultModel[analysisFailed]" has a null value in JSON.');
        assert(json.containsKey(r'store'),
            'Required key "AnalyzeStoreLinksResultModel[store]" is missing from JSON.');
        assert(json[r'store'] != null,
            'Required key "AnalyzeStoreLinksResultModel[store]" has a null value in JSON.');
        return true;
      }());

      return AnalyzeStoreLinksResultModel(
        analysisFailed: mapValueOfType<bool>(json, r'analysisFailed')!,
        store: MyStoreModel.fromJson(json[r'store'])!,
      );
    }
    return null;
  }

  static List<AnalyzeStoreLinksResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AnalyzeStoreLinksResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyzeStoreLinksResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyzeStoreLinksResultModel> mapFromJson(dynamic json) {
    final map = <String, AnalyzeStoreLinksResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyzeStoreLinksResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyzeStoreLinksResultModel-objects as value to a dart map
  static Map<String, List<AnalyzeStoreLinksResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AnalyzeStoreLinksResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyzeStoreLinksResultModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'analysisFailed',
    'store',
  };
}
