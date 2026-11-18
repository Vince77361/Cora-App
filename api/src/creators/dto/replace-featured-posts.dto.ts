import { ApiProperty } from '@nestjs/swagger';
import { FeaturedPostKind, FeaturedPostSource } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { MAX_CAPTION, MAX_FEATURED_POSTS } from '../featured-post-rules';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 두 모양 중 하나다. `id`만 있으면 이미 있는 대표 게시물을 그대로 두고(순서만 새 자리),
// `id`가 없으면 새 게시물이라 source·kind·mediaPath가 필요하다. 모양별 필수는 서비스가 다시 확인한다.
export class FeaturedPostInputDto {
  @ApiProperty({
    required: false,
    format: 'uuid',
    description:
      '내 대표 게시물의 ID. 이것만 보내면 기존 게시물을 그대로 두고 이 차례에 놓는다.',
  })
  @IsOptional()
  @IsUUID()
  id?: string;

  @ApiProperty({
    required: false,
    enum: FeaturedPostSource,
    enumName: 'FeaturedPostSource',
  })
  @ValidateIf((o: FeaturedPostInputDto) => !o.id)
  @IsEnum(FeaturedPostSource)
  source?: FeaturedPostSource;

  @ApiProperty({
    required: false,
    enum: FeaturedPostKind,
    enumName: 'FeaturedPostKind',
  })
  @ValidateIf((o: FeaturedPostInputDto) => !o.id)
  @IsEnum(FeaturedPostKind)
  kind?: FeaturedPostKind;

  @ApiProperty({
    required: false,
    description:
      '올린 파일의 경로. 사진첩은 POST /uploads/photos(FEATURED_POST)가 준 경로, 인스타그램은 가져오기가 준 경로.',
  })
  @ValidateIf((o: FeaturedPostInputDto) => !o.id)
  @IsString()
  mediaPath?: string;

  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  thumbnailPath?: string | null;

  @ApiProperty({
    required: false,
    nullable: true,
    maxLength: MAX_CAPTION,
    description: '한 줄 설명. 사진첩 게시물은 필수.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(MAX_CAPTION)
  caption?: string | null;

  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  instagramMediaId?: string | null;
}

// 전체 교체다. 목록의 차례가 곧 순서(1번부터)이고, 빠진 기존 게시물은 대표 게시물에서 빠진다.
export class ReplaceFeaturedPostsDto {
  @ApiProperty({ type: [FeaturedPostInputDto], maxItems: MAX_FEATURED_POSTS })
  @IsArray()
  @ArrayMaxSize(MAX_FEATURED_POSTS)
  @ValidateNested({ each: true })
  @Type(() => FeaturedPostInputDto)
  items!: FeaturedPostInputDto[];
}
