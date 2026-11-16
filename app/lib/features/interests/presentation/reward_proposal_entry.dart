import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';

/// 보상 제안을 어디에 보내는가. 04의 `…에게 제안`은 서로 관심 전이라 크리에이터에게 관심과 함께 보내고,
/// 05의 `내가 먼저 제안하기`는 이미 있는 협업의 새 판본으로 보낸다.
sealed class RewardProposalTarget {
  const RewardProposalTarget();
}

/// 서로 관심 전: [creatorId]에게 보내는 관심에 제안을 붙인다.
class BeforeMatch extends RewardProposalTarget {
  const BeforeMatch(this.creatorId);

  final String creatorId;
}

/// 서로 관심 뒤: 협업 [collaborationId]의 최신 판본 [baseVersion] 위에 새 판본을 낸다.
class AfterMatch extends RewardProposalTarget {
  const AfterMatch(this.collaborationId, this.baseVersion);

  final String collaborationId;
  final int baseVersion;
}

const _placeholderTitle = '보상 제안';

/// 보상·예산 설정(F1)에서 보내기 전 검토(F2)로 이어지는 흐름을 여는 한 곳. 보냈으면 true다.
///
/// 지금은 자리다. F1·F2를 브랜드의 제안으로 여는 일은 이 계획의 다음 커밋이 맡고, 그때 이 함수의 몸을
/// 바꾼다. 부르는 쪽(04·05)은 [RewardProposalTarget]만 넘기고 결과로 `보냈어요` 문구와 이동을 정한다.
Future<bool> openRewardProposal(
  BuildContext context,
  RewardProposalTarget target,
) async {
  // 자리 화면은 역할마다 경로가 다르다(브랜드와 크리에이터가 서로의 경로를 열 수 없다). 지금 열려 있는
  // 화면의 경로로 어느 쪽인지 안다.
  final router = GoRouter.of(context);
  final creator = router.routeInformationProvider.value.uri.path.startsWith(
    AppRoutes.creator,
  );
  await router.push<void>(
    creator
        ? AppRoutes.creatorComingSoon(_placeholderTitle)
        : AppRoutes.brandComingSoon(_placeholderTitle),
    extra: AppRoutes.stacked,
  );
  return false;
}
