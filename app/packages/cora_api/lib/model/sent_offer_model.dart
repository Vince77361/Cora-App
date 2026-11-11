//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class SentOfferModel {
  /// Returns a new [SentOfferModel] instance.
  SentOfferModel({
    required this.creator,
    required this.id,
    required this.paymentDaysLeft,
    required this.sentAt,
    required this.terms,
    required this.view,
  });

  CreatorSummaryModel creator;

  String id;

  /// 수락됐고 아직 결제 기한 전일 때 남은 날(올림). 아니면 null.
  int? paymentDaysLeft;

  /// 보낸 시각(ISO 8601).
  DateTime sentAt;

  OfferTermsModel terms;

  /// 사장님에게 보이는 상태. 거절은 30초가 지나야 DECLINED로 보이고 그전에는 WAITING이다.
  OfferView view;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SentOfferModel &&
          other.creator == creator &&
          other.id == id &&
          other.paymentDaysLeft == paymentDaysLeft &&
          other.sentAt == sentAt &&
          other.terms == terms &&
          other.view == view;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (creator.hashCode) +
      (id.hashCode) +
      (paymentDaysLeft == null ? 0 : paymentDaysLeft!.hashCode) +
      (sentAt.hashCode) +
      (terms.hashCode) +
      (view.hashCode);

  @override
  String toString() =>
      'SentOfferModel[creator=$creator, id=$id, paymentDaysLeft=$paymentDaysLeft, sentAt=$sentAt, terms=$terms, view=$view]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'creator'] = this.creator;
    json[r'id'] = this.id;
    if (this.paymentDaysLeft != null) {
      json[r'paymentDaysLeft'] = this.paymentDaysLeft;
    } else {
      json[r'paymentDaysLeft'] = null;
    }
    json[r'sentAt'] = this.sentAt.toUtc().toIso8601String();
    json[r'terms'] = this.terms;
    json[r'view'] = this.view;
    return json;
  }

  /// Returns a new [SentOfferModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SentOfferModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'creator'),
            'Required key "SentOfferModel[creator]" is missing from JSON.');
        assert(json[r'creator'] != null,
            'Required key "SentOfferModel[creator]" has a null value in JSON.');
        assert(json.containsKey(r'id'),
            'Required key "SentOfferModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "SentOfferModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'paymentDaysLeft'),
            'Required key "SentOfferModel[paymentDaysLeft]" is missing from JSON.');
        assert(json.containsKey(r'sentAt'),
            'Required key "SentOfferModel[sentAt]" is missing from JSON.');
        assert(json[r'sentAt'] != null,
            'Required key "SentOfferModel[sentAt]" has a null value in JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "SentOfferModel[terms]" is missing from JSON.');
        assert(json[r'terms'] != null,
            'Required key "SentOfferModel[terms]" has a null value in JSON.');
        assert(json.containsKey(r'view'),
            'Required key "SentOfferModel[view]" is missing from JSON.');
        assert(json[r'view'] != null,
            'Required key "SentOfferModel[view]" has a null value in JSON.');
        return true;
      }());

      return SentOfferModel(
        creator: CreatorSummaryModel.fromJson(json[r'creator'])!,
        id: mapValueOfType<String>(json, r'id')!,
        paymentDaysLeft: mapValueOfType<int>(json, r'paymentDaysLeft'),
        sentAt: mapDateTime(json, r'sentAt', r'')!,
        terms: OfferTermsModel.fromJson(json[r'terms'])!,
        view: OfferView.fromJson(json[r'view'])!,
      );
    }
    return null;
  }

  static List<SentOfferModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SentOfferModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SentOfferModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SentOfferModel> mapFromJson(dynamic json) {
    final map = <String, SentOfferModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SentOfferModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SentOfferModel-objects as value to a dart map
  static Map<String, List<SentOfferModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SentOfferModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SentOfferModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'creator',
    'id',
    'paymentDaysLeft',
    'sentAt',
    'terms',
    'view',
  };
}
