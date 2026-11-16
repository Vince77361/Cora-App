import { Body, Controller, Get, HttpCode, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { PrinciplesModel } from './dto/principles.model';
import { UpsertPrinciplesDto } from './dto/upsert-principles.dto';
import { PrinciplesService } from './principles.service';

@ApiBearerAuth()
@Controller('creators/me/principles')
export class PrinciplesController {
  constructor(private readonly principles: PrinciplesService) {}

  @Get()
  @ApiOperation({ operationId: 'getMyPrinciples' })
  @ApiOkResponse({ type: PrinciplesModel })
  getMine(@CurrentUser() user: AuthUser): Promise<PrinciplesModel> {
    return this.principles.getMine(user.userId);
  }

  @Put()
  @HttpCode(200)
  @ApiOperation({ operationId: 'upsertMyPrinciples' })
  @ApiOkResponse({ type: PrinciplesModel })
  upsertMine(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpsertPrinciplesDto,
  ): Promise<PrinciplesModel> {
    return this.principles.upsertMine(user.userId, dto);
  }
}
