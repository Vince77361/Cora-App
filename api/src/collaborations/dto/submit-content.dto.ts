import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class SubmitContentDto {
  @ApiProperty({
    description:
      '올린 콘텐츠의 주소. 형식(쇼츠·릴스·카드뉴스·블로그)에 맞는 https 주소만 받는다.',
    maxLength: 2000,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  url!: string;
}
