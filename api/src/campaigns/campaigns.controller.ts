import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Patch,
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
import { CampaignsService } from './campaigns.service';
import { CampaignModel } from './dto/campaign.model';
import { CreateCampaignDto } from './dto/create-campaign.dto';
import { UpdateCampaignDto } from './dto/update-campaign.dto';

@ApiBearerAuth()
@Controller('campaigns')
export class CampaignsController {
  constructor(private readonly campaigns: CampaignsService) {}

  @Get('mine/active')
  @ApiOperation({ operationId: 'getMyActiveCampaign' })
  @ApiOkResponse({ type: CampaignModel })
  getMyActive(@CurrentUser() user: AuthUser): Promise<CampaignModel> {
    return this.campaigns.getMyActive(user.userId);
  }

  @Post()
  @ApiOperation({ operationId: 'createCampaign' })
  @ApiCreatedResponse({ type: CampaignModel })
  create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateCampaignDto,
  ): Promise<CampaignModel> {
    return this.campaigns.create(user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ operationId: 'updateCampaign' })
  @ApiOkResponse({ type: CampaignModel })
  update(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateCampaignDto,
  ): Promise<CampaignModel> {
    return this.campaigns.update(user.userId, id, dto);
  }

  @Post(':id/close')
  @HttpCode(200)
  @ApiOperation({ operationId: 'closeCampaign' })
  @ApiOkResponse({ type: CampaignModel })
  close(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<CampaignModel> {
    return this.campaigns.close(user.userId, id);
  }
}
