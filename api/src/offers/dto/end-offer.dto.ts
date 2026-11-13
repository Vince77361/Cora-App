import { ApiProperty } from '@nestjs/swagger';
import { OfferEndReason } from '@prisma/client';
import { IsEnum } from 'class-validator';

// 제안을 끝낼 때 고르는 사유(네 가지). 상대에게는 알림으로만 가고 사유는 제안함에 남는다.
export class EndOfferDto {
  @ApiProperty({ enum: OfferEndReason, enumName: 'OfferEndReason' })
  @IsEnum(OfferEndReason)
  reason!: OfferEndReason;
}
