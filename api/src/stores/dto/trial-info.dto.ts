import { ApiProperty } from '@nestjs/swagger';
import {
  IsInt,
  IsString,
  Max,
  Min,
  ValidateBy,
  ValidationArguments,
} from 'class-validator';
import { STORE_PAGE_POLICY } from '../../common/collaboration-policy';

// 'YYYY-MM-DD'이고 달력에 있는 날짜인가(2월 30일 같은 값을 막는다).
export function isCalendarDate(value: unknown): boolean {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
}

// 체험단 계약 정보. 사장님이 직접 넣는 값이다.
export class TrialInfoDto {
  @ApiProperty({
    minimum: 1,
    maximum: STORE_PAGE_POLICY.trialMonthlyFeeMax,
    description: '월 계약 금액(원).',
  })
  @IsInt()
  @Min(1)
  @Max(STORE_PAGE_POLICY.trialMonthlyFeeMax)
  monthlyFee!: number;

  @ApiProperty({
    example: '2026-12-10',
    description: '계약 종료일(한국 날짜, YYYY-MM-DD).',
  })
  @IsString()
  @ValidateBy({
    name: 'isCalendarDate',
    validator: {
      validate: (value: unknown): boolean => isCalendarDate(value),
      defaultMessage: (args?: ValidationArguments): string =>
        `${args?.property ?? 'endsOn'}은 YYYY-MM-DD 모양의 날짜여야 해요.`,
    },
  })
  endsOn!: string;

  @ApiProperty({
    minimum: 1,
    maximum: STORE_PAGE_POLICY.trialPostCountMax,
    description: '석 달 동안 받은 글 수.',
  })
  @IsInt()
  @Min(1)
  @Max(STORE_PAGE_POLICY.trialPostCountMax)
  postCount!: number;
}
