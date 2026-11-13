import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ProposalDetailModel } from './dto/proposal-detail.model';
import { ProposalRowModel } from './dto/proposal-row.model';
import { ProposalsQueryDto } from './dto/proposals-query.dto';
import { ProposalsService } from './proposals.service';

// 라우트 순서가 중요하다: "offers/proposals"가 "offers/:id"보다 먼저 등록돼야 "proposals"가 id로 읽히지 않는다.
// 같은 경로 접두의 offers/sent·offers/received는 OffersController가 먼저 등록돼 있다.
@ApiBearerAuth()
@Controller('offers')
export class ProposalsController {
  constructor(private readonly proposals: ProposalsService) {}

  @Get('proposals')
  @ApiOperation({
    operationId: 'listProposals',
    description:
      '제안함(F3). 사장님은 내 가게의 오퍼, 크리에이터는 내가 받은·보낸 오퍼. 내가 응답할 차례 → 상대 대기 순, 같은 묶음에서는 최근 판본 순.',
  })
  @ApiOkResponse({ type: [ProposalRowModel] })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: ProposalsQueryDto,
  ): Promise<ProposalRowModel[]> {
    return this.proposals.list(user.userId, query.tab);
  }

  @Get(':id')
  @ApiOperation({
    operationId: 'getProposal',
    description: '제안 상세. 당사자만 볼 수 있고 남의 제안은 404다.',
  })
  @ApiOkResponse({ type: ProposalDetailModel })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ProposalDetailModel> {
    return this.proposals.get(user.userId, id);
  }
}
