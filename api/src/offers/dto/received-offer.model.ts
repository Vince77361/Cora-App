import { ApiProperty } from '@nestjs/swagger';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';
import { StoreSummaryModel } from '../../stores/dto/store-public.model';
import { OFFER_VIEWS } from '../offer-rules';
import type { OfferView } from '../offer-rules';

// 크리에이터가 보는 받은 오퍼 한 장.
export class ReceivedOfferModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ type: StoreSummaryModel })
  store!: StoreSummaryModel;

  @ApiProperty({ type: String, nullable: true })
  storeIntro!: string | null;

  @ApiProperty({ type: String, nullable: true })
  bestShootingTime!: string | null;

  @ApiProperty({ type: OfferTermsModel })
  terms!: OfferTermsModel;

  @ApiProperty({
    enum: OFFER_VIEWS,
    enumName: 'OfferView',
    description: '크리에이터에게 보이는 상태. 거절은 바로 DECLINED로 보인다.',
  })
  view!: OfferView;

  @ApiProperty({ format: 'date-time', description: '도착한 시각(ISO 8601).' })
  receivedAt!: string;

  @ApiProperty({
    description: '방금 거절해 30초 안에 되돌릴 수 있으면 true.',
  })
  canUndoDecline!: boolean;
}
