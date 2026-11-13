import { ApiProperty } from '@nestjs/swagger';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';
import { StoreSummaryModel } from '../../stores/dto/store-public.model';
import { OFFER_VIEWS } from '../offer-rules';
import type { OfferView } from '../offer-rules';

// 크리에이터가 보는 받은 오퍼 한 장.
export class ReceivedOfferModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: '수락돼 만들어진 협업의 id. 수락 전이면 null.',
  })
  collaborationId!: string | null;

  @ApiProperty({ type: StoreSummaryModel })
  store!: StoreSummaryModel;

  @ApiProperty({ type: String, nullable: true })
  storeIntro!: string | null;

  @ApiProperty({ type: String, nullable: true })
  bestShootingTime!: string | null;

  @ApiProperty({ type: OfferTermsModel })
  terms!: OfferTermsModel;

  @ApiProperty({
    type: 'integer',
    description: '최신 판본의 번호. 수락은 이 번호와 함께 보낸다.',
  })
  version!: number;

  @ApiProperty({
    description:
      '크리에이터가 응답할 차례이면 true. 답을 기다리는 오퍼에만 해당한다.',
  })
  myTurn!: boolean;

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

  @ApiProperty({
    description:
      '릴스·카드뉴스의 조회수 보상을 받으려면 인스타그램 연동이 필요한데 아직 연동하지 않았으면 true. true인 오퍼는 수락할 수 없다. 기다리는 중(WAITING)이 아닌 오퍼는 항상 false.',
  })
  needsInstagram!: boolean;
}
