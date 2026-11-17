import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { INQUIRY_MESSAGE_MAX, NOTE_MAX } from '../discovery-rules';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 10 받은 제안의 "조건부터 질문하기". 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다.
export class InquiryDto {
  @ApiProperty({
    minLength: 1,
    maxLength: INQUIRY_MESSAGE_MAX,
    description:
      '브랜드에게 보내는 첫 메시지(1~1000자). 요청에는 이 한 개만 담긴다.',
  })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(INQUIRY_MESSAGE_MAX)
  message!: string;

  @ApiProperty({
    type: String,
    required: false,
    nullable: true,
    maxLength: NOTE_MAX.CREATOR,
    description:
      '내가 만들고 싶은 콘텐츠 한 줄(40자). 나중에 서로 관심이 닿으면 조건 버전 1의 제목이 된다.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(NOTE_MAX.CREATOR)
  contentLine?: string | null;
}
