import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsInt, IsString, Max, Min } from 'class-validator';
import {
  MAX_PHOTO_BYTES,
  PHOTO_CONTENT_TYPES,
  PHOTO_PURPOSES,
} from '../photo-rules';
import type { PhotoPurpose } from '../photo-rules';

// 경로는 받지 않는다. 사용자 ID와 파일 이름은 서버가 정한다.
export class CreatePhotoUploadDto {
  @ApiProperty({ enum: PHOTO_PURPOSES })
  @IsIn(PHOTO_PURPOSES)
  purpose!: PhotoPurpose;

  @ApiProperty({ enum: PHOTO_CONTENT_TYPES })
  @IsString()
  @IsIn(PHOTO_CONTENT_TYPES)
  contentType!: string;

  @ApiProperty({ type: 'integer', minimum: 1, maximum: MAX_PHOTO_BYTES })
  @IsInt()
  @Min(1)
  @Max(MAX_PHOTO_BYTES)
  sizeBytes!: number;
}
