import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart' show formatFromWire;
import '../../offer_terms/domain/offer_terms.dart' show ViewPay;
import '../domain/received_proposal.dart';
import '../domain/received_proposals_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 받은 제안을 읽고 `조건부터 질문하기`를 보낸다. 생성된 타입은
/// 이 파일 밖으로 내보내지 않는다.
class ApiReceivedProposalsRepository implements ReceivedProposalsRepository {
  ApiReceivedProposalsRepository(api.ApiClient client)
    : _discovery = api.DiscoveryApi(client);

  final api.DiscoveryApi _discovery;

  @override
  Future<List<ReceivedProposal>> fetchAll() async {
    try {
      final rows = await _discovery.listReceivedProposals();
      if (rows == null) throw const ReceivedProposalsFailure.failed();
      return [for (final m in rows) _proposal(m)];
    } catch (error) {
      throw _failure(error, '읽기');
    }
  }

  @override
  Future<InquiryResult> inquire(
    String campaignId, {
    required String message,
    String? contentLine,
  }) async {
    try {
      final m = await _discovery.createInquiry(
        campaignId,
        api.InquiryDto(message: message, contentLine: contentLine),
      );
      if (m == null) throw const ReceivedProposalsFailure.failed();
      return InquiryResult(
        collaborationId: m.collaborationId,
        conversationId: m.conversationId,
      );
    } catch (error) {
      throw _failure(error, '질문');
    }
  }

  static ReceivedProposalsFailure _failure(Object error, String what) {
    if (error is ReceivedProposalsFailure) return error;
    final parsed = ApiError.from(error);
    // 사용자에게는 같은 실패지만 원인을 알 수 있게 종류와 상태 코드만 남긴다(응답 본문과 문구는 남기지 않는다).
    if (kDebugMode) {
      debugPrint(
        '[received_proposals] $what 실패: 종류=${error.runtimeType} '
        '상태=${parsed.status} 코드=${parsed.code}',
      );
    }
    return parsed.isConflict
        ? const ReceivedProposalsFailure.conflict()
        : const ReceivedProposalsFailure.failed();
  }

  static ReceivedProposal _proposal(api.ProposalModel m) => ReceivedProposal(
    campaignId: m.campaignId,
    brandName: m.brandName,
    brandPhotoUrl: m.brandPhotoUrl,
    contentPhotoUrl: m.contentPhotoUrl,
    contentTitle: m.contentTitle,
    fee: m.fee,
    format: formatFromWire(m.format),
    note: m.note,
    performance: m.performance == null
        ? null
        : ViewPay(
            ratePerThousand: m.performance!.ratePer1000,
            cap: m.performance!.cap,
          ),
    productProvided: m.productProvided,
  );
}
