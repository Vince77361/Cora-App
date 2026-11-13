import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../../store_onboarding/domain/my_store.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../domain/offer_terms.dart';
import '../../domain/proposal_draft.dart';

/// 고르는 중인 조건. F1(보상·예산 설정)과 F2(보내기 전 검토)가 같은 대상이면 같은 값을 본다.
///
/// 처음 값은 가게의 모집 조건이고, 아직 없으면 서버 설정의 기본값이다. 화면을 모두 떠나면 고르던 값도
/// 버린다. 값은 입력할 때마다 바뀌고, 서버에는 보내는 화면이 따로 보낸다.
final proposalDraftViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProposalDraftViewModel, OfferTerms, ProposalTarget>(
      ProposalDraftViewModel.new,
      retry: (_, _) => null,
    );

class ProposalDraftViewModel extends AsyncNotifier<OfferTerms> {
  ProposalDraftViewModel(this._target);

  final ProposalTarget _target;

  /// 조회수 수당을 껐다 켜도 고른 단가와 상한이 남도록 마지막 값을 든다.
  ViewPay? _lastViewPay;

  @override
  Future<OfferTerms> build() async {
    final config = await ref.watch(serverConfigViewModelProvider.future);
    // 가게 사장님이 만드는 모집 조건과 오퍼만 가게의 모집 조건에서 시작한다. 가게를 읽지 못해도 기본값으로 연다.
    MyStore? store;
    if (_target is RecruitTarget || _target is NewOfferTarget) {
      try {
        store = await ref.watch(myStoreViewModelProvider.future);
      } on Object {
        store = null;
      }
    }
    final start = store?.defaultTerms ?? config.defaultTerms;
    _lastViewPay = start.reward.viewPay ?? config.defaultTerms.reward.viewPay;
    return start;
  }

  OfferTerms? get _terms => state.value;

  void _set(OfferTerms terms) => state = AsyncData(terms);

  /// 콘텐츠 형식을 바꾼다. 블로그 글은 조회수를 셀 수 없어 조회수 수당을 끈다.
  void setFormat(ContentFormat format) {
    final terms = _terms;
    if (terms == null) return;
    var reward = terms.reward;
    if (format == ContentFormat.blog && reward.viewPay != null) {
      _lastViewPay = reward.viewPay;
      reward = reward.withViewPay(null);
    }
    _set(terms.copyWith(format: format, reward: reward));
  }

  /// 제공 혜택을 바꾼다. null이면 `혜택 없음`이다.
  void setVoucher(Voucher? voucher) {
    final terms = _terms;
    if (terms == null) return;
    _set(terms.copyWith(reward: terms.reward.withVoucher(voucher)));
  }

  void setFixedCash(int amount) {
    final terms = _terms;
    if (terms == null) return;
    _set(terms.copyWith(reward: terms.reward.withFixedCash(amount)));
  }

  /// 조회수 수당을 켜고 끈다. 블로그 글에서는 켤 수 없다.
  void setViewPayEnabled(bool enabled) {
    final terms = _terms;
    if (terms == null) return;
    if (enabled && !terms.viewPayAllowed) return;
    final current = terms.reward.viewPay;
    if (current != null) _lastViewPay = current;
    _set(
      terms.copyWith(
        reward: terms.reward.withViewPay(enabled ? _lastViewPay : null),
      ),
    );
  }

  void setRate(int ratePerThousand) => _changeViewPay(
    (viewPay) => viewPay.copyWith(ratePerThousand: ratePerThousand),
  );

  void setCap(int cap) =>
      _changeViewPay((viewPay) => viewPay.copyWith(cap: cap));

  void _changeViewPay(ViewPay Function(ViewPay) change) {
    final terms = _terms;
    final current = terms?.reward.viewPay;
    if (terms == null || current == null) return;
    final next = change(current);
    _lastViewPay = next;
    _set(terms.copyWith(reward: terms.reward.withViewPay(next)));
  }

  void setUsageRights(UsageRights rights) {
    final terms = _terms;
    if (terms == null) return;
    _set(terms.copyWith(usageRights: rights));
  }
}
