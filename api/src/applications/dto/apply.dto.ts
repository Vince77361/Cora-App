import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { PROPOSAL_POLICY } from '../../common/collaboration-policy';

// 길이는 앞뒤 공백을 자른 뒤에 잰다. 문자열이 아니면 그대로 둬서 IsString이 거절하게 한다.
const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class ApplyDto {
  @ApiProperty({
    required: false,
    maxLength: PROPOSAL_POLICY.pitchMax,
    description: '사장님이 지원자 목록에서 보는 한 줄. 비우면 저장하지 않는다.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(PROPOSAL_POLICY.pitchMax)
  pitch?: string;
}
