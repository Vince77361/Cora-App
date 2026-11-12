import '../../offer_terms/domain/offer_terms.dart';

/// 협업의 단계. 가게 오퍼가 지나는 단계만 이름을 두고, 브랜드 계약의 단계는 [other]로 묶는다
/// (이 화면은 가게 오퍼 협업만 그린다).
enum CollaborationStage {
  awaitingPayment,
  funded,
  counting,
  settled,
  refunded,
  cancelled,
  halted,
  other,
}

/// 내가 이 협업에서 맡은 쪽. A7은 크리에이터 화면이다.
enum CollaborationRole { commissioner, creator }

/// 진행 단계 다섯 개. 서버가 항상 이 순서로 보낸다.
enum StepKey { accepted, paid, visit, submit, settle }

enum StepState { done, now, todo }

/// 지급 상태. 계좌가 없으면 [needsAccount], 계좌가 있고 송금을 기다리면 [pending].
enum PayoutStatus { none, needsAccount, pending, done, failed }

class CollaborationStep {
  const CollaborationStep({required this.key, required this.state, this.at});

  final StepKey key;
  final StepState state;

  /// 그 단계가 끝난 시각. 기록이 없는 단계(방문·촬영)와 끝나지 않은 단계는 null.
  final DateTime? at;
}

/// 사장님이 보낸 취소 요청. 크리에이터에게는 `requestedByMe`가 false다.
class CancelRequest {
  const CancelRequest({
    required this.id,
    required this.expiresAt,
    required this.requestedByMe,
  });

  final String id;
  final DateTime expiresAt;
  final bool requestedByMe;
}

/// 정산 결과. 조회수를 읽지 못해 멈춘 협업은 null이다.
class CollaborationSettlement {
  const CollaborationSettlement({
    required this.finalViews,
    required this.payoutAmount,
    required this.refundAmount,
  });

  final int? finalViews;
  final int payoutAmount;
  final int refundAmount;
}

/// 서버의 `CollaborationModel`과 같은 항목. 서버가 계산한 값을 그대로 담고 앱은 다시 계산하지 않는다.
class Collaboration {
  const Collaboration({
    required this.id,
    required this.role,
    required this.stage,
    required this.counterpartName,
    required this.terms,
    required this.escrowAmount,
    required this.steps,
    this.counterpartPhotoUrl,
    this.earnedSoFar,
    this.currentViews,
    this.countingEndsAt,
    this.submitDueAt,
    this.submittedUrl,
    this.canCancel = false,
    this.canRequestCancel = false,
    this.cancelRequest,
    this.payoutStatus = PayoutStatus.none,
    this.payoutScheduledFor,
    this.settlement,
    this.expectedRefund,
  });

  final String id;
  final CollaborationRole role;
  final CollaborationStage stage;

  /// 크리에이터에게는 가게 이름, 사장님에게는 크리에이터의 활동 이름.
  final String counterpartName;
  final String? counterpartPhotoUrl;
  final OfferTerms terms;

  /// Cora가 보관하는 금액(원). 식사권만 있는 협업은 0이다.
  final int escrowAmount;
  final List<CollaborationStep> steps;

  /// 집계 중에 크리에이터에게만 오는 지금까지 번 금액.
  final int? earnedSoFar;
  final int? currentViews;
  final DateTime? countingEndsAt;
  final DateTime? submitDueAt;
  final String? submittedUrl;
  final bool canCancel;
  final bool canRequestCancel;
  final CancelRequest? cancelRequest;
  final PayoutStatus payoutStatus;

  /// 계좌가 있고 송금을 기다릴 때 지급 예정일.
  final DateTime? payoutScheduledFor;
  final CollaborationSettlement? settlement;
  final int? expectedRefund;

  /// 협업 번호의 앞 8자리. 식사권 화면과 문의 메일 제목에 쓴다.
  String get shortId => id.length <= 8 ? id : id.substring(0, 8);

  bool get hasVoucher => terms.voucherName != null;

  /// 조회수당 지급이 있는(돈이 보관되는) 협업.
  bool get hasEscrow => escrowAmount > 0;

  CollaborationStep? step(StepKey key) {
    for (final s in steps) {
      if (s.key == key) return s;
    }
    return null;
  }

  /// 지금 하는 단계(NOW). 끝난 협업에는 없다.
  StepKey? get currentStep {
    for (final s in steps) {
      if (s.state == StepState.now) return s.key;
    }
    return null;
  }
}
