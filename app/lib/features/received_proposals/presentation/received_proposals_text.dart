import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/received_proposal.dart';

/// 받은 제안(10)과 03 맨 위 묶음, `조건부터 질문하기` 시트의 문구. 캔버스 Proposal 글자 그대로이고, 아래 표시한
/// 것만 캔버스에 없어 계획·설계의 문구를 쓴다.
abstract final class ReceivedProposalsTexts {
  // 10(캔버스 Proposal)
  static const title = '받은 제안';
  static const close = '닫기';
  static const likedLabel = '브랜드가 좋아한 점';
  static const sendInterest = '관심 보내기';
  static const askConditions = '조건부터 질문하기';

  /// 한 줄 입력란의 안내 글자(캔버스 `placeholder`)와 스크린 리더 이름(캔버스 `label`).
  static const ideaHint = '내가 만들고 싶은 콘텐츠를 한 줄로';
  static const ideaLabel = '내가 만들고 싶은 콘텐츠 한 줄';
  static const ideaSendLabel = '아이디어 보내기';

  /// 한 줄의 최대 글자 수(서버 `contentLine`과 같다).
  static const ideaMax = 40;

  static String proposedOnContent(String title) => '내 콘텐츠 「$title」에 제안했어요';
  static const proposedOnProfile = '내 프로필에 제안했어요';

  /// 10의 제작비 줄: `30만 원 + 제품`, 성과 추가가 있으면 `+ 성과 추가`가 뒤에 붙는다.
  static String priceLine(ReceivedProposal p) {
    final parts = [
      won(p.fee),
      if (p.productProvided) '제품',
      if (p.performance != null) '성과 추가',
    ];
    return parts.join(' + ');
  }

  static String formatLine(ReceivedProposal p) => contentLine(p.format);

  /// 카드에 한 줄로 보이는 `내 콘텐츠 「…」에 제안했어요`(사본이 없으면 `내 프로필에 제안했어요`).
  static String proposedOn(ReceivedProposal p) {
    final t = p.contentTitle;
    return t == null || t.isEmpty ? proposedOnProfile : proposedOnContent(t);
  }

  /// 03 묶음 카드의 좁은 자리에 같은 문장을 두 줄로 나눠 둔다. 한 덩어리로 흘리면 글자 가운데에서 줄이
  /// 바뀌므로(`제안` / `했어요`) 낱말 경계에서 미리 나눈다. [head]는 한 줄에 말줄임으로 두고 [tail]이 있으면
  /// 다음 줄이다. 두 줄을 이으면 [proposedOn]과 같다.
  static ({String head, String? tail}) proposedOnLines(ReceivedProposal p) {
    final t = p.contentTitle;
    return t == null || t.isEmpty
        ? (head: proposedOnProfile, tail: null)
        : (head: '내 콘텐츠 「$t」에', tail: '제안했어요');
  }

  // 03 맨 위 묶음(캔버스에 없는 화면, 계획 Task 11의 문구)
  static String group(int n) => '받은 제안 $n';

  // `조건부터 질문하기` 시트(캔버스에 없는 화면, 계획 Task 11의 문구)
  static const inquiryTitle = '브랜드에게 물어볼 내용을 적어 주세요';
  static const inquiryField = '질문';
  static const inquirySend = '질문 보내기';
  static const inquiryMax = 1000;
  static const inquirySent = '질문을 보냈어요. 브랜드가 수락하면 대화가 열려요.';
  static const inquiryConflict = '이미 이 캠페인에 질문했어요.';

  // 계획에 없는 문구(캔버스 밖): 실패 안내와 빈 자리
  static const inquiryFailed = '질문을 보내지 못했어요. 다시 시도해 주세요.';
  static const interestFailed = '관심을 보내지 못했어요. 다시 시도해 주세요.';
  static const loadFailedTitle = '받은 제안을 불러오지 못했어요';
  static const goneTitle = '더 볼 수 없는 제안이에요';
  static const goneBody = '이미 답했거나 브랜드가 거두었어요.';
}
