import { ApiProperty } from '@nestjs/swagger';
import { PassReason, SwipeTargetKind } from '@prisma/client';
import { IsEnum, IsUUID } from 'class-validator';

// 넘긴 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
export class PassReasonDto {
  @ApiProperty({ enum: SwipeTargetKind, enumName: 'SwipeTargetKind' })
  @IsEnum(SwipeTargetKind)
  targetKind!: SwipeTargetKind;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  targetId!: string;

  @ApiProperty({ enum: PassReason, enumName: 'PassReason' })
  @IsEnum(PassReason)
  reason!: PassReason;
}
