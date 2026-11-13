import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:cora/features/store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../server_config/fake_server_config_repository.dart';
import 'proposal_harness.dart';

const _target = NewOfferTarget(creatorId: 'c1', creatorName: '하루 한 컵');
const _voucher = Voucher(name: '식사권', value: 40000, people: 2);
const _viewPay = ViewPay(ratePerThousand: 2000, cap: 60000);

ProviderContainer _container({OfferTerms? storeTerms}) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      storeRepositoryProvider.overrideWithValue(
        storeWith(defaultTerms: storeTerms),
      ),
      serverConfigRepositoryProvider.overrideWithValue(
        FakeServerConfigRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// 초안을 지켜보는 화면이 있는 것처럼 구독을 유지한 채 읽는다(autoDispose라서 안 그러면 읽을 때마다 다시 만든다).
Future<ProposalDraftViewModel> _open(
  ProviderContainer container, {
  ProposalTarget target = _target,
}) async {
  container.listen(proposalDraftViewModelProvider(target), (_, _) {});
  await container.read(proposalDraftViewModelProvider(target).future);
  return container.read(proposalDraftViewModelProvider(target).notifier);
}

OfferTerms _terms(ProviderContainer container) =>
    container.read(proposalDraftViewModelProvider(_target)).requireValue;

void main() {
  test('keeps the values being edited when the store is read again', () async {
    final container = _container();
    final draft = await _open(container);

    draft.setVoucher(const Voucher(name: '빵 세트', value: 30000, people: 3));
    draft.setFixedCash(50000);
    // F1을 고치는 동안 가게가 다시 읽혀도(저장 직후, 새로 고침) 고르던 값이 처음 값으로 돌아가면 안 된다.
    container.invalidate(myStoreViewModelProvider);
    await container.read(myStoreViewModelProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(
      _terms(container).reward,
      const Reward(
        voucher: Voucher(name: '빵 세트', value: 30000, people: 3),
        fixedCash: 50000,
        viewPay: _viewPay,
      ),
    );
  });

  test(
    'turns the view pay back on when a blog post becomes another format',
    () async {
      final container = _container();
      final draft = await _open(container);
      draft.setRate(3000);

      draft.setFormat(ContentFormat.blog);
      expect(_terms(container).reward.viewPay, isNull);

      draft.setFormat(ContentFormat.cardNews);
      // 꺼질 때의 단가와 상한 그대로다.
      expect(
        _terms(container).reward.viewPay,
        const ViewPay(ratePerThousand: 3000, cap: 60000),
      );
    },
  );

  test(
    'does not turn the view pay back on once the reward was chosen by hand',
    () async {
      final container = _container();
      final draft = await _open(container);

      draft.setFormat(ContentFormat.blog);
      draft.pickPreset(RewardPreset.fixedCash);
      draft.setFixedCash(30000);
      draft.setFormat(ContentFormat.reels);

      expect(_terms(container).reward, const Reward(fixedCash: 30000));
    },
  );

  test(
    'leaves a view pay the person turned off alone when changing between non blog formats',
    () async {
      final container = _container();
      final draft = await _open(container);
      draft.setViewPayEnabled(false);

      draft.setFormat(ContentFormat.shorts);
      draft.setFormat(ContentFormat.cardNews);

      expect(_terms(container).reward.viewPay, isNull);
    },
  );

  test(
    'builds a preset from the current elements and the last chosen values',
    () async {
      final container = _container(
        storeTerms: const OfferTerms(
          format: ContentFormat.reels,
          reward: Reward(
            voucher: Voucher(name: '빵 세트', value: 30000, people: 3),
          ),
        ),
      );
      final draft = await _open(container);

      // 가게 조건에 없던 조회수 수당은 서버 설정의 기본값으로 켜진다.
      draft.pickPreset(RewardPreset.benefitAndViewPay);
      expect(
        _terms(container).reward,
        const Reward(
          voucher: Voucher(name: '빵 세트', value: 30000, people: 3),
          viewPay: _viewPay,
        ),
      );

      draft.setRate(3500);
      draft.pickPreset(RewardPreset.fixedCash);
      expect(_terms(container).reward, const Reward());
      draft.setFixedCash(30000);

      // 조합을 오가도 혜택·조회수 수당의 고른 값과 고정 현금이 남는다.
      draft.pickPreset(RewardPreset.benefitAndViewPay);
      expect(
        _terms(container).reward,
        const Reward(
          voucher: Voucher(name: '빵 세트', value: 30000, people: 3),
          viewPay: ViewPay(ratePerThousand: 3500, cap: 60000),
        ),
      );
      draft.pickPreset(RewardPreset.fixedCash);
      expect(_terms(container).reward, const Reward(fixedCash: 30000));
    },
  );

  test('refuses the view pay preset for a blog post', () async {
    final container = _container();
    final draft = await _open(container);
    draft.setFormat(ContentFormat.blog);
    draft.pickPreset(RewardPreset.benefitOnly);

    draft.pickPreset(RewardPreset.benefitAndViewPay);

    expect(_terms(container).reward, const Reward(voucher: _voucher));
  });
}
