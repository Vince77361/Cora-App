import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../brand_onboarding/domain/brand_repository.dart';
import '../../../brand_onboarding/domain/campaign_repository.dart';
import '../../../negotiation/domain/brand_usage_rights.dart';
import '../../../offer_terms/domain/offer_terms.dart' show ViewPay;
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../domain/interests_repository.dart';
import '../reward_proposal_entry.dart';

/// F1·F2를 여는 데 필요한 값: 받는 사람, 모집 줄, 처음 값이 담긴 [target]과 받는 사람의 사진.
class RewardProposalSetup {
  const RewardProposalSetup({required this.target, this.recipientPhotoUrl});

  final BrandProposalTarget target;
  final String? recipientPhotoUrl;
}

/// 서로 관심 전에 만드는 판본의 사용권. 서버가 만드는 조건 버전의 기본값(공통 모델: 재게시는 브랜드 계정만)이다.
const _beforeMatchUsageRights = BrandUsageRights.repostOnly;

/// 04·05가 연 흐름의 시작값을 모은다. 서로 관심 전에는 내 캠페인과 브랜드에서(이미 만든 제안이 있으면 그 값),
/// 서로 관심 뒤에는 협업의 최신 판본에서 읽는다. 읽지 못하면 오류이고 화면이 `다시 시도`를 준다.
final rewardProposalSetupProvider = FutureProvider.autoDispose
    .family<RewardProposalSetup, RewardProposalTarget>((ref, target) async {
      switch (target) {
        case BeforeMatch():
          final campaign = await ref
              .read(campaignRepositoryProvider)
              .fetchMyActive();
          final brand = await ref.read(brandRepositoryProvider).fetchMine();
          if (campaign == null || brand == null) {
            throw StateError('제안할 캠페인이나 브랜드가 없다');
          }
          final config = await ref.watch(serverConfigViewModelProvider.future);
          final current = target.current;
          // 04의 표는 성과 추가의 상한만 안다. 단가는 서버 설정의 기본값으로 채운다.
          final perfCap = current?.perfCap;
          return RewardProposalSetup(
            recipientPhotoUrl: target.recipientPhotoUrl,
            target: BrandProposalTarget(
              recipientName: target.recipientName ?? '크리에이터',
              recruitLine: '${brand.name} · ${campaign.headline}',
              format: campaign.format,
              usageRights: _beforeMatchUsageRights,
              startFee: current?.fee ?? campaign.fee,
              startProductProvided:
                  current?.productProvided ?? campaign.productProvided,
              startPerformance: perfCap == null
                  ? null
                  : ViewPay(
                      ratePerThousand: config.reward.viewRate.defaultValue,
                      cap: perfCap,
                    ),
            ),
          );
        case AfterMatch():
          final base = await ref
              .read(interestsRepositoryProvider)
              .fetchProposalBase(target.collaborationId);
          return RewardProposalSetup(
            recipientPhotoUrl: base.counterpartPhotoUrl,
            target: BrandProposalTarget(
              recipientName: base.counterpartName,
              recruitLine: base.recruitLine,
              format: base.format,
              pieces: base.pieces,
              usageRights: base.usageRights,
              startFee: base.fee,
              startProductProvided: base.productProvided,
              startPerformance: base.performance,
              nextVersion: target.baseVersion + 1,
              proposedByBrand: base.proposedByBrand,
            ),
          );
      }
    }, retry: (_, _) => null);
