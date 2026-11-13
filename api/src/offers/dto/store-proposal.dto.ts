import { ApiProperty } from '@nestjs/swagger';
import { ProposeVersionDto } from './propose-version.dto';

// 크리에이터가 가게 페이지에서 "내 방식으로 제안"을 보낼 때의 본문. 새 판본의 조건과 같은 모양이다.
export class StoreProposalDto extends ProposeVersionDto {}

export class StoreProposalResultModel {
  @ApiProperty({ format: 'uuid' })
  offerId!: string;

  @ApiProperty({
    type: 'integer',
    description: '방금 낸 판본의 번호. 새 오퍼면 2다(1은 가게의 모집 조건).',
  })
  version!: number;
}
