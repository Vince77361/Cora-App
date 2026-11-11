import { ApiProperty } from '@nestjs/swagger';

// 답을 기다리는 사장님의 취소 요청. 만료됐거나 답한 요청은 내보내지 않는다.
export class CancelRequestModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    description:
      '내가 보낸 요청이면 true(사장님), 받은 요청이면 false(크리에이터).',
  })
  requestedByMe!: boolean;

  @ApiProperty({
    format: 'date-time',
    description: '이 시각까지 답이 없으면 요청이 사라진다(ISO 8601).',
  })
  expiresAt!: string;
}
