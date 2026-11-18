import { ApiProperty } from '@nestjs/swagger';
import { FeaturedPostKind } from '@prisma/client';

// 연동한 인스타그램 계정의 게시물 한 개(고르기 격자의 한 칸).
export class InstagramPostModel {
  @ApiProperty({ description: '인스타그램 게시물 ID.' })
  id!: string;

  @ApiProperty({ enum: FeaturedPostKind, enumName: 'FeaturedPostKind' })
  kind!: FeaturedPostKind;

  @ApiProperty({ type: String, nullable: true, description: '게시물 글 전체.' })
  caption!: string | null;

  @ApiProperty({ description: '격자에 보일 그림의 주소.' })
  thumbnailUrl!: string;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '영상 길이(초). 사진이거나 모르면 null. 60초를 넘으면 가져올 수 없다.',
  })
  durationSec!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '영상 파일 크기(바이트). 사진이거나 모르면 null. 100MB를 넘으면 가져올 수 없다.',
  })
  sizeBytes!: number | null;
}
