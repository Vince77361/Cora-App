import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ProposalInboxRowModel } from './dto/proposal-inbox-row.model';
import { ProposalInboxService } from './proposal-inbox.service';

// 제안함(F3)의 브랜드 계약 줄. 가게 오퍼 줄은 GET /offers/proposals가 주고, 앱이 두 목록을 한 목록으로 합친다.
@ApiBearerAuth()
@Controller('terms')
export class ProposalInboxController {
  constructor(private readonly inbox: ProposalInboxService) {}

  @Get('proposal-inbox')
  @ApiOperation({
    operationId: 'listTermsProposalInbox',
    summary:
      '제안함의 브랜드 계약 줄(브랜드와 크리에이터 모두). 내가 당사자인 협업만, 내가 응답할 차례 → 상대 대기 → 끝남 순이고 같은 묶음에서는 최근 순이다. 계약 이후와 요청 거절·차단으로 끝난 협업은 없다.',
  })
  @ApiOkResponse({ type: [ProposalInboxRowModel] })
  list(@CurrentUser() user: AuthUser): Promise<ProposalInboxRowModel[]> {
    return this.inbox.list(user.userId);
  }
}
