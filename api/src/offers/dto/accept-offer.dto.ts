import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

// 수락은 내가 본 판본 번호와 함께 보낸다. 그사이 새 판본이 나왔으면 서버가 409 STALE_VERSION으로 거절한다.
export class AcceptOfferDto {
  @ApiProperty({
    type: 'integer',
    minimum: 1,
    description: '수락하려는 판본 번호. 최신이 아니면 409 STALE_VERSION.',
  })
  @IsInt()
  @Min(1)
  version!: number;
}
