import { Body, Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ContractsService } from './contracts.service';
import { CreatorConsentDto } from './dto/consent.dto';
import { ContractModel } from './dto/contract.model';

@ApiBearerAuth()
@Controller('collaborations/:id/contract')
export class ContractsController {
  constructor(private readonly contracts: ContractsService) {}

  @Get()
  @ApiOperation({
    operationId: 'getContract',
    summary:
      '계약 화면(당사자만). 양쪽이 같은 판본을 확인하기 전(NOT_READY)에는 최신 판본과 문구를 미리 보기로 준다. 브랜드에게는 동의하면 결제할 금액(quote)이 함께 간다.',
  })
  @ApiOkResponse({ type: ContractModel })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ContractModel> {
    return this.contracts.get(user.userId, id);
  }

  @Post('creator-consent')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'consentContractAsCreator',
    summary:
      '크리에이터가 계약에 동의한다(브랜드보다 먼저). 협업이 합의(AGREED) 상태이고 termsVersion이 최신일 때만: 최신이 아니면 409 STALE_VERSION(latestVersion), 그 밖의 상태는 409 CONFLICT, 확인한 문구가 서버의 문구와 다르면 400. 같은 판본에 다시 동의하면 바뀌는 것 없이 같은 계약을 돌려준다.',
  })
  @ApiOkResponse({ type: ContractModel })
  consentAsCreator(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: CreatorConsentDto,
  ): Promise<ContractModel> {
    return this.contracts.consentAsCreator(user.userId, id, body);
  }
}
