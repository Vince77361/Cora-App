import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CardDetailsService } from './card-details.service';
import {
  CampaignDetailModel,
  CreatorCardDetailModel,
} from './dto/card-details.model';

@ApiBearerAuth()
@Controller()
export class CardDetailsController {
  constructor(private readonly details: CardDetailsService) {}

  @Get('campaigns/:id/detail')
  @ApiOperation({
    operationId: 'getCampaignDetail',
    summary:
      '캠페인 상세(크리에이터). 보이지 않거나 내가 넘긴 캠페인은 404, 예산은 담지 않는다.',
  })
  @ApiOkResponse({ type: CampaignDetailModel })
  getCampaignDetail(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<CampaignDetailModel> {
    return this.details.getCampaignDetail(user.userId, id);
  }

  @Get('creators/:id/card')
  @ApiOperation({
    operationId: 'getCreatorCard',
    summary:
      '크리에이터 카드 상세(브랜드). 보이지 않거나 내가 넘긴 크리에이터는 404.',
  })
  @ApiOkResponse({ type: CreatorCardDetailModel })
  getCreatorCard(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<CreatorCardDetailModel> {
    return this.details.getCreatorCard(user.userId, id);
  }
}
