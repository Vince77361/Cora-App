import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import {
  CampaignRecommendationsModel,
  CreatorRecommendationsModel,
  PreviewCardsModel,
  StoreCreatorRecommendationsModel,
} from './dto/recommendations.model';
import { RecommendationsService } from './recommendations.service';

@ApiBearerAuth()
@Controller('recommendations')
export class RecommendationsController {
  constructor(private readonly recommendations: RecommendationsService) {}

  @Get('creators')
  @ApiOperation({
    operationId: 'listCreatorRecommendations',
    summary: '브랜드의 오늘 크리에이터 추천(진행 중인 캠페인 필요)',
  })
  @ApiOkResponse({ type: CreatorRecommendationsModel })
  listCreators(
    @CurrentUser() user: AuthUser,
  ): Promise<CreatorRecommendationsModel> {
    return this.recommendations.listCreators(user.userId);
  }

  @Get('store-creators')
  @ApiOperation({
    operationId: 'listStoreCreatorRecommendations',
    summary:
      '사장님의 오늘 전체 둘러보기 크리에이터 카드(하루 최대 10장, 한국 시간 자정에 새로 채움)',
  })
  @ApiOkResponse({ type: StoreCreatorRecommendationsModel })
  listStoreCreators(
    @CurrentUser() user: AuthUser,
  ): Promise<StoreCreatorRecommendationsModel> {
    return this.recommendations.listStoreCreators(user.userId);
  }

  @Get('campaigns')
  @ApiOperation({
    operationId: 'listCampaignRecommendations',
    summary: '크리에이터의 오늘 캠페인·가게 추천',
  })
  @ApiOkResponse({ type: CampaignRecommendationsModel })
  listCampaigns(
    @CurrentUser() user: AuthUser,
  ): Promise<CampaignRecommendationsModel> {
    return this.recommendations.listCampaigns(user.userId);
  }

  @Get('preview')
  @ApiOperation({
    operationId: 'listPreviewCards',
    summary: '역할이 없는 사용자의 둘러보기 카드(읽기 전용)',
  })
  @ApiOkResponse({ type: PreviewCardsModel })
  listPreview(@CurrentUser() user: AuthUser): Promise<PreviewCardsModel> {
    return this.recommendations.listPreview(user.userId);
  }
}
