import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class MarkReadDto {
  @ApiProperty({
    type: 'integer',
    minimum: 0,
    description: '여기까지 읽었다는 번호. 방의 마지막 번호를 넘을 수 없다.',
  })
  @IsInt()
  @Min(0)
  seq!: number;
}
