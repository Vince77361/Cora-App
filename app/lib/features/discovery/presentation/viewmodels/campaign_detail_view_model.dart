import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/campaign_detail.dart';
import '../../domain/discovery_repository.dart';

/// D1 캠페인 상세. 캠페인마다 하나씩 만들고 화면을 떠나면 버린다. 자동 재시도는 끈다(실패하면 오류
/// 화면의 `다시 시도`로 다시 받는다. 재시도가 끝날 때까지 로딩으로 남지 않게).
final campaignDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CampaignDetailViewModel, CampaignDetail, String>(
      CampaignDetailViewModel.new,
      retry: (_, _) => null,
    );

class CampaignDetailViewModel extends AsyncNotifier<CampaignDetail> {
  CampaignDetailViewModel(this.campaignId);

  final String campaignId;

  @override
  Future<CampaignDetail> build() =>
      ref.read(discoveryRepositoryProvider).fetchCampaignDetail(campaignId);
}
