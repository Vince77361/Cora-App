import '../../offer_terms/presentation/offer_terms_text.dart' show wonExact;
import '../domain/terms_version.dart';
import 'terms_text.dart';

// 계약(D4)의 문구와 값. 캔버스(NContract / DarkNContract) 글자 그대로이고, 아래 표시한 것만 캔버스에 없다.

/// `합의한 버전 2로` 뒤의 `로`/`으로`. 숫자를 읽은 소리의 받침에 맞춘다(`2`는 이라 `로`, `3`은 삼이라 `으로`,
/// `10`은 십이라 `으로`). `ㄹ` 받침(일·칠·팔)은 `로`다.
String _euroRo(int number) {
  final last = number % 10;
  // 0은 십·백처럼 읽혀 받침이 있고(ㅂ·ㄱ), 3·6은 삼·육이라 받침(ㅁ·ㄱ)이 있다.
  return last == 0 || last == 3 || last == 6 ? '으로' : '로';
}

abstract final class ContractTexts {
  static const title = '협업 계약';
  static const subtitle = '양쪽이 모두 동의하면 계약이 체결되고 제작이 시작돼요.';

  /// 머리 제목. 캔버스는 `로` 뒤에서 줄이 바뀐다.
  static String heading(int version) =>
      '합의한 버전 $version${_euroRo(version)}\n계약해요.';

  // 요약 칸 이름
  static const cellDeliverable = '제작물';
  static const cellFee = '제작비';
  static const cellStart = '제작 시작';
  static const cellPayout = '지급';
  static const cellPerformance = '성과 추가';
  static const cellMaxCash = '최대 현금 부담';

  // 아래 막대
  static const consent = '동의하고 계약하기';
  static const notReady = '모두 확인하면 계약할 수 있어요';
  static const creatorWaitsBrand = '브랜드 동의를 기다리고 있어요. 계약서는 체결 후 보관함에 저장돼요.';
  static const brandWaitsCreator = '크리에이터의 동의를 기다리고 있어요.';
  static const previewNote = '양쪽이 같은 버전을 확인하면 계약할 수 있어요.';
  static const voided = '조건이 바뀌어 동의가 취소됐어요. 새 조건을 확인해 주세요.';

  // 결제 상자(브랜드)
  static const payFee = '제작비';
  static const payPerformance = '성과 추가 (최대)';
  static const payServiceFee = '서비스 수수료';
  static const payTotal = '동의하면 결제할 금액';
  static const payMethodGroup = '결제 수단';
  static const checking = '결제를 확인하고 있어요';
  static const paymentIncomplete = '결제가 완료되지 않았어요. 다시 시도해 주세요.';

  /// 결제 상자의 안내. 성과 추가가 있으면 뒤에 환불 안내가 붙는다.
  static String escrowNote(int payoutDays, {required bool hasPerformance}) =>
      '결제 금액은 Cora가 보관하다가, 콘텐츠가 게시되고 $payoutDays일째에 크리에이터에게 지급해요.'
      '${hasPerformance ? ' 성과 추가는 조회수만큼 지급하고, 남으면 집계 후 환불해요.' : ''}';

  // 체결
  static const concluded = '계약이 체결됐어요.';
  static String concludedAt(DateTime at) => '${monthDayLabel(at)} 체결';
  static const openProgress = '협업 진행 보기';

  // 캔버스 밖: 실패 문구(결제 화면 A8과 같은 말투)
  static const loadFailed = '계약을 불러오지 못했어요';
  static const actionFailed = '처리하지 못했어요. 다시 시도해 주세요.';
  static const startFailed = '결제를 시작하지 못했어요. 다시 시도해 주세요.';
}

/// 요약 칸의 값들. 금액은 만 원 단위로 줄이지 않고, 계약 사본의 값을 그대로 보인다.
String contractFeeValue(TermsVersion terms) =>
    terms.productProvided ? '${wonExact(terms.fee)} + 제품' : wonExact(terms.fee);
