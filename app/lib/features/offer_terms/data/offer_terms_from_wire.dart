import 'package:cora_api/api.dart' as api;

import '../domain/offer_terms.dart';

/// 서버가 보낸 확정 조건을 앱의 타입으로 바꾼다. 생성된 타입은 data 계층 밖으로 새지 않게 여기서 끊는다.
///
/// 서버는 보상을 세 요소로 보낸다. 식사권은 이름과 금액이 모두 있을 때만, 조회수 수당은 단가와
/// 상한이 모두 있을 때만 있는 것으로 본다. 읽을 때는 범위를 검사하지 않는다(옛 협업의 값도 그대로 읽는다).
OfferTerms offerTermsFromWire(api.OfferTermsModel t) {
  final voucherName = t.voucherName;
  final voucherValue = t.voucherValue;
  final rate = t.viewRatePerThousand;
  final cap = t.perViewCap;
  return OfferTerms(
    format: formatFromWire(t.format),
    pieces: t.pieces,
    reward: Reward(
      voucher: voucherName == null || voucherValue == null
          ? null
          : Voucher(
              name: voucherName,
              value: voucherValue,
              people: t.voucherPeople,
            ),
      fixedCash: t.fixedCash,
      viewPay: rate == null || cap == null
          ? null
          : ViewPay(ratePerThousand: rate, cap: cap),
    ),
    usageRights: usageRightsFromWire(t.usageRights),
  );
}

ContentFormat formatFromWire(api.ContentFormat f) => switch (f) {
  api.ContentFormat.SHORTS => ContentFormat.shorts,
  api.ContentFormat.REELS => ContentFormat.reels,
  api.ContentFormat.CARD_NEWS => ContentFormat.cardNews,
  _ => ContentFormat.blog,
};

api.ContentFormat formatToWire(ContentFormat f) => switch (f) {
  ContentFormat.shorts => api.ContentFormat.SHORTS,
  ContentFormat.reels => api.ContentFormat.REELS,
  ContentFormat.cardNews => api.ContentFormat.CARD_NEWS,
  ContentFormat.blog => api.ContentFormat.BLOG,
};

UsageRights usageRightsFromWire(api.UsageRights u) => switch (u) {
  api.UsageRights.STORE_REPOST_3M => UsageRights.storeRepost3m,
  api.UsageRights.STORE_REPOST_6M => UsageRights.storeRepost6m,
  _ => UsageRights.none,
};

api.UsageRights usageRightsToWire(UsageRights u) => switch (u) {
  UsageRights.storeRepost3m => api.UsageRights.STORE_REPOST_3M,
  UsageRights.storeRepost6m => api.UsageRights.STORE_REPOST_6M,
  UsageRights.none => api.UsageRights.NONE,
};

/// 사장님이 고른 보상을 서버의 보상 입력으로 바꾼다. 없는 요소는 담지 않는다.
api.RewardInputDto rewardToWire(Reward reward) {
  final voucher = reward.voucher;
  final viewPay = reward.viewPay;
  return api.RewardInputDto(
    voucher: voucher == null
        ? null
        : api.VoucherInputDto(
            name: voucher.name,
            value: voucher.value,
            people: voucher.people,
          ),
    fixedCash: reward.fixedCash,
    perView: viewPay == null
        ? null
        : api.PerViewInputDto(
            ratePerThousand: viewPay.ratePerThousand,
            cap: viewPay.cap,
          ),
  );
}
