import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export const ADVANCE_STEPS = ['DRAFTS', 'TERMS'] as const;
export type AdvanceStep = (typeof ADVANCE_STEPS)[number];

// PAGE는 분석이 끝나면 서버가 정하고, DONE은 공개가 정한다. 앱이 보낼 수 있는 것은 중간 두 단계뿐이다.
export class AdvanceOnboardingDto {
  @ApiProperty({ enum: ADVANCE_STEPS, enumName: 'AdvanceOnboardingStep' })
  @IsIn(ADVANCE_STEPS)
  step!: AdvanceStep;
}
