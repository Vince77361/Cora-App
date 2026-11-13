//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ViewReportEvidenceModel {
  /// Returns a new [ViewReportEvidenceModel] instance.
  ViewReportEvidenceModel({
    required this.imageUrl,
    required this.statedViews,
  });

  /// 캡처 이미지를 읽는 주소(당사자에게만 주는, 기한이 있는 주소). 주소를 만들지 못했으면 null이다(화면은 그림 없이 조회수만 보여 준다).
  String? imageUrl;

  /// 크리에이터가 적은 조회수.
  int statedViews;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewReportEvidenceModel &&
          other.imageUrl == imageUrl &&
          other.statedViews == statedViews;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (imageUrl == null ? 0 : imageUrl!.hashCode) + (statedViews.hashCode);

  @override
  String toString() =>
      'ViewReportEvidenceModel[imageUrl=$imageUrl, statedViews=$statedViews]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.imageUrl != null) {
      json[r'imageUrl'] = this.imageUrl;
    } else {
      json[r'imageUrl'] = null;
    }
    json[r'statedViews'] = this.statedViews;
    return json;
  }

  /// Returns a new [ViewReportEvidenceModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ViewReportEvidenceModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'imageUrl'),
            'Required key "ViewReportEvidenceModel[imageUrl]" is missing from JSON.');
        assert(json.containsKey(r'statedViews'),
            'Required key "ViewReportEvidenceModel[statedViews]" is missing from JSON.');
        assert(json[r'statedViews'] != null,
            'Required key "ViewReportEvidenceModel[statedViews]" has a null value in JSON.');
        return true;
      }());

      return ViewReportEvidenceModel(
        imageUrl: mapValueOfType<String>(json, r'imageUrl'),
        statedViews: mapValueOfType<int>(json, r'statedViews')!,
      );
    }
    return null;
  }

  static List<ViewReportEvidenceModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ViewReportEvidenceModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewReportEvidenceModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ViewReportEvidenceModel> mapFromJson(dynamic json) {
    final map = <String, ViewReportEvidenceModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ViewReportEvidenceModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ViewReportEvidenceModel-objects as value to a dart map
  static Map<String, List<ViewReportEvidenceModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ViewReportEvidenceModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ViewReportEvidenceModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'imageUrl',
    'statedViews',
  };
}
