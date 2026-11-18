import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  ParseUUIDPipe,
  Put,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
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
import { InquiryDto } from './dto/inquiry.dto';
import { InquiryResultModel } from './dto/inquiry-result.model';
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
      '하트(LIKE)·넘김(PASS)·저장(HOLD)을 저장한다. 브랜드·크리에이터는 반대쪽도 하트면 서로 관심(협업과 조건 버전 1)이 만들어진다. 사장님은 크리에이터에게만(campaign 없음) 결정하며 협업을 만들지 않는다.',
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
      '하트·저장 목록. 내가 하트를 보냈거나 저장한 것만 나온다(넘긴 것은 어디에도 나오지 않는다).',
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
      '크리에이터가 받은 제안: 글이나 조건 제안이 붙은 브랜드의 하트 가운데 아직 결정하지 않은 것.',
  })
  @ApiOkResponse({ type: [ProposalModel] })
  listReceivedProposals(
    @CurrentUser() user: AuthUser,
  ): Promise<ProposalModel[]> {
    return this.interests.listReceivedProposals(user.userId);
  }

  @Post('received-proposals/:campaignId/inquiry')
  @ApiOperation({
    operationId: 'createInquiry',
    summary:
      '"조건부터 질문하기": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다. 협업(INQUIRY)과 메시지 요청 방과 첫 메시지가 한 번에 만들어진다.',
  })
  @ApiCreatedResponse({ type: InquiryResultModel })
  @ApiNotFoundResponse({
    description:
      '그 캠페인의 브랜드가 나에게 글이나 제안을 붙인 하트를 보내지 않았다.',
  })
  createInquiry(
    @CurrentUser() user: AuthUser,
    @Param('campaignId', ParseUUIDPipe) campaignId: string,
    @Body() body: InquiryDto,
  ): Promise<InquiryResultModel> {
    return this.discovery.inquire(user.userId, campaignId, body);
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
      '오늘(한국 날짜) 내가 가장 나중에 한 결정을 지운다. 오늘 한 결정이 없으면 본문 없이 200이다. 서로 관심이 된 결정(사장님은 하트를 보낸 크리에이터가 그 가게에 지원해 있을 때)은 409다.',
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
    summary: '가게 카드를 넘긴다(가게 카드의 하트는 지원 API로 보낸다).',
  })
  @ApiNoContentResponse()
  async putStorePass(
    @CurrentUser() user: AuthUser,
    @Param('storeId', ParseUUIDPipe) storeId: string,
  ): Promise<void> {
    await this.discovery.passStore(user.userId, storeId);
  }
}
