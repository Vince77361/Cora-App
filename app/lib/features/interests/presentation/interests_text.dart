import '../../../core/text/josa.dart';

/// 저장함(03), 후보 비교(04), 서로 관심(05)의 문구. 캔버스 글자 그대로이고, 아래 표시한 것만 캔버스에
/// 없어 계획·설계의 문구를 쓴다.
abstract final class InterestsTexts {
  // 03 머리와 탭(캔버스 Likes)
  static const title = '저장함';
  static const brandPill = '브랜드 관점';
  static const creatorPill = '크리에이터 관점';
  static const brandDescription = '저장은 나만 보고, 하트는 상대에게 전해져요. 비교할 후보를 골라요.';
  static const creatorDescription = '저장은 나만 보고, 하트는 상대에게 전해져요.';
  static const tabListLabel = '후보 분류';
  static String tabSaved(int n) => '저장 $n';
  static String tabSent(int n) => '보낸 관심 $n';
  static String tabProposals(int n) => '보낸 제안 $n';

  // 카드 표지
  static const badgeMutual = '서로 관심';
  static const badgeWaiting = '응답 대기';
  static const badgeHeld = '저장';

  // 비교 동그라미
  static const pickedLabel = '비교에 선택됨';
  static const notPickedLabel = '비교에 고르기';
  static const pickLimit = '비교는 2명까지예요.';

  // 보류 카드를 바꾼 뒤의 안내(01·08과 같은 문구)
  static const passedForCreator = '넘겼어요. 브랜드에는 알리지 않아요.';

  // 서로 관심 상자(캔버스 Likes)
  static const openTerms = '협업 조건 확인';

  // 비교 버튼
  static String compareButton(int n) => '선택한 $n명 비교하기';
  static const compareNeedTwo = '비교할 후보 2명을 골라 주세요.';

  // 탭이 비었을 때(F8 공용 위젯, 캔버스 밖, 설계 4.3).
  static const emptySavedTitle = '아직 저장한 후보가 없어요.';
  static const emptySavedBody = '카드를 위로 밀거나 저장 버튼을 눌러 보세요.';
  static const emptySentTitle = '아직 보낸 하트가 없어요.';
  static const emptySentBody = '카드를 오른쪽으로 밀거나 하트 버튼을 눌러 보세요.';
  // 보낸 제안 탭 줄의 단추(제안함 F3과 같은 글자).
  static const respond = '응답하기';
  static const waitingButton = '대기';
  static const emptyProposalsTitle = '아직 보낸 제안이 없어요.';
  static const emptyProposalsBody = '마음에 드는 크리에이터에게 제안해 보세요.';

  // 캔버스와 계획에 없는 문구: 불러오기 실패와 저장 실패 안내, 보류 카드를 눌렀을 때의 시트.
  static const loadFailedTitle = '관심 목록을 불러오지 못했어요';
  static const holdLike = '관심 보내기';
  static const holdPass = '넘기기';

  // 04 후보 비교(캔버스 Compare)
  static const compareTitle = '후보 비교';
  static const compareNote =
      '같은 결과물 기준으로 맞췄어요. 점 표시는 조건이 다른 항목이에요. 팔로워 수는 비교하지 않아요.';
  static const differsLabel = '조건이 달라요';
  static const rowDeliverable = '결과물';
  static const rowBenefit = '혜택';
  static const rowFee = '현금 고정비';
  static const rowPerfCap = '성과 상한';
  static const rowUsage = '사용권';
  static const rowStart = '촬영 가능일';
  static const rowFace = '얼굴 출연';
  static String viewProposal(String shortName) => '$shortName의 제안 보기';
  static String propose(String shortName) => '$shortName에게 제안';
  static String proposalSent(String name) => '$name에게 제안을 보냈어요. 상대도 고르면 알려드려요.';
  static const compareLoadFailedTitle = '후보 비교를 불러오지 못했어요';

  // 05 서로 관심 확인(캔버스 Match)
  static String matchBadge(String tagline) => '$tagline 캠페인에서 연결';
  static const matchTitle = '서로를 골랐어요.';
  static String matchBody(String brand, String creator) =>
      '${josa(brand, JosaPair.gwaWa)} ${josa(creator, JosaPair.iGa)} 서로의 콘텐츠에 관심을 표시했어요. 아직 계약이나 지급 의무는 생기지 않아요.';
  static String viewProposals(int n) => n == 0 ? '제안 보기' : '받은 제안 보기 · $n건';
  static const proposeFirst = '내가 먼저 제안하기';

  /// 첫 인사 입력란(캔버스의 안내 글자 `콘텐츠에 대한 첫 인사 남기기`, 스크린 리더 이름 `첫 메시지`)과 보내기 원.
  static const greetingHint = '콘텐츠에 대한 첫 인사 남기기';
  static const greetingLabel = '첫 메시지';
  static const greetingSendLabel = '첫 메시지 보내기';

  /// 캔버스에 없는 안내(계획 Task 11의 문구).
  static const greetingFailed = '첫 인사를 보내지 못했어요. 대화에서 다시 보내 주세요.';
  static const close = '닫기';
}
