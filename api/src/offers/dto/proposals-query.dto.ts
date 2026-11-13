import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export const PROPOSAL_TABS = ['active', 'ended'] as const;
export type ProposalTab = (typeof PROPOSAL_TABS)[number];

export class ProposalsQueryDto {
  @ApiProperty({
    enum: PROPOSAL_TABS,
    enumName: 'ProposalTab',
    description:
      'active: 내가 응답할 차례와 상대를 기다리는 제안. ended: 합의, 종료, 기한이 지난 제안.',
  })
  @IsIn(PROPOSAL_TABS)
  tab!: ProposalTab;
}
