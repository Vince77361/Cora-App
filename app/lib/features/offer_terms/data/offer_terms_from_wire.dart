import 'package:cora_api/api.dart' as api;

import '../domain/offer_terms.dart';

/// 서버가 보낸 확정 조건을 앱의 타입으로 바꾼다. 생성된 타입은 data 계층 밖으로 새지 않게 여기서 끊는다.
///
/// 서버는 보상을 세 요소(식사권, 고정 현금, 조회수 수당)로 보낸다. 앱 도메인(Task 7이 바꾼다)이 아직 옛 모양이라
/// 보상 종류는 식사권·조회수 수당이 있는지로 가르고, 단가는 1,000회당 금액을 건당 금액으로 환산한다.
OfferTerms offerTermsFromWire(api.OfferTermsModel t) => OfferTerms(
  format: switch (t.format) {
    api.ContentFormat.SHORTS => ContentFormat.shorts,
    api.ContentFormat.REELS => ContentFormat.reels,
    api.ContentFormat.CARD_NEWS => ContentFormat.cardNews,
    _ => ContentFormat.blog,
  },
  rewardType: switch ((t.voucherName != null, t.perViewCap != null)) {
    (true, false) => RewardType.voucher,
    (false, true) => RewardType.perView,
    _ => RewardType.both,
  },
  voucherName: t.voucherName,
  voucherValue: t.voucherValue,
  perViewAmount: t.viewRatePerThousand == null
      ? null
      : t.viewRatePerThousand! ~/ 1000,
  perViewCap: t.perViewCap,
);

/// 사장님이 고른 조건을 서버의 보상 입력으로 바꾼다. 조회수 단가와 상한은 비워 보내
/// 서버가 가게의 모집 조건(없으면 기본값)으로 채우게 한다.
api.RewardInputDto rewardInputToWire(OfferTermsInput input) {
  final hasVoucher =
      input.rewardType == RewardType.voucher ||
      input.rewardType == RewardType.both;
  final hasPerView =
      input.rewardType == RewardType.perView ||
      input.rewardType == RewardType.both;
  return api.RewardInputDto(
    voucher: hasVoucher
        ? api.VoucherInputDto(
            name: input.voucherName,
            value: input.voucherValue,
          )
        : null,
    perView: hasPerView ? api.PerViewInputDto() : null,
  );
}
