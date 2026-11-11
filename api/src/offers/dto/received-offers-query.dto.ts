import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export const RECEIVED_TABS = ['new', 'active'] as const;
export type ReceivedTab = (typeof RECEIVED_TABS)[number];

export class ReceivedOffersQueryDto {
  @ApiProperty({
    enum: RECEIVED_TABS,
    enumName: 'ReceivedOfferTab',
    description:
      'new: 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼. active: 수락한 오퍼.',
  })
  @IsIn(RECEIVED_TABS)
  tab!: ReceivedTab;
}
