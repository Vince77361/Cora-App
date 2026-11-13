import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

// 조회수는 DB의 32비트 정수 안에서 받는다. 터무니없이 큰 값은 계산 전에 막는다.
export const MAX_EVIDENCE_VIEWS = 1_000_000_000;

export class SubmitViewEvidenceDto {
  @ApiProperty({
    description:
      '올린 캡처의 경로. POST /uploads/photos(purpose VIEW_EVIDENCE)가 내준 내 경로만 받는다.',
    maxLength: 300,
  })
  @IsString()
  @MaxLength(300)
  @Matches(/^[A-Za-z0-9/._-]+$/)
  path!: string;

  @ApiProperty({
    type: 'integer',
    minimum: 0,
    maximum: MAX_EVIDENCE_VIEWS,
    description: '캡처에서 읽은 조회수.',
  })
  @IsInt()
  @Min(0)
  @Max(MAX_EVIDENCE_VIEWS)
  views!: number;
}
