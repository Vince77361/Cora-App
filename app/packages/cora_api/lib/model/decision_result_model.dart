//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class DecisionResultModel {
  /// Returns a new [DecisionResultModel] instance.
  DecisionResultModel({
    required this.collaborationId,
    required this.conversationId,
    required this.decision,
    required this.matched,
  });

  /// 서로 관심으로 생긴 협업의 id. 닿지 않았으면 null.
  String? collaborationId;

  /// 서로 관심으로 열린 대화방의 id. 닿지 않았으면 null.
  String? conversationId;

  SwipeDecisionKind decision;

  /// 이 결정으로 서로 관심이 닿았는가.
  bool matched;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecisionResultModel &&
          other.collaborationId == collaborationId &&
          other.conversationId == conversationId &&
          other.decision == decision &&
          other.matched == matched;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (conversationId == null ? 0 : conversationId!.hashCode) +
      (decision.hashCode) +
      (matched.hashCode);

  @override
  String toString() =>
      'DecisionResultModel[collaborationId=$collaborationId, conversationId=$conversationId, decision=$decision, matched=$matched]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    if (this.conversationId != null) {
      json[r'conversationId'] = this.conversationId;
    } else {
      json[r'conversationId'] = null;
    }
    json[r'decision'] = this.decision;
    json[r'matched'] = this.matched;
    return json;
  }

  /// Returns a new [DecisionResultModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DecisionResultModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'collaborationId'),
            'Required key "DecisionResultModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'conversationId'),
            'Required key "DecisionResultModel[conversationId]" is missing from JSON.');
        assert(json.containsKey(r'decision'),
            'Required key "DecisionResultModel[decision]" is missing from JSON.');
        assert(json[r'decision'] != null,
            'Required key "DecisionResultModel[decision]" has a null value in JSON.');
        assert(json.containsKey(r'matched'),
            'Required key "DecisionResultModel[matched]" is missing from JSON.');
        assert(json[r'matched'] != null,
            'Required key "DecisionResultModel[matched]" has a null value in JSON.');
        return true;
      }());

      return DecisionResultModel(
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        conversationId: mapValueOfType<String>(json, r'conversationId'),
        decision: SwipeDecisionKind.fromJson(json[r'decision'])!,
        matched: mapValueOfType<bool>(json, r'matched')!,
      );
    }
    return null;
  }

  static List<DecisionResultModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DecisionResultModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DecisionResultModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DecisionResultModel> mapFromJson(dynamic json) {
    final map = <String, DecisionResultModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DecisionResultModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DecisionResultModel-objects as value to a dart map
  static Map<String, List<DecisionResultModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DecisionResultModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DecisionResultModel.listFromJson(
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
    'decision',
    'matched',
  };
}
