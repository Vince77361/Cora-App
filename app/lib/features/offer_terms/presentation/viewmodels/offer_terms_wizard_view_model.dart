import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/proposal_draft.dart';

/// 오퍼 보내기(A5)의 단계 상태. 고르는 조건은 [proposalDraftViewModelProvider]가 들고 있어 F1·F2와
/// 함께 쓰고, 여기에는 어느 단계인지와 화면에서만 의미 있는 선택을 둔다. 화면을 떠나면 버린다.
final offerTermsWizardViewModelProvider = NotifierProvider.autoDispose
    .family<OfferTermsWizardViewModel, OfferTermsWizardState, NewOfferTarget>(
      OfferTermsWizardViewModel.new,
    );

class OfferTermsWizardState {
  const OfferTermsWizardState({this.step = 0, this.cashChosen = false});

  /// 0부터 센다(0 = 콘텐츠 형식, 1 = 보상, 2 = 확인).
  final int step;

  /// `고정 현금`을 눌렀다. 금액을 아직 안 적었으면 보상은 비어 있지만 이 조합이 골라진 것으로 보인다.
  final bool cashChosen;

  static const lastStep = 2;

  bool get isLastStep => step == lastStep;

  OfferTermsWizardState copyWith({int? step, bool? cashChosen}) =>
      OfferTermsWizardState(
        step: step ?? this.step,
        cashChosen: cashChosen ?? this.cashChosen,
      );
}

class OfferTermsWizardViewModel extends Notifier<OfferTermsWizardState> {
  OfferTermsWizardViewModel(this._target);

  // ignore: unused_field
  final NewOfferTarget _target;

  @override
  OfferTermsWizardState build() => const OfferTermsWizardState();

  void next() {
    if (state.isLastStep) return;
    state = state.copyWith(step: state.step + 1);
  }

  /// 앞 단계로. 첫 단계에서는 아무 일도 없다.
  void back() {
    if (state.step == 0) return;
    state = state.copyWith(step: state.step - 1);
  }

  void setCashChosen(bool chosen) {
    if (state.cashChosen == chosen) return;
    state = state.copyWith(cashChosen: chosen);
  }
}
