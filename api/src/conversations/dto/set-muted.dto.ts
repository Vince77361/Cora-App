import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class SetMutedDto {
  @ApiProperty({ description: '이 방의 알림을 끄려면 true.' })
  @IsBoolean()
  muted!: boolean;
}

export class MutedModel {
  @ApiProperty()
  muted!: boolean;
}
