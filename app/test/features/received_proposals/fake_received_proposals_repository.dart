import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/received_proposals/domain/received_proposal.dart';
import 'package:cora/features/received_proposals/domain/received_proposals_repository.dart';

/// 손으로 쓴 가짜 받은 제안 저장소. 목록과 질문 보내기를 흉내 낸다.
class FakeReceivedProposalsRepository implements ReceivedProposalsRepository {
  FakeReceivedProposalsRepository({List<ReceivedProposal>? proposals})
    : proposals = proposals ?? [];

  List<ReceivedProposal> proposals;

  bool failFetch = false;

  /// 설정하면 [inquire]가 이 예외를 던진다.
  ReceivedProposalsFailure? inquiryFailure;

  /// 설정하면 [inquire]가 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdInquiry;

  int fetchCalls = 0;
  final inquiries =
      <({String campaignId, String message, String? contentLine})>[];

  @override
  Future<List<ReceivedProposal>> fetchAll() async {
    fetchCalls++;
    if (failFetch) throw const ReceivedProposalsFailure.failed();
    // 질문을 보낸 캠페인은 서버 목록에서 빠진다(협업이 생겼으므로).
    final asked = {for (final i in inquiries) i.campaignId};
    return [
      for (final p in proposals)
        if (!asked.contains(p.campaignId)) p,
    ];
  }

  @override
  Future<InquiryResult> inquire(
    String campaignId, {
    required String message,
    String? contentLine,
  }) async {
    await holdInquiry?.future;
    final failure = inquiryFailure;
    if (failure != null) throw failure;
    inquiries.add((
      campaignId: campaignId,
      message: message,
      contentLine: contentLine,
    ));
    return InquiryResult(
      collaborationId: 'collab-$campaignId',
      conversationId: 'conv-$campaignId',
    );
  }
}

/// 테스트용 받은 제안. 기본은 브랜드의 글이 붙은 릴스 30만 원 + 제품이다.
ReceivedProposal receivedProposal({
  String campaignId = 'c1',
  String brandName = '모아 스튜디오',
  String? contentTitle = '매일 손이 가는 물건들',
  String? note = '실제로 사용하는 장면이 좋았어요. 새 주얼리도 서윤님의 일상 안에서 소개하고 싶어요.',
  int fee = 300000,
  ContentFormat format = ContentFormat.reels,
  bool productProvided = true,
  ViewPay? performance,
}) => ReceivedProposal(
  campaignId: campaignId,
  brandName: brandName,
  contentTitle: contentTitle,
  fee: fee,
  format: format,
  note: note,
  productProvided: productProvided,
  performance: performance,
);
