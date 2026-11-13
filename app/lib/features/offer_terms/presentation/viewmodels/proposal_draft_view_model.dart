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

  /// 요소를 껐다 켜도 고른 값이 남도록 마지막 값을 든다(조회수 수당의 단가·상한, 식사권, 고정 현금).
  Voucher? _lastVoucher;
  int _lastFixedCash = 0;
  ViewPay? _lastViewPay;

  /// 서버 설정의 기본 보상. 한 번도 켠 적 없는 요소를 켤 때 쓴다.
  Reward _defaults = const Reward();

  /// 블로그 글로 바꾸며 조회수 수당이 꺼졌다. 블로그 글이 아닌 형식으로 돌아오면 다시 켠다.
  bool _viewPayDroppedByBlog = false;

  @override
  Future<OfferTerms> build() async {
    final config = await ref.watch(serverConfigViewModelProvider.future);
    // 가게 사장님이 만드는 모집 조건과 오퍼만 가게의 모집 조건에서 시작한다. 가게를 읽지 못해도 기본값으로 연다.
    // 처음 값만 필요해서 한 번만 읽는다. 지켜보면 고르는 동안 가게가 새로 읽힐 때마다 초안이 처음 값으로
    // 되돌아간다(오퍼 보내기에서 F1을 고치고 돌아오면 고친 값이 사라진다).
    MyStore? store;
    if (_target is RecruitTarget || _target is NewOfferTarget) {
      try {
        store = await ref.read(myStoreViewModelProvider.future);
      } on Object {
        store = null;
      }
    }
    _defaults = config.defaultTerms.reward;
    _lastVoucher = _defaults.voucher;
    _lastViewPay = _defaults.viewPay;
    // 크리에이터의 역제안은 가게의 모집 조건에서, 사장님이 고쳐서 다시 보내는 판본은 그 제안의 최신 판본 조건에서
    // 시작한다(바꾼 만큼이 다음 판본이다).
    final target = _target;
    final given = switch (target) {
      CounterTarget(:final start) => start,
      ReplyTarget(:final start) => start,
      _ => null,
    };
    final start = given ?? store?.defaultTerms ?? config.defaultTerms;
    _remember(start.reward);
    return start;
  }

  OfferTerms? get _terms => state.value;

  void _remember(Reward reward) {
    _lastVoucher = reward.voucher ?? _lastVoucher;
    _lastViewPay = reward.viewPay ?? _lastViewPay;
    if (reward.fixedCash > 0) _lastFixedCash = reward.fixedCash;
  }

  void _set(OfferTerms terms) {
    _remember(terms.reward);
    state = AsyncData(terms);
  }

  /// 빠른 조합을 고를 때 쓰는 값: 지금 보상의 요소를 우선하고, 없으면 마지막으로 고른 값, 그것도 없으면
  /// 서버 설정의 기본값으로 세 요소를 모두 채운다.
  Reward get presetBase {
    final reward = _terms?.reward ?? const Reward();
    return Reward(
      voucher: reward.voucher ?? _lastVoucher ?? _defaults.voucher,
      fixedCash: reward.fixedCash > 0 ? reward.fixedCash : _lastFixedCash,
      viewPay: reward.viewPay ?? _lastViewPay ?? _defaults.viewPay,
    );
  }

  /// 콘텐츠 형식을 바꾼다. 블로그 글은 조회수를 셀 수 없어 조회수 수당을 끄고, 블로그 글이 아닌 형식으로
  /// 돌아오면 그때 꺼진 조회수 수당을 마지막 값으로 다시 켠다.
  void setFormat(ContentFormat format) {
    final terms = _terms;
    if (terms == null) return;
    var reward = terms.reward;
    if (format == ContentFormat.blog && reward.viewPay != null) {
      _lastViewPay = reward.viewPay;
      reward = reward.withViewPay(null);
      _viewPayDroppedByBlog = true;
    } else if (format != ContentFormat.blog && _viewPayDroppedByBlog) {
      _viewPayDroppedByBlog = false;
      if (reward.viewPay == null) reward = reward.withViewPay(_lastViewPay);
    }
    _set(terms.copyWith(format: format, reward: reward));
  }

  /// 보상 요소를 직접 바꾸면 블로그 글에서 꺼졌던 조회수 수당을 다시 켜 주지 않는다.
  void _changeReward(OfferTerms terms) {
    _viewPayDroppedByBlog = false;
    _set(terms);
  }

  /// 빠른 조합 하나를 고른다. 조합에 없는 요소는 끄고, 값은 [presetBase]에서 가져온다.
  void pickPreset(RewardPreset preset) {
    final terms = _terms;
    if (terms == null) return;
    if (preset == RewardPreset.benefitAndViewPay && !terms.viewPayAllowed) {
      return;
    }
    _changeReward(terms.copyWith(reward: applyPreset(presetBase, preset)));
  }

  /// 제공 혜택을 바꾼다. null이면 `혜택 없음`이다.
  void setVoucher(Voucher? voucher) {
    final terms = _terms;
    if (terms == null) return;
    _changeReward(terms.copyWith(reward: terms.reward.withVoucher(voucher)));
  }

  void setFixedCash(int amount) {
    final terms = _terms;
    if (terms == null) return;
    _changeReward(terms.copyWith(reward: terms.reward.withFixedCash(amount)));
  }

  /// 조회수 수당을 켜고 끈다. 블로그 글에서는 켤 수 없다.
  void setViewPayEnabled(bool enabled) {
    final terms = _terms;
    if (terms == null) return;
    if (enabled && !terms.viewPayAllowed) return;
    _changeReward(
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
    _changeReward(
      terms.copyWith(reward: terms.reward.withViewPay(change(current))),
    );
  }

  void setUsageRights(UsageRights rights) {
    final terms = _terms;
    if (terms == null) return;
    _set(terms.copyWith(usageRights: rights));
  }
}
