//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationSettlementModel {
  /// Returns a new [CollaborationSettlementModel] instance.
  CollaborationSettlementModel({
    required this.finalViews,
    required this.payoutAmount,
    required this.refundAmount,
  });

  /// 정산에 쓴 최종 조회수.
  int? finalViews;

  /// 크리에이터에게 가는 금액(원).
  int payoutAmount;

  /// 사장님에게 돌아가는 금액(원).
  int refundAmount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationSettlementModel &&
          other.finalViews == finalViews &&
          other.payoutAmount == payoutAmount &&
          other.refundAmount == refundAmount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (finalViews == null ? 0 : finalViews!.hashCode) +
      (payoutAmount.hashCode) +
      (refundAmount.hashCode);

  @override
  String toString() =>
      'CollaborationSettlementModel[finalViews=$finalViews, payoutAmount=$payoutAmount, refundAmount=$refundAmount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.finalViews != null) {
      json[r'finalViews'] = this.finalViews;
    } else {
      json[r'finalViews'] = null;
    }
    json[r'payoutAmount'] = this.payoutAmount;
    json[r'refundAmount'] = this.refundAmount;
    return json;
  }

  /// Returns a new [CollaborationSettlementModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollaborationSettlementModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'finalViews'),
            'Required key "CollaborationSettlementModel[finalViews]" is missing from JSON.');
        assert(json.containsKey(r'payoutAmount'),
            'Required key "CollaborationSettlementModel[payoutAmount]" is missing from JSON.');
        assert(json[r'payoutAmount'] != null,
            'Required key "CollaborationSettlementModel[payoutAmount]" has a null value in JSON.');
        assert(json.containsKey(r'refundAmount'),
            'Required key "CollaborationSettlementModel[refundAmount]" is missing from JSON.');
        assert(json[r'refundAmount'] != null,
            'Required key "CollaborationSettlementModel[refundAmount]" has a null value in JSON.');
        return true;
      }());

      return CollaborationSettlementModel(
        finalViews: mapValueOfType<int>(json, r'finalViews'),
        payoutAmount: mapValueOfType<int>(json, r'payoutAmount')!,
        refundAmount: mapValueOfType<int>(json, r'refundAmount')!,
      );
    }
    return null;
  }

  static List<CollaborationSettlementModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationSettlementModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationSettlementModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollaborationSettlementModel> mapFromJson(dynamic json) {
    final map = <String, CollaborationSettlementModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollaborationSettlementModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollaborationSettlementModel-objects as value to a dart map
  static Map<String, List<CollaborationSettlementModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CollaborationSettlementModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollaborationSettlementModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'finalViews',
    'payoutAmount',
    'refundAmount',
  };
}
