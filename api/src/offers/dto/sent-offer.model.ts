import { ApiProperty } from '@nestjs/swagger';
import { CreatorSummaryModel } from '../../creators/dto/creator-profile.model';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';
import { OFFER_VIEWS } from '../offer-rules';
import type { OfferView } from '../offer-rules';

// 사장님이 보는 보낸 오퍼 한 줄.
export class SentOfferModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ type: CreatorSummaryModel })
  creator!: CreatorSummaryModel;

  @ApiProperty({ type: OfferTermsModel })
  terms!: OfferTermsModel;

  @ApiProperty({
    enum: OFFER_VIEWS,
    enumName: 'OfferView',
    description:
      '사장님에게 보이는 상태. 거절은 30초가 지나야 DECLINED로 보이고 그전에는 WAITING이다.',
  })
  view!: OfferView;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '수락됐고 아직 결제 기한 전일 때 남은 날(올림). 아니면 null.',
  })
  paymentDaysLeft!: number | null;

  @ApiProperty({ format: 'date-time', description: '보낸 시각(ISO 8601).' })
  sentAt!: string;
}
