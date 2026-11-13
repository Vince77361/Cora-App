//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class StoreProposalResultModel {
  /// Returns a new [StoreProposalResultModel] instance.
  StoreProposalResultModel({
    required this.offerId,
    required this.version,
  });

  String offerId;

  /// 방금 낸 판본의 번호. 새 오퍼면 2다(1은 가게의 모집 조건).
  int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreProposalResultModel &&
          other.offerId == offerId &&
          other.version == version;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (offerId.hashCode) + (version.hashCode);

  @override
  String toString() =>
      'StoreProposalResultModel[offerId=$offerId, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'offerId'] = this.offerId;
    json[r'version'] = this.version;
    return json;
  }

  /// Returns a new [StoreProposalResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoreProposalResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'offerId'),
            'Required key "StoreProposalResultModel[offerId]" is missing from JSON.');
        assert(json[r'offerId'] != null,
            'Required key "StoreProposalResultModel[offerId]" has a null value in JSON.');
        assert(json.containsKey(r'version'),
            'Required key "StoreProposalResultModel[version]" is missing from JSON.');
        assert(json[r'version'] != null,
            'Required key "StoreProposalResultModel[version]" has a null value in JSON.');
        return true;
      }());

      return StoreProposalResultModel(
        offerId: mapValueOfType<String>(json, r'offerId')!,
        version: mapValueOfType<int>(json, r'version')!,
      );
    }
    return null;
  }

  static List<StoreProposalResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoreProposalResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoreProposalResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoreProposalResultModel> mapFromJson(dynamic json) {
    final map = <String, StoreProposalResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoreProposalResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoreProposalResultModel-objects as value to a dart map
  static Map<String, List<StoreProposalResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoreProposalResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoreProposalResultModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'offerId',
    'version',
  };
}
