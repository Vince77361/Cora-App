import {
  Body,
  Controller,
  Delete,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Put,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiExtraModels,
  ApiOperation,
  getSchemaPath,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { DiscoveryService } from './discovery.service';
import {
  DecisionResultModel,
  UndoneDecisionModel,
} from './dto/decision-result.model';
import { PassReasonDto } from './dto/pass-reason.dto';
import { PutDecisionDto } from './dto/put-decision.dto';

@ApiBearerAuth()
@ApiExtraModels(UndoneDecisionModel)
@Controller('discovery')
export class DiscoveryController {
  constructor(private readonly discovery: DiscoveryService) {}

  @Put('decisions')
  @ApiOperation({
    operationId: 'putDecision',
    summary:
      '관심·넘김·보류를 저장한다. 반대쪽도 관심이면 서로 관심(협업과 조건 버전 1)이 만들어진다.',
  })
  @ApiOkResponse({ type: DecisionResultModel })
  putDecision(
    @CurrentUser() user: AuthUser,
    @Body() body: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    return this.discovery.decide(user.userId, body);
  }

  @Put('decisions/pass-reason')
  @HttpCode(204)
  @ApiOperation({
    operationId: 'putPassReason',
    summary:
      '넘긴 카드에 이유를 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.',
  })
  @ApiNoContentResponse()
  async putPassReason(
    @CurrentUser() user: AuthUser,
    @Body() body: PassReasonDto,
  ): Promise<void> {
    await this.discovery.setPassReason(user.userId, body);
  }

  @Delete('decisions/last')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'undoLastDecision',
    summary:
      '오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다.',
  })
  @ApiOkResponse({
    schema: {
      nullable: true,
      allOf: [{ $ref: getSchemaPath(UndoneDecisionModel) }],
    },
    description: '지운 결정의 대상. 되돌릴 것이 없으면 본문이 없다(null).',
  })
  undoLastDecision(
    @CurrentUser() user: AuthUser,
  ): Promise<UndoneDecisionModel | null> {
    return this.discovery.undoLast(user.userId);
  }

  @Put('store-passes/:storeId')
  @HttpCode(204)
  @ApiOperation({
    operationId: 'putStorePass',
    summary: '가게 카드를 넘긴다(가게 카드의 관심은 지원 API로 보낸다).',
  })
  @ApiNoContentResponse()
  async putStorePass(
    @CurrentUser() user: AuthUser,
    @Param('storeId', ParseUUIDPipe) storeId: string,
  ): Promise<void> {
    await this.discovery.passStore(user.userId, storeId);
  }
}
