import 'package:cora/features/brand_onboarding/domain/campaign.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/principles/domain/principles.dart'
    show ProductTrialDays;

/// 손으로 쓴 가짜 캠페인 저장소. 브랜드의 진행 중인 캠페인 하나를 흉내 낸다.
class FakeCampaignRepository implements CampaignRepository {
  /// [active]가 서버에 있는 진행 중인 캠페인이다. null이면 없다.
  FakeCampaignRepository({this.active});

  Campaign? active;

  bool failFetch = false;

  /// 설정하면 [create]·[update]·[close]가 이 실패를 던진다.
  CampaignFailure? failWrite;

  int createCalls = 0;
  int updateCalls = 0;
  int closeCalls = 0;

  /// 마지막 [create]·[update]에 넘어온 값.
  CampaignInput? lastInput;

  Campaign _from(String id, CampaignInput i) => Campaign(
    id: id,
    headline: i.headline,
    fee: i.fee,
    budget: i.budget,
    productProvided: i.productProvided,
    format: i.format,
    startFrom: i.startFrom,
    trialDays: i.trialDays,
    mustInclude: i.mustInclude,
    notRequired: i.notRequired,
    status: CampaignStatus.active,
  );

  @override
  Future<Campaign?> fetchMyActive() async {
    if (failFetch) throw const CampaignFailure();
    return active;
  }

  @override
  Future<Campaign> create(CampaignInput input) async {
    createCalls++;
    lastInput = input;
    final failure = failWrite;
    if (failure != null) throw failure;
    return active = _from('campaign-1', input);
  }

  @override
  Future<Campaign> update(String id, CampaignInput input) async {
    updateCalls++;
    lastInput = input;
    final failure = failWrite;
    if (failure != null) throw failure;
    return active = _from(id, input);
  }

  @override
  Future<void> close(String id) async {
    closeCalls++;
    final failure = failWrite;
    if (failure != null) throw failure;
    active = null;
  }
}

/// 테스트가 기본으로 쓰는 진행 중인 캠페인.
final defaultCampaign = Campaign(
  id: 'campaign-1',
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
  budget: 1000000,
  productProvided: true,
  format: ContentFormat.reels,
  startFrom: DateTime(2026, 11, 20),
  trialDays: ProductTrialDays.any,
  mustInclude: const [],
  notRequired: const [],
  status: CampaignStatus.active,
);
