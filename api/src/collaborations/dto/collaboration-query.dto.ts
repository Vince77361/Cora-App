import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export const COLLABORATION_SCOPES = ['active', 'done'] as const;
export type CollaborationScope = (typeof COLLABORATION_SCOPES)[number];

export class CollaborationQueryDto {
  @ApiProperty({
    enum: COLLABORATION_SCOPES,
    enumName: 'CollaborationScope',
    description:
      'active: 진행 중(결제 대기·보관 중·집계 중·멈춤 등). done: 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터.',
  })
  @IsIn(COLLABORATION_SCOPES)
  scope!: CollaborationScope;
}
