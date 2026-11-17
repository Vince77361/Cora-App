import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

// 협의를 그만두는 이유(앱의 선택지). 저장만 하고 상대에게는 알리지 않는다.
export const DROP_CHOICES = [
  'SCHEDULE',
  'BUDGET',
  'DIRECTION',
  'OTHER',
] as const;
export type DropChoice = (typeof DROP_CHOICES)[number];

export class DropCollaborationDto {
  @ApiProperty({
    enum: DROP_CHOICES,
    enumName: 'DropReasonChoice',
    description:
      '그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 "이번에는 함께하기 어렵대요."만 본다).',
  })
  @IsIn(DROP_CHOICES)
  reason!: DropChoice;
}
