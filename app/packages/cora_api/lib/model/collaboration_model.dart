//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of cora_api;

class CollaborationModel {
  /// Returns a new [CollaborationModel] instance.
  CollaborationModel({
    required this.canCancel,
    required this.canRequestCancel,
    required this.cancelRequest,
    required this.counterpart,
    required this.countingEndsAt,
    required this.currentViews,
    required this.earnedSoFar,
    required this.escrowAmount,
    required this.expectedRefund,
    required this.id,
    required this.kind,
    required this.payoutScheduledFor,
    required this.payoutStatus,
    required this.role,
    required this.settlement,
    required this.stage,
    this.steps = const [],
    required this.store,
    required this.submitDueAt,
    required this.submittedUrl,
    required this.terms,
    required this.viewReportStatus,
  });

  /// 크리에이터가 지금 협업을 그만둘 수 있으면 true(링크를 제출하기 전).
  bool canCancel;

  /// 사장님이 지금 취소 요청을 보낼 수 있으면 true.
  bool canRequestCancel;

  /// 답을 기다리는 취소 요청.
  CancelRequestModel? cancelRequest;

  CollaborationCounterpartModel counterpart;

  /// 조회수 집계가 끝나는 시각(제출 뒤 7일).
  DateTime? countingEndsAt;

  /// 가장 최근에 읽은 조회수. 아직 읽은 값이 없으면 null.
  int? currentViews;

  /// 지금까지 받을 금액(원). 집계 중일 때 크리에이터에게만 숫자다.
  int? earnedSoFar;

  /// 결제할 때 에스크로에 맡긴 금액(원). 협업이 끝날 때까지 그대로이고, 결제 전이거나 식사권만 있으면 0.
  int escrowAmount;

  /// 예상 환급액(원). 집계 중일 때 사장님에게만 숫자다.
  int? expectedRefund;

  String id;

  CollaborationKind kind;

  /// 지급이 PENDING이고 계좌가 있을 때 송금할 지급일. 크리에이터에게만.
  DateTime? payoutScheduledFor;

  /// NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인).
  PayoutStatus payoutStatus;

  /// 내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터.
  CollaborationRole role;

  /// 정산이 확정된 뒤의 결과. 정산 전이거나(조회 자료 확인 전 포함) 식사권만 있으면 null.
  CollaborationSettlementModel? settlement;

  CollaborationStage stage;

  List<CollaborationStepModel> steps;

  /// 가게 오퍼의 가게. 브랜드 계약이거나 가게를 읽을 수 없으면 null.
  StoreSummaryModel? store;

  /// 링크 제출 기한(결제 뒤 14일).
  DateTime? submitDueAt;

  String? submittedUrl;

  /// 수락할 때의 조건(사본).
  OfferTermsModel terms;

  /// 조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중.
  CollaborationViewReportStatus viewReportStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationModel &&
          other.canCancel == canCancel &&
          other.canRequestCancel == canRequestCancel &&
          other.cancelRequest == cancelRequest &&
          other.counterpart == counterpart &&
          other.countingEndsAt == countingEndsAt &&
          other.currentViews == currentViews &&
          other.earnedSoFar == earnedSoFar &&
          other.escrowAmount == escrowAmount &&
          other.expectedRefund == expectedRefund &&
          other.id == id &&
          other.kind == kind &&
          other.payoutScheduledFor == payoutScheduledFor &&
          other.payoutStatus == payoutStatus &&
          other.role == role &&
          other.settlement == settlement &&
          other.stage == stage &&
          _deepEquality.equals(other.steps, steps) &&
          other.store == store &&
          other.submitDueAt == submitDueAt &&
          other.submittedUrl == submittedUrl &&
          other.terms == terms &&
          other.viewReportStatus == viewReportStatus;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (canCancel.hashCode) +
      (canRequestCancel.hashCode) +
      (cancelRequest == null ? 0 : cancelRequest!.hashCode) +
      (counterpart.hashCode) +
      (countingEndsAt == null ? 0 : countingEndsAt!.hashCode) +
      (currentViews == null ? 0 : currentViews!.hashCode) +
      (earnedSoFar == null ? 0 : earnedSoFar!.hashCode) +
      (escrowAmount.hashCode) +
      (expectedRefund == null ? 0 : expectedRefund!.hashCode) +
      (id.hashCode) +
      (kind.hashCode) +
      (payoutScheduledFor == null ? 0 : payoutScheduledFor!.hashCode) +
      (payoutStatus.hashCode) +
      (role.hashCode) +
      (settlement == null ? 0 : settlement!.hashCode) +
      (stage.hashCode) +
      (steps.hashCode) +
      (store == null ? 0 : store!.hashCode) +
      (submitDueAt == null ? 0 : submitDueAt!.hashCode) +
      (submittedUrl == null ? 0 : submittedUrl!.hashCode) +
      (terms.hashCode) +
      (viewReportStatus.hashCode);

