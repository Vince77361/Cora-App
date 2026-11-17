import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export const MESSAGES_PAGE_MAX = 50;

export class ListMessagesQuery {
  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: 0,
    description: '이 번호보다 큰 메시지(빠진 번호를 받을 때).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  afterSeq?: number;

  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: 1,
    description: '이 번호보다 작은 메시지(위로 넘겨 볼 때).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  beforeSeq?: number;

  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: 1,
    maximum: MESSAGES_PAGE_MAX,
    default: MESSAGES_PAGE_MAX,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MESSAGES_PAGE_MAX)
  limit?: number;
}
