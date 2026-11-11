//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ReceivedOfferModel {
  /// Returns a new [ReceivedOfferModel] instance.
  ReceivedOfferModel({
    required this.bestShootingTime,
    required this.canUndoDecline,
    required this.collaborationId,
    required this.id,
    required this.receivedAt,
    required this.store,
    required this.storeIntro,
    required this.terms,
    required this.view,
  });

  String? bestShootingTime;

  /// 방금 거절해 30초 안에 되돌릴 수 있으면 true.
  bool canUndoDecline;

  /// 수락돼 만들어진 협업의 id. 수락 전이면 null.
  String? collaborationId;

  String id;

  /// 도착한 시각(ISO 8601).
  DateTime receivedAt;

  StoreSummaryModel store;

  String? storeIntro;

  OfferTermsModel terms;

  /// 크리에이터에게 보이는 상태. 거절은 바로 DECLINED로 보인다.
  OfferView view;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivedOfferModel &&
          other.bestShootingTime == bestShootingTime &&
          other.canUndoDecline == canUndoDecline &&
          other.collaborationId == collaborationId &&
          other.id == id &&
          other.receivedAt == receivedAt &&
          other.store == store &&
          other.storeIntro == storeIntro &&
          other.terms == terms &&
          other.view == view;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (bestShootingTime == null ? 0 : bestShootingTime!.hashCode) +
      (canUndoDecline.hashCode) +
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (id.hashCode) +
      (receivedAt.hashCode) +
      (store.hashCode) +
      (storeIntro == null ? 0 : storeIntro!.hashCode) +
      (terms.hashCode) +
      (view.hashCode);

  @override
  String toString() =>
      'ReceivedOfferModel[bestShootingTime=$bestShootingTime, canUndoDecline=$canUndoDecline, collaborationId=$collaborationId, id=$id, receivedAt=$receivedAt, store=$store, storeIntro=$storeIntro, terms=$terms, view=$view]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.bestShootingTime != null) {
      json[r'bestShootingTime'] = this.bestShootingTime;
    } else {
      json[r'bestShootingTime'] = null;
    }
    json[r'canUndoDecline'] = this.canUndoDecline;
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    json[r'id'] = this.id;
    json[r'receivedAt'] = this.receivedAt.toUtc().toIso8601String();
    json[r'store'] = this.store;
    if (this.storeIntro != null) {
      json[r'storeIntro'] = this.storeIntro;
    } else {
      json[r'storeIntro'] = null;
    }
    json[r'terms'] = this.terms;
    json[r'view'] = this.view;
    return json;
  }

  /// Returns a new [ReceivedOfferModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReceivedOfferModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bestShootingTime'),
            'Required key "ReceivedOfferModel[bestShootingTime]" is missing from JSON.');
        assert(json.containsKey(r'canUndoDecline'),
            'Required key "ReceivedOfferModel[canUndoDecline]" is missing from JSON.');
        assert(json[r'canUndoDecline'] != null,
            'Required key "ReceivedOfferModel[canUndoDecline]" has a null value in JSON.');
        assert(json.containsKey(r'collaborationId'),
            'Required key "ReceivedOfferModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "ReceivedOfferModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "ReceivedOfferModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'receivedAt'),
            'Required key "ReceivedOfferModel[receivedAt]" is missing from JSON.');
        assert(json[r'receivedAt'] != null,
            'Required key "ReceivedOfferModel[receivedAt]" has a null value in JSON.');
        assert(json.containsKey(r'store'),
            'Required key "ReceivedOfferModel[store]" is missing from JSON.');
        assert(json[r'store'] != null,
            'Required key "ReceivedOfferModel[store]" has a null value in JSON.');
        assert(json.containsKey(r'storeIntro'),
            'Required key "ReceivedOfferModel[storeIntro]" is missing from JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "ReceivedOfferModel[terms]" is missing from JSON.');
        assert(json[r'terms'] != null,
            'Required key "ReceivedOfferModel[terms]" has a null value in JSON.');
        assert(json.containsKey(r'view'),
            'Required key "ReceivedOfferModel[view]" is missing from JSON.');
        assert(json[r'view'] != null,
            'Required key "ReceivedOfferModel[view]" has a null value in JSON.');
        return true;
      }());

      return ReceivedOfferModel(
        bestShootingTime: mapValueOfType<String>(json, r'bestShootingTime'),
        canUndoDecline: mapValueOfType<bool>(json, r'canUndoDecline')!,
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        id: mapValueOfType<String>(json, r'id')!,
        receivedAt: mapDateTime(json, r'receivedAt', r'')!,
        store: StoreSummaryModel.fromJson(json[r'store'])!,
        storeIntro: mapValueOfType<String>(json, r'storeIntro'),
        terms: OfferTermsModel.fromJson(json[r'terms'])!,
        view: OfferView.fromJson(json[r'view'])!,
      );
    }
    return null;
  }

  static List<ReceivedOfferModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ReceivedOfferModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReceivedOfferModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReceivedOfferModel> mapFromJson(dynamic json) {
    final map = <String, ReceivedOfferModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReceivedOfferModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReceivedOfferModel-objects as value to a dart map
  static Map<String, List<ReceivedOfferModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ReceivedOfferModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReceivedOfferModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bestShootingTime',
    'canUndoDecline',
    'collaborationId',
    'id',
    'receivedAt',
    'store',
    'storeIntro',
    'terms',
    'view',
  };
}