  @override
  String toString() =>
      'CollaborationModel[canCancel=$canCancel, canRequestCancel=$canRequestCancel, cancelRequest=$cancelRequest, counterpart=$counterpart, countingEndsAt=$countingEndsAt, currentViews=$currentViews, earnedSoFar=$earnedSoFar, escrowAmount=$escrowAmount, expectedRefund=$expectedRefund, id=$id, kind=$kind, payoutScheduledFor=$payoutScheduledFor, payoutStatus=$payoutStatus, role=$role, settlement=$settlement, stage=$stage, steps=$steps, store=$store, submitDueAt=$submitDueAt, submittedUrl=$submittedUrl, terms=$terms, viewReportStatus=$viewReportStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'canCancel'] = this.canCancel;
    json[r'canRequestCancel'] = this.canRequestCancel;
    if (this.cancelRequest != null) {
      json[r'cancelRequest'] = this.cancelRequest;
    } else {
      json[r'cancelRequest'] = null;
    }
    json[r'counterpart'] = this.counterpart;
    if (this.countingEndsAt != null) {
      json[r'countingEndsAt'] = this.countingEndsAt!.toUtc().toIso8601String();
    } else {
      json[r'countingEndsAt'] = null;
    }
    if (this.currentViews != null) {
      json[r'currentViews'] = this.currentViews;
    } else {
      json[r'currentViews'] = null;
    }
    if (this.earnedSoFar != null) {
      json[r'earnedSoFar'] = this.earnedSoFar;
    } else {
      json[r'earnedSoFar'] = null;
    }
    json[r'escrowAmount'] = this.escrowAmount;
    if (this.expectedRefund != null) {
      json[r'expectedRefund'] = this.expectedRefund;
    } else {
      json[r'expectedRefund'] = null;
    }
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    if (this.payoutScheduledFor != null) {
      json[r'payoutScheduledFor'] =
          this.payoutScheduledFor!.toUtc().toIso8601String();
    } else {
      json[r'payoutScheduledFor'] = null;
    }
    json[r'payoutStatus'] = this.payoutStatus;
    json[r'role'] = this.role;
    if (this.settlement != null) {
      json[r'settlement'] = this.settlement;
    } else {
      json[r'settlement'] = null;
    }
    json[r'stage'] = this.stage;
    json[r'steps'] = this.steps;
    if (this.store != null) {
      json[r'store'] = this.store;
    } else {
      json[r'store'] = null;
    }
    if (this.submitDueAt != null) {
      json[r'submitDueAt'] = this.submitDueAt!.toUtc().toIso8601String();
    } else {
      json[r'submitDueAt'] = null;
    }
    if (this.submittedUrl != null) {
      json[r'submittedUrl'] = this.submittedUrl;
    } else {
      json[r'submittedUrl'] = null;
    }
    json[r'terms'] = this.terms;
    json[r'viewReportStatus'] = this.viewReportStatus;
    return json;
  }

  /// Returns a new [CollaborationModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CollaborationModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'canCancel'),
            'Required key "CollaborationModel[canCancel]" is missing from JSON.');
        assert(json[r'canCancel'] != null,
            'Required key "CollaborationModel[canCancel]" has a null value in JSON.');
        assert(json.containsKey(r'canRequestCancel'),
            'Required key "CollaborationModel[canRequestCancel]" is missing from JSON.');
        assert(json[r'canRequestCancel'] != null,
            'Required key "CollaborationModel[canRequestCancel]" has a null value in JSON.');
        assert(json.containsKey(r'cancelRequest'),
            'Required key "CollaborationModel[cancelRequest]" is missing from JSON.');
        assert(json.containsKey(r'counterpart'),
            'Required key "CollaborationModel[counterpart]" is missing from JSON.');
        assert(json[r'counterpart'] != null,
            'Required key "CollaborationModel[counterpart]" has a null value in JSON.');
        assert(json.containsKey(r'countingEndsAt'),
            'Required key "CollaborationModel[countingEndsAt]" is missing from JSON.');
        assert(json.containsKey(r'currentViews'),
            'Required key "CollaborationModel[currentViews]" is missing from JSON.');
        assert(json.containsKey(r'earnedSoFar'),
            'Required key "CollaborationModel[earnedSoFar]" is missing from JSON.');
        assert(json.containsKey(r'escrowAmount'),
            'Required key "CollaborationModel[escrowAmount]" is missing from JSON.');
        assert(json[r'escrowAmount'] != null,
            'Required key "CollaborationModel[escrowAmount]" has a null value in JSON.');
        assert(json.containsKey(r'expectedRefund'),
            'Required key "CollaborationModel[expectedRefund]" is missing from JSON.');
        assert(json.containsKey(r'id'),
            'Required key "CollaborationModel[id]" is missing from JSON.');
        assert(json[r'id'] != null,
            'Required key "CollaborationModel[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'),
            'Required key "CollaborationModel[kind]" is missing from JSON.');
        assert(json[r'kind'] != null,
            'Required key "CollaborationModel[kind]" has a null value in JSON.');
        assert(json.containsKey(r'payoutScheduledFor'),
            'Required key "CollaborationModel[payoutScheduledFor]" is missing from JSON.');
        assert(json.containsKey(r'payoutStatus'),
            'Required key "CollaborationModel[payoutStatus]" is missing from JSON.');
        assert(json[r'payoutStatus'] != null,
            'Required key "CollaborationModel[payoutStatus]" has a null value in JSON.');
        assert(json.containsKey(r'role'),
            'Required key "CollaborationModel[role]" is missing from JSON.');
        assert(json[r'role'] != null,
            'Required key "CollaborationModel[role]" has a null value in JSON.');
        assert(json.containsKey(r'settlement'),
            'Required key "CollaborationModel[settlement]" is missing from JSON.');
        assert(json.containsKey(r'stage'),
            'Required key "CollaborationModel[stage]" is missing from JSON.');
        assert(json[r'stage'] != null,
            'Required key "CollaborationModel[stage]" has a null value in JSON.');
        assert(json.containsKey(r'steps'),
            'Required key "CollaborationModel[steps]" is missing from JSON.');
        assert(json[r'steps'] != null,
            'Required key "CollaborationModel[steps]" has a null value in JSON.');
        assert(json.containsKey(r'store'),
            'Required key "CollaborationModel[store]" is missing from JSON.');
        assert(json.containsKey(r'submitDueAt'),
            'Required key "CollaborationModel[submitDueAt]" is missing from JSON.');
        assert(json.containsKey(r'submittedUrl'),
            'Required key "CollaborationModel[submittedUrl]" is missing from JSON.');
        assert(json.containsKey(r'terms'),
            'Required key "CollaborationModel[terms]" is missing from JSON.');
        assert(json[r'terms'] != null,
            'Required key "CollaborationModel[terms]" has a null value in JSON.');
        assert(json.containsKey(r'viewReportStatus'),
            'Required key "CollaborationModel[viewReportStatus]" is missing from JSON.');
        assert(json[r'viewReportStatus'] != null,
            'Required key "CollaborationModel[viewReportStatus]" has a null value in JSON.');
        return true;
      }());

      return CollaborationModel(
        canCancel: mapValueOfType<bool>(json, r'canCancel')!,
        canRequestCancel: mapValueOfType<bool>(json, r'canRequestCancel')!,
        cancelRequest: CancelRequestModel.fromJson(json[r'cancelRequest']),
        counterpart:
            CollaborationCounterpartModel.fromJson(json[r'counterpart'])!,
        countingEndsAt: mapDateTime(json, r'countingEndsAt', r''),
        currentViews: mapValueOfType<int>(json, r'currentViews'),
        earnedSoFar: mapValueOfType<int>(json, r'earnedSoFar'),
        escrowAmount: mapValueOfType<int>(json, r'escrowAmount')!,
        expectedRefund: mapValueOfType<int>(json, r'expectedRefund'),
        id: mapValueOfType<String>(json, r'id')!,
        kind: CollaborationKind.fromJson(json[r'kind'])!,
        payoutScheduledFor: mapDateTime(json, r'payoutScheduledFor', r''),
        payoutStatus: PayoutStatus.fromJson(json[r'payoutStatus'])!,
        role: CollaborationRole.fromJson(json[r'role'])!,
        settlement: CollaborationSettlementModel.fromJson(json[r'settlement']),
        stage: CollaborationStage.fromJson(json[r'stage'])!,
        steps: CollaborationStepModel.listFromJson(json[r'steps']),
        store: StoreSummaryModel.fromJson(json[r'store']),
        submitDueAt: mapDateTime(json, r'submitDueAt', r''),
        submittedUrl: mapValueOfType<String>(json, r'submittedUrl'),
        terms: OfferTermsModel.fromJson(json[r'terms'])!,
        viewReportStatus:
            CollaborationViewReportStatus.fromJson(json[r'viewReportStatus'])!,
      );
    }
    return null;
  }

  static List<CollaborationModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CollaborationModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CollaborationModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CollaborationModel> mapFromJson(dynamic json) {
    final map = <String, CollaborationModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CollaborationModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CollaborationModel-objects as value to a dart map
  static Map<String, List<CollaborationModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CollaborationModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CollaborationModel.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'canCancel',
    'canRequestCancel',
    'cancelRequest',
    'counterpart',
    'countingEndsAt',
    'currentViews',
    'earnedSoFar',
    'escrowAmount',
    'expectedRefund',
    'id',
    'kind',
    'payoutScheduledFor',
    'payoutStatus',
    'role',
    'settlement',
    'stage',
    'steps',
    'store',
    'submitDueAt',
    'submittedUrl',
    'terms',
    'viewReportStatus',
  };
}
