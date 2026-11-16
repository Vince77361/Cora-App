import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'campaign.dart';

/// 내 캠페인을 서버와 주고받는 포트.
abstract class CampaignRepository {
  /// 진행 중인 내 캠페인. 없으면 null. 서버에 닿지 못하면 [CampaignFailure].
  Future<Campaign?> fetchMyActive();

  /// 캠페인을 만든다. 실패하면 [CampaignFailure].
  Future<Campaign> create(CampaignInput input);

  /// 캠페인 [id]를 고친다. 실패하면 [CampaignFailure].
  Future<Campaign> update(String id, CampaignInput input);

  /// 캠페인 [id]를 마감한다. 이미 이어진 협업은 그대로다. 실패하면 [CampaignFailure].
  Future<void> close(String id);
}

/// 캠페인을 서버와 주고받지 못했다. 서버가 입력이 틀렸다고 알려 준 경우(400)와 이미 진행 중인
/// 캠페인이 있는 경우(409)는 [message]에 서버의 사용자 문구가 담긴다.
class CampaignFailure implements Exception {
  const CampaignFailure({this.message});

  final String? message;

  @override
  String toString() => 'CampaignFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) =>
      throw UnimplementedError('campaignRepositoryProvider must be overridden'),
);
