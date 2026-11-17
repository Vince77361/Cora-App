import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'received_proposal.dart';

/// 받은 제안(10)과 `조건부터 질문하기`가 서버와 주고받는 포트. 관심 보내기는 발견의
/// `DiscoveryRepository.decide`가 맡는다.
abstract class ReceivedProposalsRepository {
  /// 내가 받은 제안 전부. 이미 협업이 있는 캠페인은 서버가 뺀다. 실패하면 [ReceivedProposalsFailure].
  Future<List<ReceivedProposal>> fetchAll();

  /// 캠페인 [campaignId]의 브랜드에게 조건부터 질문한다. [message]는 첫 메시지(1~1,000자), [contentLine]은 내가
  /// 만들고 싶은 콘텐츠 한 줄(선택, 40자). 이미 질문했으면 [ReceivedProposalsFailure.conflict]다.
  Future<InquiryResult> inquire(
    String campaignId, {
    required String message,
    String? contentLine,
  });
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class ReceivedProposalsFailure implements Exception {
  const ReceivedProposalsFailure(this.kind);

  /// 연결 문제이거나 서버가 처리하지 못한 일.
  const ReceivedProposalsFailure.failed()
    : kind = ReceivedProposalsFailureKind.failed;

  /// 이미 이 캠페인에 질문했거나 질문할 수 없는 상태다(409).
  const ReceivedProposalsFailure.conflict()
    : kind = ReceivedProposalsFailureKind.conflict;

  final ReceivedProposalsFailureKind kind;

  bool get isConflict => kind == ReceivedProposalsFailureKind.conflict;

  @override
  String toString() => 'ReceivedProposalsFailure($kind)';
}

enum ReceivedProposalsFailureKind { failed, conflict }

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final receivedProposalsRepositoryProvider =
    Provider<ReceivedProposalsRepository>(
      (ref) => throw UnimplementedError(
        'receivedProposalsRepositoryProvider must be overridden',
      ),
    );
