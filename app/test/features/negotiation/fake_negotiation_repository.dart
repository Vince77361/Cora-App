import 'dart:async';

import 'package:cora/features/discovery/domain/discovery_card.dart'
    show MatchReason;
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;

/// 캔버스 06의 견본 판본: 현금 30만 원, 제품 제공, 성과 추가 없음, 릴스 1편, 11월 16일 이후. 서로 관심이 닿을 때
/// 서버가 만든 판본 1이라 아무도 확인하지 않았다.
TermsVersion termsVersion({
  int version = 1,
  String title = '출근 전 30초, 오늘의 손목 루틴',
  int fee = 300000,
  bool productProvided = true,
  ViewPay? performance,
  ContentFormat format = ContentFormat.reels,
  int pieces = 1,
  RevisionScope revisionScope = RevisionScope.guideOnce,
  BrandUsageRights usageRights = BrandUsageRights.repostOnly,
  int payoutDays = 7,
  int? maxCash,
  bool brandConfirmed = false,
  bool creatorConfirmed = false,
  TermsProposer proposedBy = TermsProposer.system,
}) => TermsVersion(
  version: version,
  title: title,
  fee: fee,
  productProvided: productProvided,
  performance: performance,
  format: format,
  pieces: pieces,
  startDate: DateTime(2026, 11, 16),
  revisionScope: revisionScope,
  usageRights: usageRights,
  payoutDays: payoutDays,
  maxCash: maxCash ?? fee + (performance?.cap ?? 0),
  brandConfirmed: brandConfirmed,
  creatorConfirmed: creatorConfirmed,
  proposedBy: proposedBy,
);

/// 캔버스 06의 견본: 내가 응답할 차례, 안내 한 줄, 이유 하나, 팔로워 8,200명.
TermsLatest termsLatest({
  TermsVersion? terms,
  bool mine = false,
  bool myTurn = true,
  bool needsInstagram = false,
  String? notice = '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
  List<MatchReason> reasons = const [MatchReason.field],
  List<String> fields = const ['리빙·소품', '패션'],
  int? followers = 8200,
}) => TermsLatest(
  terms: terms ?? termsVersion(),
  mine: mine,
  myTurn: myTurn,
  needsInstagram: needsInstagram,
  notice: notice,
  reasons: reasons,
  fields: fields,
  followers: followers,
);

/// 손으로 쓴 가짜 조건 저장소. 수락하면 내 확인을 기록해 다시 읽을 때 `상대 대기`가 되게 한다.
class FakeNegotiationRepository implements NegotiationRepository {
  FakeNegotiationRepository({TermsLatest? latest})
    : latest = latest ?? termsLatest();

  TermsLatest latest;
  bool failFetch = false;

  /// 설정하면 [confirm]이 이 예외를 던진다(옛 판본, 서버의 거절 문구, 그 밖의 실패).
  Exception? confirmFailure;

  /// 옛 판본 예외 뒤 다시 읽을 때 돌려줄 최신 판본. 설정하면 [confirm]이 실패하고 [latest]가 이것으로 바뀐다.
  TermsLatest? newerLatest;

  /// 설정하면 [drop]이 이 예외를 던진다.
  Exception? dropFailure;

  /// 설정하면 [drop]이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdDrop;

  /// [drop]이 성공했을 때 부르는 곳(서버가 방을 바꾸는 것을 흉내 낸다).
  void Function(String collaborationId)? onDropped;

  int fetchCalls = 0;
  final dropped = <({String id, DropReason reason})>[];
  final confirmed = <({String id, int version})>[];

  @override
  Future<TermsLatest> fetchLatest(String collaborationId) async {
    fetchCalls++;
    if (failFetch) throw const NegotiationFailure();
    return latest;
  }

  @override
  Future<void> drop(String collaborationId, DropReason reason) async {
    dropped.add((id: collaborationId, reason: reason));
    await holdDrop?.future;
    final failure = dropFailure;
    if (failure != null) throw failure;
    onDropped?.call(collaborationId);
  }

  @override
  Future<void> confirm(String collaborationId, int version) async {
    confirmed.add((id: collaborationId, version: version));
    final failure = confirmFailure;
    if (failure != null) {
      final newer = newerLatest;
      if (newer != null) latest = newer;
      throw failure;
    }
    latest = TermsLatest(
      terms: latest.terms,
      mine: latest.mine,
      myTurn: false,
      needsInstagram: false,
      notice: latest.notice,
      reasons: latest.reasons,
      fields: latest.fields,
      followers: latest.followers,
    );
  }
}
