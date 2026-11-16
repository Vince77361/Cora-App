import {
  Controller,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { TermsLatestModel, TermsVersionModel } from './dto/terms-version.model';
import { NegotiationService } from './negotiation.service';

@ApiBearerAuth()
@Controller('collaborations/:id/terms')
export class TermsController {
  constructor(private readonly negotiation: NegotiationService) {}

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
