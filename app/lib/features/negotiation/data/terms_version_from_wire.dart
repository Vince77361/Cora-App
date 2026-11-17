import 'package:cora_api/api.dart' as api;

import '../../offer_terms/data/offer_terms_from_wire.dart' show formatFromWire;
import '../../offer_terms/domain/offer_terms.dart' show ViewPay;
import '../domain/brand_usage_rights.dart';
import '../domain/terms_version.dart';

/// 서버의 조건 판본(`TermsVersionModel`)을 앱의 [TermsVersion]으로. 협의 화면과 대화방이 같은 변환을 쓴다.
TermsVersion termsVersionFromWire(api.TermsVersionModel t) => TermsVersion(
  version: t.version,
  title: t.title,
  fee: t.fee,
  productProvided: t.productProvided,
  performance: t.performance == null
      ? null
      : ViewPay(
          ratePerThousand: t.performance!.ratePer1000,
          cap: t.performance!.cap,
        ),
  format: formatFromWire(t.format),
  pieces: t.pieces,
  startDate: dateOnly(t.startDate),
  revisionScope: switch (t.revisionScope) {
    api.RevisionScope.NONE => RevisionScope.none,
    api.RevisionScope.GUIDE_1 => RevisionScope.guideOnce,
    api.RevisionScope.DRAFT_1 => RevisionScope.draftOnce,
    _ => RevisionScope.draftTwice,
  },
  usageRights: switch (t.usageRights) {
    api.BrandUsageRights.REPOST_ONLY => BrandUsageRights.repostOnly,
    api.BrandUsageRights.ADS_TOO => BrandUsageRights.adsToo,
    _ => BrandUsageRights.none,
  },
  payoutDays: t.payoutDays,
  maxCash: t.maxCash,
  brandConfirmed: t.brandConfirmed,
  creatorConfirmed: t.creatorConfirmed,
  proposedBy: switch (t.proposedBy) {
    api.TermsProposer.BRAND => TermsProposer.brand,
    api.TermsProposer.CREATOR => TermsProposer.creator,
    _ => TermsProposer.system,
  },
  changedFields: [for (final f in t.changedFields) _field(f)],
  createdAt: t.createdAt,
  previousMaxCash: t.previousMaxCash,
);

TermsField _field(api.TermsField f) => switch (f) {
  api.TermsField.TITLE => TermsField.title,
  api.TermsField.FEE => TermsField.fee,
  api.TermsField.PERFORMANCE => TermsField.performance,
  api.TermsField.START_DATE => TermsField.startDate,
  api.TermsField.DELIVERABLE => TermsField.deliverable,
  api.TermsField.PRODUCT => TermsField.product,
  api.TermsField.REVISION => TermsField.revision,
  api.TermsField.USAGE => TermsField.usage,
  _ => TermsField.payout,
};

/// 서버가 날짜를 UTC 시각으로 보내도 앱 시계의 그날 0시로 둔다(날짜만 뜻이 있다).
DateTime dateOnly(DateTime at) => DateTime(at.year, at.month, at.day);
