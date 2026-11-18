import { ApiProperty } from '@nestjs/swagger';
import { FeaturedPostKind, FeaturedPostSource } from '@prisma/client';

// 크리에이터의 대표 게시물 한 개. 응답에는 파일 경로가 아니라 읽을 수 있는 주소만 담는다.
export class FeaturedPostModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ type: 'integer', minimum: 1, maximum: 4 })
  position!: number;

  @ApiProperty({ enum: FeaturedPostSource, enumName: 'FeaturedPostSource' })
  source!: FeaturedPostSource;

  @ApiProperty({ enum: FeaturedPostKind, enumName: 'FeaturedPostKind' })
  kind!: FeaturedPostKind;

  @ApiProperty({
    description: '카드에 보이는 그림. 썸네일이 있으면 썸네일, 없으면 사진.',
  })
  photoUrl!: string;

  @ApiProperty({ description: '사진이나 영상 파일의 주소.' })
  mediaUrl!: string;

  @ApiProperty({ type: String, nullable: true, maxLength: 40 })
  caption!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '인스타그램에서 가져왔으면 원본 게시물 ID.',
  })
  instagramMediaId!: string | null;
}
