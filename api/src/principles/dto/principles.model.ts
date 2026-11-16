import { ApiProperty } from '@nestjs/swagger';
import { FeeBand, IndustryCategory, ProductTrialDays } from '@prisma/client';

// 크리에이터의 협업 원칙. 본인만 읽는다(브랜드가 보는 카드는 4번 계획의 카드 모델이 꼬리표로 줄여 낸다).
export class PrinciplesModel {
  // 받고 싶은 분야. 일반 업종 중 1개 이상.
  // (설명은 주석으로만 둔다: 같은 enum을 쓰는 다른 필드의 문서에 enum 설명으로 번진다.)
  @ApiProperty({
    enum: IndustryCategory,
    enumName: 'IndustryCategory',
    isArray: true,
  })
  fields!: IndustryCategory[];

  // 피하는 업종. 민감 업종 중 0개 이상.
  @ApiProperty({
    enum: IndustryCategory,
    enumName: 'IndustryCategory',
    isArray: true,
  })
  blockedIndustries!: IndustryCategory[];

  @ApiProperty()
  faceOk!: boolean;

  @ApiProperty()
  scriptOk!: boolean;

  @ApiProperty()
  honestReview!: boolean;

  @ApiProperty({ enum: FeeBand, enumName: 'FeeBand' })
  feeBand!: FeeBand;

  @ApiProperty({ enum: ProductTrialDays, enumName: 'ProductTrialDays' })
  trialDays!: ProductTrialDays;
}
