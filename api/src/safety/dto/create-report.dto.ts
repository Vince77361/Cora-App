import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export const REPORT_TARGET_KINDS = ['USER', 'CONVERSATION'] as const;
export const REPORT_REASONS = ['SPAM', 'ABUSE', 'FRAUD', 'OTHER'] as const;
export const REPORT_DETAIL_MAX = 500;

export class CreateReportDto {
  @ApiProperty({
    enum: REPORT_TARGET_KINDS,
    enumName: 'ReportTargetKind',
    description:
      'USER는 내가 참가한 방의 상대, CONVERSATION은 내가 참가한 방이다.',
  })
  @IsIn(REPORT_TARGET_KINDS)
  targetKind!: (typeof REPORT_TARGET_KINDS)[number];

  @ApiProperty({
    format: 'uuid',
    description:
      '사용자 또는 대화방의 id. 내 방이나 그 상대가 아니면 404다(형식이 틀려도 같다).',
  })
  @IsString()
  @MaxLength(64)
  targetId!: string;

  @ApiProperty({
    enum: REPORT_REASONS,
    enumName: 'ReportReason',
    description:
      'SPAM 광고·스팸, ABUSE 부적절한 말, FRAUD 사기 의심, OTHER 기타.',
  })
  @IsIn(REPORT_REASONS)
  reason!: (typeof REPORT_REASONS)[number];

  @ApiProperty({
    required: false,
    maxLength: REPORT_DETAIL_MAX,
    description: '자세한 내용(선택, 500자까지).',
  })
  @IsOptional()
  @IsString()
  @MaxLength(REPORT_DETAIL_MAX)
  detail?: string;
}
