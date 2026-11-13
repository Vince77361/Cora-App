import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { VIEW_REPORT_POLICY } from '../../common/collaboration-policy';

export class DisputeViewReportDto {
  @ApiProperty({
    description: '이의 사유. 앞뒤 공백을 뺀 글자 수가 1~200자여야 한다.',
    minLength: 1,
    maxLength: VIEW_REPORT_POLICY.disputeReasonMax,
  })
  @IsString()
  @MinLength(1)
  @MaxLength(VIEW_REPORT_POLICY.disputeReasonMax)
  reason!: string;
}
