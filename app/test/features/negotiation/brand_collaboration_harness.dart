import 'package:cora/features/collaboration/domain/collaboration.dart';

import '../collaboration/fake_collaboration_repository.dart';

const brandCollabId = 'b0b0b0b0-aaaa-bbbb-cccc-000000000007';

/// 캔버스 07의 견본 브랜드 협업: 서윤의 작은 취향과 모아 스튜디오, 지금 3단계(2단계까지 끝), 확보액 350,000원,
/// 남은 예산 150,000원. 기본은 브랜드가 보고 있고 상대의 동의를 기다린다.
Collaboration brandCollab({
  String id = brandCollabId,
  CollaborationRole role = CollaborationRole.commissioner,
  String counterpart = '서윤의 작은 취향',
  String brandName = '모아 스튜디오',
  int doneCount = 2,
  int? current = 3,
  BrandProgressNote? note = BrandProgressNote.waitingOtherConfirm,
  CollaborationNextAction? nextAction,
  int? securedAmount = 350000,
  CampaignBudgetLeft? budget = const CampaignBudgetLeft(left: 150000, over: 0),
  bool withProgress = true,
  String? conversationId,
}) => collaboration(
  id: id,
  kind: CollaborationKind.brandContract,
  role: role,
  storeName: counterpart,
  campaign: CollaborationCampaign(
    id: 'campaign-1',
    brandName: brandName,
    headline: '나만의 아침 루틴 속 작은 포인트',
  ),
  brandProgress: withProgress
      ? BrandProgress(doneCount: doneCount, current: current, note: note)
      : null,
  nextAction: nextAction,
  securedAmount: securedAmount,
  campaignBudgetLeft: role == CollaborationRole.commissioner ? budget : null,
  conversationId: conversationId,
);
