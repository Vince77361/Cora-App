import { ApiProperty } from '@nestjs/swagger';
import { QuietHours } from '@prisma/client';
import { IsBoolean, IsEnum } from 'class-validator';

// PUT은 통째로 바꾼다: 다섯 스위치와 방해 금지를 모두 받는다. enabledCount는 서버가 센다.
export class UpdateNotificationSettingsDto {
  @ApiProperty()
  @IsBoolean()
  mutualInterest!: boolean;

  @ApiProperty()
  @IsBoolean()
  offers!: boolean;

  @ApiProperty()
  @IsBoolean()
  messages!: boolean;

  @ApiProperty()
  @IsBoolean()
  settlement!: boolean;

  @ApiProperty()
  @IsBoolean()
  recommendations!: boolean;

  @ApiProperty({ enum: QuietHours, enumName: 'QuietHours' })
  @IsEnum(QuietHours)
  quietHours!: QuietHours;
}
