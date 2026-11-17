//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class InquiryResultModel {
  /// Returns a new [InquiryResultModel] instance.
  InquiryResultModel({
    required this.collaborationId,
    required this.conversationId,
  });

  /// 만들어진 협업(단계 INQUIRY)의 id.
  String collaborationId;

  /// 메시지 요청 상태로 만들어진 대화방의 id.
  String conversationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InquiryResultModel &&
          other.collaborationId == collaborationId &&
          other.conversationId == conversationId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId.hashCode) + (conversationId.hashCode);

  @override
  String toString() =>
      'InquiryResultModel[collaborationId=$collaborationId, conversationId=$conversationId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'collaborationId'] = this.collaborationId;
    json[r'conversationId'] = this.conversationId;
    return json;
  }

  /// Returns a new [InquiryResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InquiryResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "InquiryResultModel[collaborationId]" is missing from JSON.');
        assert(json[r'collaborationId'] != null,
            'Required key "InquiryResultModel[collaborationId]" has a null value in JSON.');
        assert(json.containsKey(r'conversationId'),
            'Required key "InquiryResultModel[conversationId]" is missing from JSON.');
        assert(json[r'conversationId'] != null,
            'Required key "InquiryResultModel[conversationId]" has a null value in JSON.');
        return true;
      }());

      return InquiryResultModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId')!,
        conversationId: mapValueOfType<String>(json, r'conversationId')!,
      );
    }
    return null;
  }

  static List<InquiryResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InquiryResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InquiryResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InquiryResultModel> mapFromJson(dynamic json) {
    final map = <String, InquiryResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InquiryResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InquiryResultModel-objects as value to a dart map
  static Map<String, List<InquiryResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InquiryResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InquiryResultModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'collaborationId',
    'conversationId',
  };
}
