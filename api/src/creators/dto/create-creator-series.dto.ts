import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { PROPOSAL_POLICY } from '../../common/collaboration-policy';

// 길이는 앞뒤 공백을 자른 뒤에 잰다. 문자열이 아니면 그대로 둬서 IsString이 거절하게 한다.
const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class CreateCreatorSeriesDto {
  @ApiProperty({ minLength: 1, maxLength: PROPOSAL_POLICY.seriesNameMax })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(PROPOSAL_POLICY.seriesNameMax)
  name!: string;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  @IsEnum(ContentFormat)
  format!: ContentFormat;

  @ApiProperty({
    required: false,
    maxLength: PROPOSAL_POLICY.seriesNoteMax,
    description: '시리즈를 한 줄로 설명한다. 비우면 저장하지 않는다.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(PROPOSAL_POLICY.seriesNoteMax)
  note?: string;
}
