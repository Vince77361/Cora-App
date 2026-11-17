import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreatorConsentDto {
  @ApiProperty({
    type: 'integer',
    description:
      '동의하려는 판본 번호. 최신이 아니면 409 STALE_VERSION(latestVersion).',
  })
  @IsInt()
  @Min(1)
  termsVersion!: number;

  @ApiProperty({
    type: String,
    isArray: true,
    description:
      '사용자가 확인한 세 줄. 서버가 만든 문구(myConsentTexts)와 정확히 같아야 한다.',
  })
  @IsArray()
  @ArrayMinSize(3)
  @ArrayMaxSize(3)
  @IsString({ each: true })
  @MaxLength(200, { each: true })
  accepted!: string[];
}
