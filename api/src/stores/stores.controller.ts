import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { AdvanceOnboardingDto } from './dto/advance-onboarding.dto';
import { AnalyzeLinksDto } from './dto/analyze-links.dto';
import {
  AnalyzeStoreLinksResultModel,
  MyStoreModel,
} from './dto/my-store.model';
import { SetDefaultTermsDto } from './dto/set-default-terms.dto';
import { StoreDetailModel, StoreSummaryModel } from './dto/store-public.model';
import { UpdateStoreDto } from './dto/update-store.dto';
import { StoresService } from './stores.service';

// "me" 경로는 ":id"보다 위에 둬야 "me"가 가게 ID로 읽히지 않는다.
@ApiBearerAuth()
@Controller('stores')
export class StoresController {
  constructor(private readonly stores: StoresService) {}

  @Post('me/analyze')
  @HttpCode(200)
  @ApiOperation({ operationId: 'analyzeMyStoreLinks' })
  @ApiOkResponse({ type: AnalyzeStoreLinksResultModel })
  analyze(
    @CurrentUser() user: AuthUser,
    @Body() dto: AnalyzeLinksDto,
  ): Promise<AnalyzeStoreLinksResultModel> {
    return this.stores.analyze(user.userId, dto.links);
  }

  @Get('me')
  @ApiOperation({ operationId: 'getMyStore' })
  @ApiOkResponse({ type: MyStoreModel })
  getMine(@CurrentUser() user: AuthUser): Promise<MyStoreModel> {
    return this.stores.getMine(user.userId);
  }

  @Patch('me')
  @HttpCode(200)
  @ApiOperation({ operationId: 'updateMyStore' })
  @ApiOkResponse({ type: MyStoreModel })
  update(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateStoreDto,
  ): Promise<MyStoreModel> {
    return this.stores.update(user.userId, dto);
  }

  @Post('me/onboarding-step')
  @HttpCode(200)
  @ApiOperation({ operationId: 'advanceMyStoreOnboarding' })
  @ApiOkResponse({ type: MyStoreModel })
  advanceOnboarding(
    @CurrentUser() user: AuthUser,
    @Body() dto: AdvanceOnboardingDto,
  ): Promise<MyStoreModel> {
    return this.stores.advanceOnboarding(user.userId, dto.step);
  }

  @Put('me/default-terms')
  @HttpCode(200)
  @ApiOperation({ operationId: 'setMyStoreDefaultTerms' })
  @ApiOkResponse({ type: MyStoreModel })
  setDefaultTerms(
    @CurrentUser() user: AuthUser,
    @Body() dto: SetDefaultTermsDto,
  ): Promise<MyStoreModel> {
    return this.stores.setDefaultTerms(user.userId, dto);
  }

  @Post('me/publish')
  @HttpCode(200)
  @ApiOperation({ operationId: 'publishMyStore' })
  @ApiOkResponse({ type: MyStoreModel })
  publish(@CurrentUser() user: AuthUser): Promise<MyStoreModel> {
    return this.stores.publish(user.userId);
  }

  @Get()
  @ApiOperation({ operationId: 'listPublishedStores' })
  @ApiOkResponse({ type: [StoreSummaryModel] })
  list(@CurrentUser() user: AuthUser): Promise<StoreSummaryModel[]> {
    return this.stores.listPublished(user.userId);
  }

  @Get(':id')
  @ApiOperation({ operationId: 'getPublishedStore' })
  @ApiOkResponse({ type: StoreDetailModel })
  getPublished(@Param('id') id: string): Promise<StoreDetailModel> {
    return this.stores.getPublished(id);
  }
}
