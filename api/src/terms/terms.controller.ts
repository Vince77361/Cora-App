import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ProposeRewardDto } from './dto/propose-reward.dto';
import { TermsHistoryModel } from './dto/terms-history.model';
import { TermsLatestModel, TermsVersionModel } from './dto/terms-version.model';
import { NegotiationService } from './negotiation.service';

@ApiBearerAuth()
@Controller('collaborations/:id/terms')
export class TermsController {
  constructor(private readonly negotiation: NegotiationService) {}

  @Get()
  @ApiOperation({
    operationId: 'listTermsVersions',
    summary:
      '조건 판본 이력(당사자만). 최신이 먼저이고 판본마다 바뀐 항목을 담는다. agreement는 최신 판본의 확인 상태, editable은 지금 수정 제안을 낼 수 있는가.',
  })
  @ApiOkResponse({ type: TermsHistoryModel })
  list(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<TermsHistoryModel> {
    return this.negotiation.list(user.userId, id);
  }

  @Get('latest')
  @ApiOperation({
    operationId: 'getLatestTerms',
    summary: '브랜드 계약의 가장 최근 조건 판본(당사자만).',
  })
  @ApiOkResponse({ type: TermsLatestModel })
  getLatest(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<TermsLatestModel> {
    return this.negotiation.getLatest(user.userId, id);
  }

  @Post()
  @ApiOperation({
    operationId: 'proposeReward',
    summary:
      '새 판본을 낸다(조건 수정 제안). 빠진 항목은 직전 판본에서 옮기고 성과 추가는 null이면 끈다. 낸 쪽은 확인함이고 단계는 협의가 되며 크리에이터의 계약 동의는 취소된다. 최신 판본이 아니면 409 STALE_VERSION, 브랜드 결제가 진행 중이면 409, 바뀐 것이 없으면 400.',
  })
  @ApiCreatedResponse({ type: TermsVersionModel })
  propose(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: ProposeRewardDto,
  ): Promise<TermsVersionModel> {
    return this.negotiation.proposeTerms(user.userId, id, body);
  }

  @Post(':version/confirm')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'confirmTerms',
    summary:
      '이 판본 수락. 최신이 아니면 409 STALE_VERSION(본문에 latestVersion), 성과 추가가 있는데 인스타그램 연동이 없으면 크리에이터는 409.',
  })
  @ApiOkResponse({ type: TermsVersionModel })
  confirm(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Param('version', ParseIntPipe) version: number,
  ): Promise<TermsVersionModel> {
    return this.negotiation.confirm(user.userId, id, version);
  }
}
