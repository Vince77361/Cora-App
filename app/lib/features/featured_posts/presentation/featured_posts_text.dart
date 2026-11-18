/// 대표 게시물 화면의 문구. 캔버스(M19G6*)와 설계 7장의 글자 그대로이고, 캔버스에 없는 것은 따로 표시했다.
abstract final class FeaturedPostsText {
  // 대표 게시물 화면(Empty·Full·Personal)
  static const title = '대표 게시물';
  static const intro = '가게 사장님에게 가장 먼저 보여요. 최대 4개, 언제든 바꿀 수 있어요.';
  static const emptyHint = '대표 게시물 1개만 있어도 지원할 수 있어요.';
  static const reorderHint = '꾹 눌러 끌면 순서를 바꿀 수 있어요';
  static const fromInstagram = '인스타에서 고르기';
  static const fromGallery = '사진첩에서 올리기';
  static const save = '저장하기';
  static const badgeInstagram = '인스타';
  static const badgeGallery = '사진첩';

  static String counter(int count) => '$count / 4';

  /// 프로필 설정의 `대표 게시물` 줄 라벨(캔버스 밖).
  static const tileLabel = '대표 게시물 (선택)';
  static String postNumber(int n) => '$n번 게시물';

  // 순서·교체 시트(Sheet)
  static const sheetBody = '다른 게시물로 바꾸거나 순서를 옮겨요.';
  static const replaceFromInstagram = '인스타에서 골라 교체';
  static const replaceFromGallery = '사진첩에서 골라 교체';
  static const moveToFront = '맨 앞으로 보내기';
  static const remove = '대표 게시물에서 빼기';

  // 인스타에서 고르기(Pick)
  static const pickTitle = '인스타그램에서 가져오기';
  static const pickClose = '닫기';
  static const pickRule = '대표 게시물로 보여줄 것만 골라요. 최대 4개예요.';
  static const pickOrderHint = '고른 순서대로 보여줘요';
  static const pickAdd = '대표 게시물에 추가';

  static String pickOwner(String handle) => '@$handle 계정의 게시물이에요.';
  static String pickCounter(int picked, int limit) => '$picked / $limit개 고름';

  // 개인 계정(Personal)
  static const personalTitle = '개인 계정은 연동할 수 없어요.';
  static const personalBody = '인스타그램 앱에서 프로페셔널 계정으로 바꾼 뒤 다시 연동해 주세요.';
  static const personalNoPayout =
      '개인 계정은 조회수 수당을 받을 수 없어요. 사진첩에서 올린 게시물은 대표 게시물로만 보여요.';
  static const personalHowTo = '프로페셔널 계정으로 바꾸는 방법';

  // 사진첩에서 올리기(기존 캔버스 B6 NUpload)
  static const composeTitle = '새 콘텐츠';
  static const captionLabel = '한 줄 설명';

  // ---- 캔버스에 없는 문구(설계 7장이 정한 것은 그 문구, 나머지는 필요한 만큼만) ----
  /// 설계 7.2: 5번째를 누를 때.
  static String pickLimit(int left) => '대표 게시물은 4개까지예요. $left개만 더 고를 수 있어요.';

  /// 설계 7.1: 나갈 때 바뀐 것이 있으면.
  static const leaveAsk = '바꾼 내용을 저장할까요?';
  static const leaveDiscard = '저장 안 함';

  /// 이미 대표 게시물이거나(한 게시물은 한 번만) 영상 한도(60초·100MB)를 넘어 고를 수 없는 칸의 표지.
  static const alreadyImported = '가져옴';
  static const notImportable = '가져올 수 없어요';

  /// 프로페셔널 계정 방법 시트(설계 7.4).
  static const howToTitle = '프로페셔널 계정으로 바꾸는 방법';
  static const howToSteps = '인스타그램 앱 → 설정 → 계정 유형 → 프로페셔널 계정으로 전환';
  static const howToClose = '닫기';

  static const addComposeButton = '대표 게시물에 추가';
  static const composeCaptionHint = '예: 출근 전 30초, 오늘의 손목 루틴';
  static const composePhotoLabel = '고른 사진 미리보기';

  static const loadFailed = '대표 게시물을 불러오지 못했어요.';
  static const saveFailed = '저장하지 못했어요. 다시 시도해 주세요.';
  static const importFailed = '가져오지 못했어요. 다시 시도해 주세요.';
  static const pickLoadFailed = '인스타그램 게시물을 불러오지 못했어요.';
  static const photoTooLarge = '사진이 너무 커요. 5MB 이하로 골라 주세요.';
  static const rateLimited = '사진을 너무 많이 올렸어요. 잠시 뒤에 다시 시도해 주세요.';
  static const uploadFailed = '사진을 올리지 못했어요. 다시 시도해 주세요.';
}
