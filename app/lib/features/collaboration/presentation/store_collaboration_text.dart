import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/collaboration.dart';
import 'collaboration_text.dart';

// 사장님 진행 화면의 문구. 크리에이터 화면(A7)과 같은 단계를 사장님 쪽 말로 쓴다.

/// 단계 이름.
String storeStepTitle(StepKey key) => switch (key) {
  StepKey.accepted => '오퍼 수락됨',
  StepKey.paid => '결제 완료',
  StepKey.visit => '크리에이터 방문·촬영',
  StepKey.submit => '콘텐츠 게시',
  StepKey.settle => '7일 집계 후 정산',
};

/// 조회수당 지급이 있는 조건인가. 돈이 지금 보관 중인지와는 다르다(결제 전에는 보관액이 0이다).
bool hasPerViewReward(Collaboration c) =>
    c.terms.rewardType != RewardType.voucher;

/// 단계 아래 작은 글씨. A7에서 크리에이터에게 하는 말(식사권은 방문 때 보여주세요 등)은 빼고
/// 날짜·기한·상한 같은 값만 남긴다. 상한은 조건(`perViewCap`)에서 읽는다.
String? storeStepSubtitle(Collaboration c, StepKey key) {
  switch (key) {
    case StepKey.accepted:
      final at = c.step(StepKey.accepted)?.at;
      return at == null ? null : monthDay(at);
    case StepKey.submit:
      return c.submitDueAt == null ? null : dueLabel(c.submitDueAt!);
    case StepKey.settle:
      final cap = c.terms.perViewCap;
      return hasPerViewReward(c) && cap != null ? '최대 ${won(cap)}' : null;
    case StepKey.paid:
    case StepKey.visit:
      return null;
  }
}

const linkFailedMessage = '링크를 열지 못했어요.';
