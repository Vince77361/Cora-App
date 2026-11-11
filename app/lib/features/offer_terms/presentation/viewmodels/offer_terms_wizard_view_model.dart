import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';

/// 오퍼 조건 3단계가 시작할 때 쓰는 값을 provider 인자로 넘기는 상자.
///
/// 일부러 `==`를 정하지 않아 같은 값이어도 상자가 다르면 다른 상태다. 위젯이 한 번 만들어 들고
/// 있으므로, 화면이 다시 그려지며 처음 값이 달라져도(예: 저장 뒤 가게가 새로 읽힘) 고르던 단계와
/// 값이 처음으로 돌아가지 않는다.
class OfferTermsWizardSeed {
  OfferTermsWizardSeed(this.initial);

  final OfferTermsInput? initial;
}

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
    required this.format,
    required this.rewardType,
    required this.voucherName,
    required this.voucherValue,
    this.submitting = false,
    this.submitFailed = false,
  });

  /// 0부터 센다(0 = 콘텐츠 형식, 1 = 보상, 2 = 확인).
  final int step;
  final ContentFormat format;
  final RewardType rewardType;

  /// 보상에 식사권이 들어가지 않아도 고른 값은 들고 있다(보상을 바꿨다 되돌려도 남도록).
  final String voucherName;
  final int voucherValue;
  final bool submitting;
  final bool submitFailed;

  static const lastStep = 2;

  /// 블로그 글은 조회수를 셀 수 없어 조회수당 보상을 쓸 수 없다(공통 모델).
  bool get perViewAllowed => format != ContentFormat.blog;

  bool get isLastStep => step == lastStep;

  /// 지금 고른 값. 식사권이 보상에 없으면 이름과 금액은 비운다.
  OfferTermsInput toInput() => OfferTermsInput(
    format: format,
    rewardType: rewardType,
    voucherName: rewardType == RewardType.perView ? null : voucherName,
    voucherValue: rewardType == RewardType.perView ? null : voucherValue,
  );

  OfferTermsWizardState copyWith({
    int? step,
    ContentFormat? format,
    RewardType? rewardType,
    String? voucherName,
    int? voucherValue,
    bool? submitting,
    bool? submitFailed,
  }) => OfferTermsWizardState(
    step: step ?? this.step,
    format: format ?? this.format,
    rewardType: rewardType ?? this.rewardType,
    voucherName: voucherName ?? this.voucherName,
    voucherValue: voucherValue ?? this.voucherValue,
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
    // 처음 고른 값은 릴스, 식사권 + 조회수(캔버스 NOffer).
    final format = initial?.format ?? ContentFormat.reels;
    return OfferTermsWizardState(
      step: 0,
      format: format,
      rewardType: _allowedReward(
        format,
        initial?.rewardType ?? RewardType.both,
      ),
      voucherName: initial?.voucherName ?? defaultVoucherName,
      voucherValue: initial?.voucherValue ?? defaultVoucherValue,
    );
  }

  /// 블로그 글에서 조회수가 들어간 보상은 식사권만으로 바꾼다.
  static RewardType _allowedReward(ContentFormat format, RewardType type) =>
      format == ContentFormat.blog && type != RewardType.voucher
      ? RewardType.voucher
      : type;

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
      format: format,
      rewardType: _allowedReward(format, state.rewardType),
      submitFailed: false,
    );
  }

  void pickReward(RewardType type) {
    if (type != RewardType.voucher && !state.perViewAllowed) return;
    state = state.copyWith(rewardType: type, submitFailed: false);
  }

  void setVoucher({required String name, required int value}) {
    state = state.copyWith(
      voucherName: name,
      voucherValue: value,
      submitFailed: false,
    );
  }

  /// 고른 조건으로 [onSubmit]을 부른다. 실패하면 확인 단계에 머물며 오류 표시만 켠다.
  Future<void> submit(Future<void> Function(OfferTermsInput) onSubmit) async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true, submitFailed: false);
    try {
      await onSubmit(state.toInput());
      // 성공하면 보통 화면이 닫혀 상태도 사라진다. 그대로 남는 화면이면 다시 누를 수 있게 둔다.
      if (ref.mounted) state = state.copyWith(submitting: false);
    } on Exception {
      if (ref.mounted) {
        state = state.copyWith(submitting: false, submitFailed: true);
      }
    }
  }
}
