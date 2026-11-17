//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class TermsHistoryModel {
  /// Returns a new [TermsHistoryModel] instance.
  TermsHistoryModel({
    required this.agreement,
    required this.editable,
    this.versions = const [],
  });

  /// 최신 판본의 확인 상태. NONE = 아무도 확인하지 않음, WAITING_BRAND = 크리에이터만 확인, WAITING_CREATOR = 브랜드만 확인, AGREED = 양쪽 확인.
  TermsAgreement agreement;

  /// 조건 수정 제안을 낼 수 있다: 협의할 수 있는 단계이고 브랜드 결제가 진행 중이 아니다.
  bool editable;

  /// 판본 목록. 최신이 먼저다.
  List<TermsVersionModel> versions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermsHistoryModel &&
          other.agreement == agreement &&
          other.editable == editable &&
          _deepEquality.equals(other.versions, versions);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agreement.hashCode) + (editable.hashCode) + (versions.hashCode);

  @override
  String toString() =>
      'TermsHistoryModel[agreement=$agreement, editable=$editable, versions=$versions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agreement'] = this.agreement;
    json[r'editable'] = this.editable;
    json[r'versions'] = this.versions;
    return json;
  }

  /// Returns a new [TermsHistoryModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TermsHistoryModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'agreement'),
            'Required key "TermsHistoryModel[agreement]" is missing from JSON.');
        assert(json[r'agreement'] != null,
            'Required key "TermsHistoryModel[agreement]" has a null value in JSON.');
        assert(json.containsKey(r'editable'),
            'Required key "TermsHistoryModel[editable]" is missing from JSON.');
        assert(json[r'editable'] != null,
            'Required key "TermsHistoryModel[editable]" has a null value in JSON.');
        assert(json.containsKey(r'versions'),
            'Required key "TermsHistoryModel[versions]" is missing from JSON.');
        assert(json[r'versions'] != null,
            'Required key "TermsHistoryModel[versions]" has a null value in JSON.');
        return true;
      }());

      return TermsHistoryModel(
        agreement: TermsAgreement.fromJson(json[r'agreement'])!,
        editable: mapValueOfType<bool>(json, r'editable')!,
        versions: TermsVersionModel.listFromJson(json[r'versions']),
      );
    }
    return null;
  }

  static List<TermsHistoryModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TermsHistoryModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TermsHistoryModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TermsHistoryModel> mapFromJson(dynamic json) {
    final map = <String, TermsHistoryModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TermsHistoryModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TermsHistoryModel-objects as value to a dart map
  static Map<String, List<TermsHistoryModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TermsHistoryModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TermsHistoryModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'agreement',
    'editable',
    'versions',
  };
}
