import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Put,
  Query,
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
import { CompareService } from './compare.service';
import { InterestsService } from './interests.service';
import {
  DecisionResultModel,
  UndoneDecisionModel,
} from './dto/decision-result.model';
import { CompareModel, CompareQuery } from './dto/compare.model';
import {
  InterestCardModel,
  ListInterestsQuery,
  ProposalModel,
} from './dto/interest-card.model';
import { PassReasonDto } from './dto/pass-reason.dto';
import { PutDecisionDto } from './dto/put-decision.dto';

@ApiBearerAuth()
@ApiExtraModels(UndoneDecisionModel)
@Controller('discovery')
export class DiscoveryController {
  constructor(
    private readonly discovery: DiscoveryService,
    private readonly interests: InterestsService,
    private readonly compareService: CompareService,
  ) {}

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

  @Get('interests')
  @ApiOperation({
    operationId: 'listInterests',
    summary:
      '관심·보류 목록. 내가 관심을 보냈거나 보류한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).',
  })
  @ApiOkResponse({ type: [InterestCardModel] })
  listInterests(
    @CurrentUser() user: AuthUser,
    @Query() query: ListInterestsQuery,
  ): Promise<InterestCardModel[]> {
    return this.interests.list(user.userId, query.tab ?? 'saved');
  }

  @Get('received-proposals')
  @ApiOperation({
    operationId: 'listReceivedProposals',
    summary:
      '크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 관심 가운데 아직 결정하지 않은 것.',
  })
  @ApiOkResponse({ type: [ProposalModel] })
  listReceivedProposals(
    @CurrentUser() user: AuthUser,
  ): Promise<ProposalModel[]> {
    return this.interests.listReceivedProposals(user.userId);
  }

  @Get('compare')
  @ApiOperation({
    operationId: 'compareCandidates',
    summary:
      '후보 비교(브랜드). 이 캠페인에서 내가 저장한 두 크리에이터를 같은 결과물 기준으로 견주고 다른 줄을 알려 준다. 팔로워 수는 없다.',
  })
  @ApiOkResponse({ type: CompareModel })
  compare(
    @CurrentUser() user: AuthUser,
    @Query() query: CompareQuery,
  ): Promise<CompareModel> {
    return this.compareService.compare(user.userId, query.a, query.b);
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
