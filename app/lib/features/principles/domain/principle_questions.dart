import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import 'principles.dart';

/// 질문 일곱 개의 이름. 순서가 곧 화면의 순서다.
enum PrincipleId { field, block, face, script, honest, fee, days }

/// 선택지 한 개. [sub]는 캔버스의 보조 글이고 없으면 빈 글자다.
class PrincipleOption {
  const PrincipleOption(this.label, [this.sub = '']);

  final String label;
  final String sub;
}

/// 질문 한 장(캔버스 Principles의 `qs`). 문구는 캔버스 글자 그대로다.
class PrincipleQuestion {
  const PrincipleQuestion({
    required this.id,
    required this.multi,
    required this.kicker,
    required this.title,
    required this.hint,
    required this.options,
    this.optional = false,
    String? summaryLabel,
  }) : summaryLabel = summaryLabel ?? kicker;

  final PrincipleId id;

  /// 여러 개를 고를 수 있는지. 아니면 하나만 남는다.
  final bool multi;

  /// 카드 맨 위 머리말.
  final String kicker;

  /// 요약 칸의 이름. 캔버스는 2번만 머리말(`제안받지 않을 업종`)과 다르게 `피하는 업종`이라 부른다.
  final String summaryLabel;
  final String title;
  final String hint;
  final List<PrincipleOption> options;

  /// true이면 아무것도 고르지 않아도 `다음`이 켜진다(2번 `피하고 싶은 업종`).
  final bool optional;
}

// 1번 선택지 순서는 일반 업종 아홉 개를 앱의 업종 순서대로 둔 것이다(맛집·카페가 첫 번째).
// 값과 이름은 가게 쪽 `IndustryCategory`를 그대로 쓴다.
const _fieldCategories = [
  IndustryCategory.foodCafe,
  IndustryCategory.beauty,
  IndustryCategory.fashion,
  IndustryCategory.accessory,
  IndustryCategory.living,
  IndustryCategory.grocery,
  IndustryCategory.digital,
  IndustryCategory.health,
  IndustryCategory.other,
];

// 2번 선택지 순서는 캔버스 순서다.
const _blockedCategories = [
  IndustryCategory.gambling,
  IndustryCategory.loan,
  IndustryCategory.alcohol,
  IndustryCategory.dietSupplement,
];

// 캔버스에 보조 글이 있는 업종. 없는 업종은 보조 글이 없다.
const _fieldSubs = {
  IndustryCategory.accessory: '반지, 팔찌, 시계',
  IndustryCategory.living: '컵, 조명, 향',
  IndustryCategory.beauty: '스킨케어, 메이크업',
  IndustryCategory.fashion: '의류, 가방',
};

const _feeBands = [
  FeeBand.w200k,
  FeeBand.w300k,
  FeeBand.w400k,
  FeeBand.w500kPlus,
];

const _trialDays = [
  ProductTrialDays.d3,
  ProductTrialDays.d7,
  ProductTrialDays.d14,
  ProductTrialDays.any,
];

