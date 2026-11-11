import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class CompleteInstagramConnectDto {
  @ApiProperty({
    description:
      '인스타그램 승인 뒤 받은 코드. 개발용 가짜 연동에서는 연결할 계정 아이디를 입력한다.',
    minLength: 1,
    maxLength: 512,
  })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(512)
  code!: string;
}
