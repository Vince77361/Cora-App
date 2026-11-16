import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import 'brand_repository.dart';
import 'campaign_repository.dart';

/// 브랜드가 앱에 들어올 때 처음 보여 줄 경로. 프로필이 없으면 프로필 만들기, 진행 중인 캠페인이
/// 없으면 캠페인 만들기, 있으면 발견(01). 조회에 실패하면 던진다(라우터가 역할 선택 화면의 오류와
/// "다시 시도"로 보낸다).
Future<String> brandEntryPath(Ref ref) async {
  final profile = await ref.read(brandRepositoryProvider).fetchMine();
  if (profile == null) return AppRoutes.brandProfileSetup;
  final campaign = await ref.read(campaignRepositoryProvider).fetchMyActive();
  return campaign == null ? AppRoutes.brandCampaignNew : AppRoutes.brand;
}
