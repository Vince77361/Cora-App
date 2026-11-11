import { Body, Controller, Get, HttpCode, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CreatorsService } from './creators.service';
import { CreatorProfileModel } from './dto/creator-profile.model';
import { UpsertCreatorProfileDto } from './dto/upsert-creator-profile.dto';

@ApiBearerAuth()
@Controller('creators')
export class CreatorsController {
  constructor(private readonly creators: CreatorsService) {}

  @Get('me')
  @ApiOperation({ operationId: 'getMyCreatorProfile' })
  @ApiOkResponse({ type: CreatorProfileModel })
  getMine(@CurrentUser() user: AuthUser): Promise<CreatorProfileModel> {
    return this.creators.getMine(user.userId);
  }

  @Put('me')
  @HttpCode(200)
  @ApiOperation({ operationId: 'upsertMyCreatorProfile' })
  @ApiOkResponse({ type: CreatorProfileModel })
  upsertMine(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpsertCreatorProfileDto,
  ): Promise<CreatorProfileModel> {
    return this.creators.upsertMine(user.userId, dto);
  }
}
