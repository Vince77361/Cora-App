import '../../principles/domain/principles.dart' show FeeBand;
import '../../../core/text/josa.dart';

/// 발견(01)과 넘기기 이유(02), 크리에이터 상세의 문구. 캔버스 글자 그대로이고, 아래 표시한 것만 캔버스에
/// 없어 계획·설계의 문구를 쓴다.
abstract final class DiscoveryTexts {
  // 01 머리
  static const brandPill = '브랜드';
  static const creatorPill = '크리에이터';

  // 알림 문구와 단추(캔버스 01)
  static const passToast = '넘겼어요. 상대에게는 알리지 않아요.';
  static const passToastAction = '이유 남기기';
  static const likeToast = '관심을 보냈어요. 상대도 고르면 알려드려요.';
  static const likeToastAction = '관심 목록';
  static const holdToast = '보류함에 담았어요.';
  static const holdToastAction = '보류 보기';
  static const matchToastAction = '확인하기';
  static String matchToast(String name) =>
      '${josa(name, JosaPair.gwaWa)} 서로 관심이 닿았어요.';

  // 카드(캔버스 01, 계획)
  static String badge(int position, int total) => '운영자 추천 $position / $total';
  static const noHeadline = '대표 콘텐츠를 준비 중이에요';
  static String feeBandLabel(FeeBand band) => switch (band) {
    FeeBand.w200k => '20만 원대',
    FeeBand.w300k => '30만 원대',
    FeeBand.w400k => '40만 원대',
    FeeBand.w500kPlus => '50만 원 이상',
  };

  // 버튼 이름(스크린 리더, 캔버스 aria-label)
  static const undoLabel = '되돌리기';
  static const passLabel = '넘기기';
  static const holdLabel = '보류';
  static const likeLabel = '관심 있어요';

  // 다 봤을 때(계획: 2026-11-12 개정. 카드는 F8 공용 위젯)
  static const undoLast = '마지막 카드 되돌리기';
  static const noCandidatesTitle = '아직 추천할 크리에이터가 없어요.';
  static const noCandidatesBody = '크리에이터가 늘어나면 알려드릴게요.';

  // 02 넘기기 이유(캔버스 Pass)
  static const reasonTitle = '넘겼어요. 이유를 남길까요?';
  static const reasonBody = '선택이에요. 남기면 다음 추천에만 반영하고 상대에게는 알리지 않아요.';
  static const reasonSkip = '이유 없이 다음 보기';
  static const reasonSave = '이유 남기고 다음 보기';
  static const reasonUndo = '되돌리기';
  static const undoTooLate = '되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.';

  // 등록 없이 먼저 둘러보기(9A, 계획·설계의 문구. 캔버스에 없다). 알약만 01의 머리를 따른다.
  static const previewPill = '둘러보는 중';
  static const chooseRole = '역할 고르기';
  static const previewDoneTitle = '여기까지 둘러봤어요.';
  static const previewDoneBody = '역할을 고르면 나에게 맞는 추천을 받아요.';
  static const previewEmptyTitle = '아직 둘러볼 크리에이터가 없어요.';

  // 크리에이터 상세(계획)
  static const fitTitle = '잘 맞는 점';
  static const detailPass = '넘기기';
  static const detailLike = '관심 보내기';
  static const noteTitle = '좋았던 점을 한 줄 남길까요? (선택)';
  static const noteSend = '관심 보내기';

  // 캔버스와 계획에 없는 문구: 불러오기·저장 실패 안내와 입력 칸 이름.
  static const retryLater = '잠시 뒤 다시 시도해 주세요.';
  static const loadFailedTitle = '추천을 불러오지 못했어요';
  static const noteLabel = '좋았던 점';
}
