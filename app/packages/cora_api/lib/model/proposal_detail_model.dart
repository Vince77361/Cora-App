//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class ProposalDetailModel {
  /// Returns a new [ProposalDetailModel] instance.
  ProposalDetailModel({
    this.changed = const [],
    required this.collaborationId,
    required this.counterpart,
    required this.endKind,
    required this.endReason,
    required this.expiresAt,
    required this.feeRate,
    required this.group,
    required this.latest,
    required this.myParty,
    required this.needsInstagram,
    required this.offerId,
    required this.previous,
    required this.status,
    required this.store,
  });

  /// 앞 판본과 달라진 항목(FORMAT, VOUCHER, FIXED_CASH, VIEW_PAY, USAGE_RIGHTS, IDEA, PRINCIPLES, SERIES). 화면이 보여 주는 순서다.
  List<String> changed;

  String? collaborationId;

  /// 상대. 사장님에게는 크리에이터, 크리에이터에게는 가게의 사장님이다(이름과 사진은 가게의 것).
  ProposalPersonModel counterpart;

  ProposalEndKind? endKind;

  OfferEndReason? endReason;

  /// 응답 기한(ISO 8601).
  DateTime expiresAt;

  /// 결제 때 더해지는 수수료율(%).
  int feeRate;

  ProposalGroup group;

  OfferVersionModel latest;

  /// 이 제안에서 나는 어느 쪽인가.
  OfferParty myParty;

  /// 답을 기다리는 제안이고 조회수 수당이 켜져 있는데 크리에이터가 인스타그램을 연동하지 않았으면 true.
  bool needsInstagram;

  String offerId;

  /// 바로 앞 판본. 첫 판본이면 null.
  OfferVersionModel? previous;

  /// 내가 보는 상태. 크리에이터가 방금 거절해 되돌릴 수 있는 동안 사장님에게는 WAITING이다.
  OfferView status;

  ProposalStoreModel store;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProposalDetailModel &&
          _deepEquality.equals(other.changed, changed) &&
          other.collaborationId == collaborationId &&
          other.counterpart == counterpart &&
          other.endKind == endKind &&
          other.endReason == endReason &&
          other.expiresAt == expiresAt &&
          other.feeRate == feeRate &&
          other.group == group &&
          other.latest == latest &&
          other.myParty == myParty &&
          other.needsInstagram == needsInstagram &&
          other.offerId == offerId &&
          other.previous == previous &&
          other.status == status &&
          other.store == store;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (changed.hashCode) +
      (collaborationId == null ? 0 : collaborationId!.hashCode) +
      (counterpart.hashCode) +
      (endKind == null ? 0 : endKind!.hashCode) +
      (endReason == null ? 0 : endReason!.hashCode) +
      (expiresAt.hashCode) +
      (feeRate.hashCode) +
      (group.hashCode) +
      (latest.hashCode) +
      (myParty.hashCode) +
      (needsInstagram.hashCode) +
      (offerId.hashCode) +
      (previous == null ? 0 : previous!.hashCode) +
      (status.hashCode) +
      (store.hashCode);

  @override
  String toString() =>
      'ProposalDetailModel[changed=$changed, collaborationId=$collaborationId, counterpart=$counterpart, endKind=$endKind, endReason=$endReason, expiresAt=$expiresAt, feeRate=$feeRate, group=$group, latest=$latest, myParty=$myParty, needsInstagram=$needsInstagram, offerId=$offerId, previous=$previous, status=$status, store=$store]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'changed'] = this.changed;
    if (this.collaborationId != null) {
      json[r'collaborationId'] = this.collaborationId;
    } else {
      json[r'collaborationId'] = null;
    }
    json[r'counterpart'] = this.counterpart;
    if (this.endKind != null) {
      json[r'endKind'] = this.endKind;
    } else {
      json[r'endKind'] = null;
    }
    if (this.endReason != null) {
      json[r'endReason'] = this.endReason;
    } else {
      json[r'endReason'] = null;
    }
    json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    json[r'feeRate'] = this.feeRate;
    json[r'group'] = this.group;
    json[r'latest'] = this.latest;
    json[r'myParty'] = this.myParty;
    json[r'needsInstagram'] = this.needsInstagram;
    json[r'offerId'] = this.offerId;
    if (this.previous != null) {
      json[r'previous'] = this.previous;
    } else {
      json[r'previous'] = null;
    }
    json[r'status'] = this.status;
    json[r'store'] = this.store;
    return json;
  }

  /// Returns a new [ProposalDetailModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProposalDetailModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'changed'),
            'Required key "ProposalDetailModel[changed]" is missing from JSON.');
        assert(json[r'changed'] != null,
            'Required key "ProposalDetailModel[changed]" has a null value in JSON.');
        assert(json.containsKey(r'collaborationId'),
            'Required key "ProposalDetailModel[collaborationId]" is missing from JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "ProposalDetailModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "ProposalDetailModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'endKind'),
            'Required key "ProposalDetailModel[endKind]" is missing from JSON.');
        assert(json.containsKey(r'endReason'),
            'Required key "ProposalDetailModel[endReason]" is missing from JSON.');
        assert(json.containsKey(r'expiresAt'),
            'Required key "ProposalDetailModel[expiresAt]" is missing from JSON.');
        assert(json[r'expiresAt'] != null,
            'Required key "ProposalDetailModel[expiresAt]" has a null value in JSON.');
        assert(json.containsKey(r'feeRate'),
            'Required key "ProposalDetailModel[feeRate]" is missing from JSON.');
        assert(json[r'feeRate'] != null,
            'Required key "ProposalDetailModel[feeRate]" has a null value in JSON.');
        assert(json.containsKey(r'group'),
            'Required key "ProposalDetailModel[group]" is missing from JSON.');
        assert(json[r'group'] != null,
            'Required key "ProposalDetailModel[group]" has a null value in JSON.');
        assert(json.containsKey(r'latest'),
            'Required key "ProposalDetailModel[latest]" is missing from JSON.');
        assert(json[r'latest'] != null,
            'Required key "ProposalDetailModel[latest]" has a null value in JSON.');
        assert(json.containsKey(r'myParty'),
            'Required key "ProposalDetailModel[myParty]" is missing from JSON.');
        assert(json[r'myParty'] != null,
            'Required key "ProposalDetailModel[myParty]" has a null value in JSON.');
        assert(json.containsKey(r'needsInstagram'),
            'Required key "ProposalDetailModel[needsInstagram]" is missing from JSON.');
        assert(json[r'needsInstagram'] != null,
            'Required key "ProposalDetailModel[needsInstagram]" has a null value in JSON.');
        assert(json.containsKey(r'offerId'),
            'Required key "ProposalDetailModel[offerId]" is missing from JSON.');
        assert(json[r'offerId'] != null,
            'Required key "ProposalDetailModel[offerId]" has a null value in JSON.');
        assert(json.containsKey(r'previous'),
            'Required key "ProposalDetailModel[previous]" is missing from JSON.');
        assert(json.containsKey(r'status'),
            'Required key "ProposalDetailModel[status]" is missing from JSON.');
        assert(json[r'status'] != null,
            'Required key "ProposalDetailModel[status]" has a null value in JSON.');
        assert(json.containsKey(r'store'),
            'Required key "ProposalDetailModel[store]" is missing from JSON.');
        assert(json[r'store'] != null,
            'Required key "ProposalDetailModel[store]" has a null value in JSON.');
        return true;
      }());

      return ProposalDetailModel(
        changed: json[r'changed'] is Iterable
            ? (json[r'changed'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        collaborationId: mapValueOfType<String>(json, r'collaborationId'),
        counterpart: ProposalPersonModel.fromJson(json[r'counterpart'])!,
        endKind: ProposalEndKind.fromJson(json[r'endKind']),
        endReason: OfferEndReason.fromJson(json[r'endReason']),
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
        feeRate: mapValueOfType<int>(json, r'feeRate')!,
        group: ProposalGroup.fromJson(json[r'group'])!,
        latest: OfferVersionModel.fromJson(json[r'latest'])!,
        myParty: OfferParty.fromJson(json[r'myParty'])!,
        needsInstagram: mapValueOfType<bool>(json, r'needsInstagram')!,
        offerId: mapValueOfType<String>(json, r'offerId')!,
        previous: OfferVersionModel.fromJson(json[r'previous']),
        status: OfferView.fromJson(json[r'status'])!,
        store: ProposalStoreModel.fromJson(json[r'store'])!,
      );
    }
    return null;
  }

  static List<ProposalDetailModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ProposalDetailModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProposalDetailModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProposalDetailModel> mapFromJson(dynamic json) {
    final map = <String, ProposalDetailModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProposalDetailModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProposalDetailModel-objects as value to a dart map
  static Map<String, List<ProposalDetailModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ProposalDetailModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProposalDetailModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'changed',
    'collaborationId',
    'counterpart',
    'endKind',
    'endReason',
    'expiresAt',
    'feeRate',
    'group',
    'latest',
    'myParty',
    'needsInstagram',
    'offerId',
    'previous',
    'status',
    'store',
  };
}
