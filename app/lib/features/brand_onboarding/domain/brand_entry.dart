import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import '../../collaboration/domain/collaboration_repository.dart';
import 'brand_repository.dart';
import 'campaign_repository.dart';

/// 브랜드가 앱에 들어올 때 처음 보여 줄 경로. 프로필이 없으면 프로필 만들기, 진행 중인 캠페인이
/// 없으면 캠페인 만들기, 있으면 발견(01). 다만 캠페인을 마감했어도 진행 중인 브랜드 협업이 있으면
/// 협업 탭으로 간다(마감 확인 문구의 "진행 중인 협업은 그대로 이어져요"를 지키려고, 캠페인 만들기
/// 화면에는 협업으로 가는 길이 없다). 조회에 실패하면 던진다(라우터가 역할 선택 화면의 오류와
/// "다시 시도"로 보낸다).
Future<String> brandEntryPath(Ref ref) async {
  final profile = await ref.read(brandRepositoryProvider).fetchMine();
  if (profile == null) return AppRoutes.brandProfileSetup;
  final campaign = await ref.read(campaignRepositoryProvider).fetchMyActive();
  if (campaign != null) return AppRoutes.brand;
  // 서버는 가게 오퍼도 같은 목록에 내려 주므로 브랜드 협업만 센다(협업 탭과 같은 기준).
  final active = await ref.read(collaborationRepositoryProvider).fetchActive();
  final hasBrandCollaboration = active.any((c) => !c.isStoreOffer);
  return hasBrandCollaboration
      ? AppRoutes.brandCollaborations
      : AppRoutes.brandCampaignNew;
}
