import { ApiProperty } from '@nestjs/swagger';
import { OfferEndReason } from '@prisma/client';
import { OFFER_PARTIES } from './offer-version.model';
import type { OfferPartyValue } from './offer-version.model';

export const OFFER_END_STATUSES = ['CANCELLED', 'DECLINED'] as const;
export type OfferEndStatus = (typeof OFFER_END_STATUSES)[number];

// 제안을 끝낸 결과. 최신 판본을 쓴 쪽이 끝내면 CANCELLED, 받은 쪽이 끝내면 DECLINED다.
export class EndedOfferModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: OFFER_END_STATUSES, enumName: 'OfferEndStatus' })
  status!: OfferEndStatus;

  @ApiProperty({ enum: OfferEndReason, enumName: 'OfferEndReason' })
  endReason!: OfferEndReason;

  @ApiProperty({
    enum: OFFER_PARTIES,
    enumName: 'OfferParty',
    description: '끝낸 쪽.',
  })
  endedBy!: OfferPartyValue;
}
