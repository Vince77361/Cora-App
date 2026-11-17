import 'dart:convert';

import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_error.dart';
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../offer_terms/data/offer_terms_from_wire.dart'
    show formatFromWire, formatToWire;
import '../../proposals/domain/proposal.dart'
    show BrandContractRow, ProposalEndKind, ProposalGroup;
import '../../payment/domain/payment_quote.dart';
import '../../payment/domain/payment_repository.dart' show PaymentMethod;
import '../domain/brand_usage_rights.dart';
import '../domain/contract.dart';
import '../domain/negotiation_repository.dart';
import '../domain/terms_version.dart';
import 'terms_version_from_wire.dart';

/// 생성된 API 클라이언트(`cora_api`)로 조건 판본을 읽고 확인한다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiNegotiationRepository implements NegotiationRepository {
  ApiNegotiationRepository(api.ApiClient client)
    : _terms = api.TermsApi(client),
      _inbox = api.ProposalInboxApi(client),
      _collaborations = api.CollaborationsApi(client),
      _contracts = api.ContractsApi(client);

  final api.TermsApi _terms;
  final api.ProposalInboxApi _inbox;
  final api.CollaborationsApi _collaborations;
  final api.ContractsApi _contracts;

  @override
  Future<TermsLatest> fetchLatest(String collaborationId) async {
    try {
      final m = await _terms.getLatestTerms(collaborationId);
      if (m == null) throw const NegotiationFailure();
      return _latest(m);
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      _log('읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<TermsHistory> fetchHistory(String collaborationId) async {
    try {
      final m = await _terms.listTermsVersions(collaborationId);
      if (m == null || m.versions.isEmpty) throw const NegotiationFailure();
      return TermsHistory(
        versions: [for (final v in m.versions) _version(v)],
        agreement: switch (m.agreement) {
          api.TermsAgreement.NONE => TermsAgreement.none,
          api.TermsAgreement.WAITING_BRAND => TermsAgreement.waitingBrand,
          api.TermsAgreement.WAITING_CREATOR => TermsAgreement.waitingCreator,
          // 마지막 칸을 `_`로 받지 않는다: 새 상태가 생겨도 합의로 오해하지 않고 분석이 먼저 알려 준다.
          api.TermsAgreement.AGREED => TermsAgreement.agreed,
        },
        editable: m.editable,
      );
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      _log('목록 읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<List<BrandContractRow>> fetchProposalInbox() async {
    try {
      final rows = await _inbox.listTermsProposalInbox();
      if (rows == null) throw const NegotiationFailure();
      return [for (final m in rows) _inboxRow(m)];
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      _log('제안함 읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<TermsVersion> propose(
    String collaborationId,
    int baseVersion,
    TermsChanges changes,
  ) async {
    try {
      final performance = changes.performance;
      final made = await _terms.proposeReward(
        collaborationId,
        api.ProposeRewardDto(
          baseVersion: baseVersion,
          title: changes.title,
          fee: changes.fee,
          productProvided: changes.productProvided,
          // 빠지면(null) 서버는 `끄기`로 읽는다. 안 바꾼 성과 추가도 이 값으로 명시한다.
          performance: performance == null
              ? null
              : api.RewardPerformanceDto(
                  ratePer1000: performance.ratePerThousand,
                  cap: performance.cap,
                ),
          startDate: changes.startDate,
          format: formatToWire(changes.format),
          pieces: changes.pieces,
          revisionScope: switch (changes.revisionScope) {
            RevisionScope.none => api.RevisionScope.NONE,
            RevisionScope.guideOnce => api.RevisionScope.GUIDE_1,
            RevisionScope.draftOnce => api.RevisionScope.DRAFT_1,
            RevisionScope.draftTwice => api.RevisionScope.DRAFT_2,
          },
          usageRights: switch (changes.usageRights) {
            BrandUsageRights.repostOnly => api.BrandUsageRights.REPOST_ONLY,
            BrandUsageRights.adsToo => api.BrandUsageRights.ADS_TOO,
            BrandUsageRights.none => api.BrandUsageRights.NONE,
          },
          payoutDays: changes.payoutDays,
        ),
      );
      if (made == null) throw const NegotiationFailure();
      return _version(made);
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      final parsed = _log('수정 제안', error);
      if (parsed.isStaleVersion) throw NegotiationStale(parsed.latestVersion);
      // 서버가 사용자 문구와 함께 거절한 409(결제 진행 중, 인스타그램 연동)와 400(바꾼 조건 없음)은 그 문구를 보인다.
      final status = parsed.status;
      if ((parsed.isConflict || status == 400) &&
          status != null &&
          status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  @override
  Future<void> confirm(String collaborationId, int version) async {
    try {
      await _terms.confirmTerms(collaborationId, version);
    } catch (error) {
      final parsed = _log('수락', error);
      if (parsed.isStaleVersion) throw NegotiationStale(parsed.latestVersion);
      // 서버가 사용자 문구와 함께 거절한 409(인스타그램 연동)는 그 문구를 보인다. 5xx 본문은 보이지 않는다.
      final status = parsed.status;
      if (parsed.isConflict && status != null && status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  @override
  Future<void> drop(String collaborationId, DropReason reason) async {
    try {
      await _collaborations.dropCollaboration(
        collaborationId,
        api.DropCollaborationDto(reason: _dropReason(reason)),
      );
    } catch (error) {
      final parsed = _log('그만두기', error);
      // 지금은 그만둘 수 없다는 409는 서버가 사용자 문구를 준다(5xx 본문은 보이지 않는다).
      final status = parsed.status;
      if (parsed.isConflict && status != null && status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  @override
  Future<Contract> fetchContract(String collaborationId) async {
    try {
      return _contractFrom(
        await _contracts.getContractWithHttpInfo(collaborationId),
      );
    } catch (error) {
      _log('계약 읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<Contract> consentAsCreator(
    String collaborationId,
    int version,
    List<String> accepted,
  ) async {
    try {
      return _contractFrom(
        await _contracts.consentContractAsCreatorWithHttpInfo(
          collaborationId,
          api.CreatorConsentDto(termsVersion: version, accepted: accepted),
        ),
      );
    } catch (error) {
      throw _consentError('크리에이터 동의', error);
    }
  }

  @override
  Future<({String paymentId, String checkoutUrl})> consentAsBrand(
    String collaborationId,
    int version,
    List<String> accepted,
    PaymentMethod method,
  ) async {
    try {
      final made = await _contracts.consentContractAsBrand(
        collaborationId,
        api.BrandConsentDto(
          termsVersion: version,
          accepted: accepted,
          method: switch (method) {
            PaymentMethod.card => api.PaymentMethod.CARD,
            PaymentMethod.transfer => api.PaymentMethod.TRANSFER,
            PaymentMethod.easyPay => api.PaymentMethod.EASY_PAY,
          },
        ),
      );
      if (made == null) throw const NegotiationFailure();
      return (paymentId: made.paymentId, checkoutUrl: made.checkoutUrl);
    } catch (error) {
      throw _consentError('브랜드 동의', error);
    }
  }

  /// 동의가 거절된 이유를 화면이 가를 수 있게 바꾼다. 옛 판본은 [NegotiationStale], 서버가 사용자 문구와 함께 거절한
  /// 409(지금은 동의할 수 없음)와 400(확인란 문구가 다름)은 [NegotiationRejected], 나머지는 [NegotiationFailure]다.
  static Exception _consentError(String action, Object error) {
    if (error is NegotiationFailure) return error;
    final parsed = _log(action, error);
    if (parsed.isStaleVersion) return NegotiationStale(parsed.latestVersion);
    final status = parsed.status;
    if ((parsed.isConflict || status == 400) &&
        status != null &&
        status < 500) {
      return NegotiationRejected(parsed.message);
    }
    return const NegotiationFailure();
  }

  /// 계약 응답을 직접 푼다. 생성된 `ContractModel`은 쓰지 않는다: 서버 문서(OpenAPI)에서 계약의 진행(`status`)이
  /// 협업·대화방의 `ContractProgress`(3값)와 같은 이름이라 한 열거형으로 합쳐졌고, 그대로 풀면 `NOT_READY`·
  /// `AWAITING_CREATOR`·`PAYING`에서 실패한다.
  static Contract _contractFrom(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 400) {
      throw api.ApiException(response.statusCode, body);
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) throw const NegotiationFailure();
    final terms = api.TermsVersionModel.fromJson(json['terms']);
    final quote = api.PaymentQuoteModel.fromJson(json['quote']);
    return Contract(
      status: switch (json['status']) {
        'NOT_READY' => ContractStatus.notReady,
        'AWAITING_CREATOR' => ContractStatus.awaitingCreator,
        'AWAITING_BRAND' => ContractStatus.awaitingBrand,
        'PAYING' => ContractStatus.paying,
        'CONCLUDED' => ContractStatus.concluded,
        _ => throw const NegotiationFailure(),
      },
      brandName: json['brandName'] as String,
      creatorName: json['creatorName'] as String,
      terms: terms == null ? null : termsVersionFromWire(terms),
      myConsentTexts: [
        for (final text in (json['myConsentTexts'] as List? ?? const []))
          text as String,
      ],
      voidedNotice: json['voidedNotice'] == true,
      quote: quote == null ? null : _quote(quote),
      creatorConsentedAt: _time(json['creatorConsentedAt']),
      brandConsentedAt: _time(json['brandConsentedAt']),
      concludedAt: _time(json['concludedAt']),
    );
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static PaymentQuote _quote(api.PaymentQuoteModel m) => PaymentQuote(
    creatorName: m.creatorName,
    creatorPhotoUrl: m.creatorPhotoUrl,
    format: formatFromWire(m.format),
    pieces: m.pieces,
    fixedCash: m.fixedCash,
    viewPayCap: m.perViewCap,
    escrow: m.escrow,
    fee: m.fee,
    total: m.total,
  );

  static BrandContractRow _inboxRow(api.ProposalInboxRowModel m) =>
      BrandContractRow(
        collaborationId: m.collaborationId,
        name: m.counterpart.name,
        photoUrl: m.counterpart.photoUrl,
        group: switch (m.group) {
          api.ProposalGroup.MY_TURN => ProposalGroup.myTurn,
          api.ProposalGroup.WAITING => ProposalGroup.waiting,
          _ => ProposalGroup.ended,
        },
        format: formatFromWire(m.format),
        pieces: m.pieces,
        version: m.version,
        counter: m.counter,
        endKind: switch (m.endKind) {
          api.ProposalEndKind.AGREED => ProposalEndKind.agreed,
          api.ProposalEndKind.ENDED => ProposalEndKind.ended,
          _ => null,
        },
        myDropReason: switch (m.myDropReason) {
          api.DropReasonChoice.SCHEDULE => DropReason.schedule,
          api.DropReasonChoice.BUDGET => DropReason.budget,
          api.DropReasonChoice.DIRECTION => DropReason.direction,
          api.DropReasonChoice.OTHER => DropReason.other,
          _ => null,
        },
      );

  static api.DropReasonChoice _dropReason(DropReason reason) =>
      switch (reason) {
        DropReason.schedule => api.DropReasonChoice.SCHEDULE,
        DropReason.budget => api.DropReasonChoice.BUDGET,
        DropReason.direction => api.DropReasonChoice.DIRECTION,
        DropReason.other => api.DropReasonChoice.OTHER,
      };

  /// 원인만 한 줄 남긴다(응답 본문과 문구는 남기지 않는다).
  static ApiError _log(String action, Object error) {
    final parsed = ApiError.from(error);
    if (kDebugMode) {
      debugPrint(
        '[negotiation] $action 실패: 종류=${error.runtimeType} '
        '상태=${parsed.status} 코드=${parsed.code}',
      );
    }
    return parsed;
  }

  static TermsLatest _latest(api.TermsLatestModel m) => TermsLatest(
    terms: _version(m.terms),
    mine: m.mine,
    myTurn: m.myTurn,
    needsInstagram: m.needsInstagram,
    notice: m.notice,
    reasons: [for (final r in m.reasons) _reason(r)],
    fields: List.of(m.fields),
    followers: m.followers,
  );

  static TermsVersion _version(api.TermsVersionModel t) =>
      termsVersionFromWire(t);

  static MatchReason _reason(api.MatchReason r) => switch (r) {
    api.MatchReason.FIELD => MatchReason.field,
    api.MatchReason.FACE => MatchReason.face,
    api.MatchReason.SCRIPT => MatchReason.script,
    api.MatchReason.FEE => MatchReason.fee,
    _ => MatchReason.trial,
  };
}
