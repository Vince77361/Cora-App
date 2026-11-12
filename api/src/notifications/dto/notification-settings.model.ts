import { ApiProperty } from '@nestjs/swagger';
import { QuietHours } from '@prisma/client';

export class NotificationSettingsModel {
  @ApiProperty({ description: '서로 관심.' })
  mutualInterest!: boolean;

  @ApiProperty({ description: '새 오퍼와 제안.' })
  offers!: boolean;

  @ApiProperty({ description: '대화 메시지.' })
  messages!: boolean;

  @ApiProperty({ description: '정산(지급 예정, 지급 완료).' })
  settlement!: boolean;

  @ApiProperty({ description: '추천 소식. 처음 값은 꺼짐.' })
  recommendations!: boolean;

  @ApiProperty({ enum: QuietHours, enumName: 'QuietHours' })
  quietHours!: QuietHours;

  @ApiProperty({
    description: '다섯 스위치 가운데 켜진 수(E4의 "{n}개 켜짐").',
  })
  enabledCount!: number;
}
