import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class ImportInstagramPostsDto {
  @ApiProperty({
    type: [String],
    minItems: 1,
    maxItems: 4,
    description: '가져올 인스타그램 게시물 ID. 같은 ID를 두 번 보낼 수 없다.',
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(4)
  @ArrayUnique()
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(128, { each: true })
  postIds!: string[];
}
