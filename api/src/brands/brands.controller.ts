import { Body, Controller, Get, HttpCode, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { BrandsService } from './brands.service';
import { BrandProfileModel } from './dto/brand-profile.model';
import { UpsertBrandProfileDto } from './dto/upsert-brand-profile.dto';

@ApiBearerAuth()
@Controller('brands')
export class BrandsController {
  constructor(private readonly brands: BrandsService) {}

  @Get('me')
  @ApiOperation({ operationId: 'getMyBrand' })
  @ApiOkResponse({ type: BrandProfileModel })
  getMine(@CurrentUser() user: AuthUser): Promise<BrandProfileModel> {
    return this.brands.getMine(user.userId);
  }

  @Put('me')
  @HttpCode(200)
  @ApiOperation({ operationId: 'upsertMyBrand' })
  @ApiOkResponse({ type: BrandProfileModel })
  upsertMine(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpsertBrandProfileDto,
  ): Promise<BrandProfileModel> {
    return this.brands.upsertMine(user.userId, dto);
  }
}
