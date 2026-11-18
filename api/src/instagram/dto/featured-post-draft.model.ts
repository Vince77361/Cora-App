import { ApiProperty } from '@nestjs/swagger';
import { FeaturedPostKind, FeaturedPostSource } from '@prisma/client';

// 가져와서 서버에 복사해 둔 게시물. 아직 대표 게시물이 아니라서 id와 순서가 없다.
// 이 모양 그대로 PUT /creators/me/featured-posts의 새 게시물 항목으로 보내면 저장된다.
export class FeaturedPostDraftModel {
  @ApiProperty({ enum: FeaturedPostSource, enumName: 'FeaturedPostSource' })
  source!: FeaturedPostSource;

  @ApiProperty({ enum: FeaturedPostKind, enumName: 'FeaturedPostKind' })
  kind!: FeaturedPostKind;

  @ApiProperty({ description: '서버에 복사한 사진이나 영상 파일의 경로.' })
  mediaPath!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '영상의 첫 화면 그림 경로. 사진은 null.',
  })
  thumbnailPath!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    maxLength: 40,
    description: '인스타그램 글의 첫 줄(40자까지).',
  })
  caption!: string | null;

  @ApiProperty({ description: '원본 인스타그램 게시물 ID.' })
  instagramMediaId!: string;

  @ApiProperty({ description: '카드에 보이는 그림의 주소(미리보기).' })
  photoUrl!: string;
}
