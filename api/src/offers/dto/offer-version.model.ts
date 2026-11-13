import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';

export const OFFER_PARTIES = ['STORE', 'CREATOR'] as const;
export type OfferPartyValue = (typeof OFFER_PARTIES)[number];

// 연재 제안. 이름·형식·메모는 따로 비어 있을 수 있어 모두 null을 허용한다. 셋이 모두 비면 연재 자체가 null이다.
export class OfferVersionSeriesModel {
  @ApiProperty({ type: String, nullable: true })
  name!: string | null;

  @ApiProperty({
    enum: ContentFormat,
    enumName: 'ContentFormat',
    nullable: true,
  })
  format!: ContentFormat | null;

  @ApiProperty({ type: String, nullable: true })
  note!: string | null;
}

// 오퍼 조건의 한 판본. 판본은 만들기만 하고 고치거나 지우지 않는다.
export class OfferVersionModel {
  @ApiProperty({ type: 'integer', description: '판본 번호. 1부터 시작한다.' })
  number!: number;

  @ApiProperty({
    enum: OFFER_PARTIES,
    enumName: 'OfferParty',
    description: '이 판본을 쓴 쪽.',
  })
  authorParty!: OfferPartyValue;

  @ApiProperty({ type: OfferTermsModel })
  terms!: OfferTermsModel;

  @ApiProperty({ type: String, nullable: true })
  idea!: string | null;

  @ApiProperty({ type: [String] })
  principles!: string[];

  @ApiProperty({ type: OfferVersionSeriesModel, nullable: true })
  series!: OfferVersionSeriesModel | null;

  @ApiProperty({ format: 'date-time' })
  createdAt!: Date;
}
