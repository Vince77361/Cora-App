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

  @Post()
  @ApiOperation({
    operationId: 'proposeReward',
    summary:
      '돈과 혜택만 바꿔 새 판본을 낸다(나머지 항목은 직전 판본에서 옮긴다). 낸 쪽은 확인함이고 단계는 협의가 된다. 최신 판본이 아니면 409 STALE_VERSION, 바뀐 것이 없으면 400.',
  })
  @ApiCreatedResponse({ type: TermsVersionModel })
  propose(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: ProposeRewardDto,
  ): Promise<TermsVersionModel> {
    return this.negotiation.proposeReward(user.userId, id, body);
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
