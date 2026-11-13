import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/offer_terms.dart';

/// 오퍼 조건 3단계가 시작할 때 쓰는 값을 provider 인자로 넘기는 상자.
///
/// 일부러 `==`를 정하지 않아 같은 값이어도 상자가 다르면 다른 상태다. 위젯이 한 번 만들어 들고
/// 있으므로, 화면이 다시 그려지며 처음 값이 달라져도(예: 저장 뒤 가게가 새로 읽힘) 고르던 단계와
/// 값이 처음으로 돌아가지 않는다.
class OfferTermsWizardSeed {
  OfferTermsWizardSeed(this.initial, this.defaults);

  /// 처음 고를 값(가게의 모집 조건, 없으면 서버 설정의 기본값).
  final OfferTerms initial;

  /// 보상 방식을 바꿔 없던 요소를 켤 때 쓰는 서버 설정의 기본값. 혜택과 조회수 수당을 모두 가진다.
  final OfferTerms defaults;
}

/// 2단계에서 고르는 보상 방식. 식사권만, 조회수 수당만, 둘 다(고정 현금은 처음 값 그대로 둔다).
/// 오퍼 보내기 개편(A5의 빠른 보상 조합)이 이 선택을 바꾼다.
enum RewardChoice { voucher, viewPay, both }

/// 3단계 화면의 상태. 화면을 떠나면 고르던 값도 버린다.
final offerTermsWizardViewModelProvider = NotifierProvider.autoDispose
    .family<
      OfferTermsWizardViewModel,
      OfferTermsWizardState,
      OfferTermsWizardSeed
    >(OfferTermsWizardViewModel.new);

class OfferTermsWizardState {
  const OfferTermsWizardState({
    required this.step,
    required this.terms,
    required this.voucher,
    required this.viewPay,
    this.submitting = false,
    this.submitFailed = false,
  });

  /// 0부터 센다(0 = 콘텐츠 형식, 1 = 보상, 2 = 확인).
  final int step;

  /// 지금 고른 조건.
  final OfferTerms terms;

  /// 보상에 들어가지 않아도 고른 값은 들고 있다(보상 방식을 바꿨다 되돌려도 남도록).
  final Voucher voucher;
  final ViewPay viewPay;
  final bool submitting;
  final bool submitFailed;

  static const lastStep = 2;

  /// 블로그 글은 조회수를 셀 수 없어 조회수 수당을 쓸 수 없다(공통 모델).
  bool get viewPayAllowed => terms.viewPayAllowed;

  bool get isLastStep => step == lastStep;

  /// 지금 고른 보상 방식. 혜택도 조회수 수당도 없으면(고정 현금만) null이다.
  RewardChoice? get choice {
    final hasVoucher = terms.reward.voucher != null;
    final hasViewPay = terms.reward.viewPay != null;
    if (hasVoucher && hasViewPay) return RewardChoice.both;
    if (hasVoucher) return RewardChoice.voucher;
    if (hasViewPay) return RewardChoice.viewPay;
    return null;
  }

  OfferTermsWizardState copyWith({
    int? step,
    OfferTerms? terms,
    Voucher? voucher,
    ViewPay? viewPay,
    bool? submitting,
    bool? submitFailed,
  }) => OfferTermsWizardState(
    step: step ?? this.step,
    terms: terms ?? this.terms,
    voucher: voucher ?? this.voucher,
    viewPay: viewPay ?? this.viewPay,
    submitting: submitting ?? this.submitting,
    submitFailed: submitFailed ?? this.submitFailed,
  );
}

class OfferTermsWizardViewModel extends Notifier<OfferTermsWizardState> {
  OfferTermsWizardViewModel(this._seed);

  final OfferTermsWizardSeed _seed;

  @override
  OfferTermsWizardState build() {
    final initial = _seed.initial;
    final defaults = _seed.defaults.reward;
    return OfferTermsWizardState(
      step: 0,
      terms: _allowed(initial),
      voucher: initial.reward.voucher ?? defaults.voucher!,
      viewPay: initial.reward.viewPay ?? defaults.viewPay!,
    );
  }

  /// 블로그 글에서 조회수 수당이 들어간 보상은 식사권만으로 바꾼다.
  OfferTerms _allowed(OfferTerms terms) {
    if (terms.viewPayAllowed || terms.reward.viewPay == null) return terms;
    final reward = terms.reward.withViewPay(null);
    return terms.copyWith(
      reward: reward.voucher == null && reward.fixedCash == 0
          ? reward.withVoucher(_seed.defaults.reward.voucher)
          : reward,
    );
  }

  void next() {
    if (state.submitting || state.isLastStep) return;
    state = state.copyWith(step: state.step + 1, submitFailed: false);
  }

  /// 앞 단계로. 첫 단계에서는 아무 일도 없다.
  void back() {
    if (state.submitting || state.step == 0) return;
    state = state.copyWith(step: state.step - 1, submitFailed: false);
  }

  void pickFormat(ContentFormat format) {
    state = state.copyWith(
      terms: _allowed(state.terms.copyWith(format: format)),
      submitFailed: false,
    );
  }

  void pickReward(RewardChoice choice) {
    if (choice != RewardChoice.voucher && !state.viewPayAllowed) return;
    final reward = state.terms.reward;
    final voucher = choice == RewardChoice.viewPay ? null : state.voucher;
    final viewPay = choice == RewardChoice.voucher ? null : state.viewPay;
    state = state.copyWith(
      terms: state.terms.copyWith(
        reward: reward.withVoucher(voucher).withViewPay(viewPay),
      ),
      submitFailed: false,
    );
  }

  void setVoucher({required String name, required int value}) {
    final voucher = state.voucher.copyWith(name: name, value: value);
    final reward = state.terms.reward;
    state = state.copyWith(
      voucher: voucher,
      terms: reward.voucher == null
          ? null
          : state.terms.copyWith(reward: reward.withVoucher(voucher)),
      submitFailed: false,
    );
  }

  /// 고른 조건으로 [onSubmit]을 부른다. 실패하면 확인 단계에 머물며 오류 표시만 켠다.
  Future<void> submit(Future<void> Function(OfferTerms) onSubmit) async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true, submitFailed: false);
    try {
      await onSubmit(state.terms);
      // 성공하면 보통 화면이 닫혀 상태도 사라진다. 그대로 남는 화면이면 다시 누를 수 있게 둔다.
      if (ref.mounted) state = state.copyWith(submitting: false);
    } on Exception {
      if (ref.mounted) {
        state = state.copyWith(submitting: false, submitFailed: true);
      }
    }
  }
}
