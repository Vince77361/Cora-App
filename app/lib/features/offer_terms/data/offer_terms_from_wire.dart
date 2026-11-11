import 'package:cora_api/api.dart' as api;

import '../domain/offer_terms.dart';

/// 서버가 보낸 확정 조건을 앱의 타입으로 바꾼다. 생성된 타입은 data 계층 밖으로 새지 않게 여기서 끊는다.
OfferTerms offerTermsFromWire(api.OfferTermsModel t) => OfferTerms(
  format: switch (t.format) {
    api.ContentFormat.SHORTS => ContentFormat.shorts,
    api.ContentFormat.REELS => ContentFormat.reels,
    api.ContentFormat.CARD_NEWS => ContentFormat.cardNews,
    _ => ContentFormat.blog,
  },
  rewardType: switch (t.rewardType) {
    api.RewardType.VOUCHER => RewardType.voucher,
    api.RewardType.PER_VIEW => RewardType.perView,
    _ => RewardType.both,
  },
  voucherName: t.voucherName,
  voucherValue: t.voucherValue,
  perViewAmount: t.perViewAmount,
  perViewCap: t.perViewCap,
);