/// 질문 일곱 개. 설계 문서 2장 09의 표와 캔버스 문구 그대로다.
final List<PrincipleQuestion> principleQuestions = List.unmodifiable([
  PrincipleQuestion(
    id: PrincipleId.field,
    multi: true,
    kicker: '함께하고 싶은 분야',
    title: '어떤 분야의\n제안을 받고 싶나요?',
    hint: '여러 개 골라도 돼요.',
    options: [
      for (final c in _fieldCategories)
        PrincipleOption(c.label, _fieldSubs[c] ?? ''),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.block,
    multi: true,
    optional: true,
    kicker: '제안받지 않을 업종',
    summaryLabel: '피하는 업종',
    title: '피하고 싶은\n업종이 있나요?',
    hint: '고른 업종의 브랜드에게는 내 프로필이 보이지 않아요.',
    options: [
      PrincipleOption('도박·사행성', '베팅, 복권'),
      PrincipleOption('대출', '금융 상품'),
      PrincipleOption('주류', '술, 주점'),
      PrincipleOption('다이어트 보조제', '건강기능식품'),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.face,
    multi: false,
    kicker: '촬영 방식',
    title: '얼굴이 나오는\n촬영도 괜찮나요?',
    hint: '손이나 소품 중심으로만 찍고 싶다면 알려주세요.',
    options: [
      PrincipleOption('얼굴 없이 할래요', '손·소품 중심'),
      PrincipleOption('괜찮아요', '얼굴 출연 가능'),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.script,
    multi: false,
    kicker: '말하는 방식',
    title: '정해진 대본을\n읽는 건 어때요?',
    hint: '브랜드의 필수 정보는 어느 쪽이든 정확히 담아요.',
    options: [
      PrincipleOption('내 말투로 할래요', '솔직한 사용 후기'),
      PrincipleOption('대본도 괜찮아요', '정해진 문구 낭독'),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.honest,
    multi: false,
    kicker: '후기 방식',
    title: '단점도 솔직하게\n말해도 될까요?',
    hint: '브랜드가 제안 전에 미리 알 수 있게 보여줘요.',
    options: [
      PrincipleOption('솔직하게 말할래요', '장점과 단점 모두'),
      PrincipleOption('좋은 점 위주로', '단점은 브랜드에 따로 전달'),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.fee,
    multi: false,
    kicker: '희망 제작비',
    title: '릴스 1편에\n얼마를 생각하나요?',
    hint: '협의로 바뀔 수 있어요.',
    options: [
      PrincipleOption('20만 원대'),
      PrincipleOption('30만 원대'),
      PrincipleOption('40만 원대'),
      PrincipleOption('50만 원 이상'),
    ],
  ),
  const PrincipleQuestion(
    id: PrincipleId.days,
    multi: false,
    kicker: '제품 사용 기간',
    title: '제품은 얼마나\n써보고 찍고 싶나요?',
    hint: '배송 일정을 정할 때 함께 보여요.',
    options: [
      PrincipleOption('3일'),
      PrincipleOption('7일'),
      PrincipleOption('14일'),
      PrincipleOption('상관없어요'),
    ],
  ),
]);

/// 질문별로 고른 선택지의 위치(눌러 고른 순서). 값은 바뀌지 않는다.
class PrincipleAnswers {
  const PrincipleAnswers(this._picks);

  const PrincipleAnswers.empty() : _picks = const {};

  /// 저장된 [p]를 선택지 위치로 푼다. 수정할 때 처음 값이다.
  factory PrincipleAnswers.from(Principles p) {
    int at<T>(List<T> values, T value) => values.indexOf(value);
    return PrincipleAnswers({
      PrincipleId.field: [
        for (final c in p.fields)
          if (_fieldCategories.contains(c)) at(_fieldCategories, c),
      ],
      PrincipleId.block: [
        for (final c in p.blockedIndustries)
          if (_blockedCategories.contains(c)) at(_blockedCategories, c),
      ],
      // 얼굴·대본: 둘째 선택지가 `괜찮아요`·`대본도 괜찮아요`(true)다.
      PrincipleId.face: [p.faceOk ? 1 : 0],
      PrincipleId.script: [p.scriptOk ? 1 : 0],
      // 후기: 첫째 선택지가 `솔직하게 말할래요`(true)다.
      PrincipleId.honest: [p.honestReview ? 0 : 1],
      PrincipleId.fee: [at(_feeBands, p.feeBand)],
      PrincipleId.days: [at(_trialDays, p.trialDays)],
    });
  }

  final Map<PrincipleId, List<int>> _picks;

  List<int> of(PrincipleId id) => _picks[id] ?? const [];

  /// [index]번 선택지를 누른 결과. 여러 개 질문은 켜고 끄고, 하나 질문은 그 하나만 남긴다.
  PrincipleAnswers pick(PrincipleQuestion q, int index) {
    final current = [...of(q.id)];
    if (q.multi) {
      if (!current.remove(index)) current.add(index);
    } else {
      current
        ..clear()
        ..add(index);
    }
    return PrincipleAnswers({..._picks, q.id: current});
  }

  /// 이 질문에서 `다음`을 켤 수 있는지.
  bool canContinue(PrincipleQuestion q) => q.optional || of(q.id).isNotEmpty;

  /// 요약 칸에 보이는 글. 고르지 않았으면 `고르지 않음`.
  String summaryOf(PrincipleQuestion q) {
    final picked = of(q.id);
    if (picked.isEmpty) return '고르지 않음';
    return picked.map((i) => q.options[i].label).join(', ');
  }

  /// 저장할 값. 필수 질문에 답하지 않은 것이 있으면 null.
  Principles? toPrinciples() {
    final fields = of(PrincipleId.field);
    final face = of(PrincipleId.face);
    final script = of(PrincipleId.script);
    final honest = of(PrincipleId.honest);
    final fee = of(PrincipleId.fee);
    final days = of(PrincipleId.days);
    if (fields.isEmpty ||
        face.isEmpty ||
        script.isEmpty ||
        honest.isEmpty ||
        fee.isEmpty ||
        days.isEmpty) {
      return null;
    }
    return Principles(
      fields: [for (final i in fields) _fieldCategories[i]],
      blockedIndustries: [
        for (final i in of(PrincipleId.block)) _blockedCategories[i],
      ],
      faceOk: face.first == 1,
      scriptOk: script.first == 1,
      honestReview: honest.first == 0,
      feeBand: _feeBands[fee.first],
      trialDays: _trialDays[days.first],
    );
  }
}
