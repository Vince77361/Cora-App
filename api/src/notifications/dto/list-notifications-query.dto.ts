import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export const NOTIFICATION_TAB_FILTERS = [
  'ALL',
  'MATCHING',
  'COLLABORATION',
  'SETTLEMENT',
] as const;
export type NotificationTabFilter = (typeof NOTIFICATION_TAB_FILTERS)[number];

export class ListNotificationsQueryDto {
  @ApiPropertyOptional({
    enum: NOTIFICATION_TAB_FILTERS,
    enumName: 'NotificationTabFilter',
    description: '없으면 ALL.',
  })
  @IsOptional()
  @IsIn(NOTIFICATION_TAB_FILTERS)
  tab?: NotificationTabFilter;

  @ApiPropertyOptional({
    description: '이전 쪽의 nextCursor. 처음 쪽은 비운다.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  cursor?: string;
}
