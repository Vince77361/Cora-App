import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

// 진행 중(수락한) 오퍼는 오퍼가 아니라 협업 목록이 보여 주므로 받은 오퍼 목록에는 새 오퍼 탭만 남았다.
// 값이 하나뿐이어도 tab을 남긴다: 앱이 이미 이 모양으로 부르고, 탭이 다시 늘어도 계약이 깨지지 않는다.
export const RECEIVED_TABS = ['new'] as const;
export type ReceivedTab = (typeof RECEIVED_TABS)[number];

export class ReceivedOffersQueryDto {
  @ApiProperty({
    enum: RECEIVED_TABS,
    enumName: 'ReceivedOfferTab',
    description: 'new: 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼.',
  })
  @IsIn(RECEIVED_TABS)
  tab!: ReceivedTab;
}
