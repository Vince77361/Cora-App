import { Body, Controller, Get, HttpCode, Post, Put } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CreatorsService } from './creators.service';
import { FeaturedPostModel } from './dto/featured-post.model';
import { ReplaceFeaturedPostsDto } from './dto/replace-featured-posts.dto';
import { FeaturedPostsService } from './featured-posts.service';
import { CreateCreatorSeriesDto } from './dto/create-creator-series.dto';
import { CreatorSeriesModel } from './dto/creator-series.model';
import { CreatorProfileModel } from './dto/creator-profile.model';
import { UpsertCreatorProfileDto } from './dto/upsert-creator-profile.dto';

@ApiBearerAuth()
@Controller('creators')
export class CreatorsController {
  constructor(
    private readonly creators: CreatorsService,
    private readonly featuredPosts: FeaturedPostsService,
  ) {}

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

  @Get('me/series')
  @ApiOperation({ operationId: 'listMyCreatorSeries' })
  @ApiOkResponse({ type: [CreatorSeriesModel] })
  listSeries(@CurrentUser() user: AuthUser): Promise<CreatorSeriesModel[]> {
    return this.creators.listMySeries(user.userId);
  }

  @Post('me/series')
  @ApiOperation({ operationId: 'createMyCreatorSeries' })
  @ApiCreatedResponse({ type: CreatorSeriesModel })
  createSeries(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateCreatorSeriesDto,
  ): Promise<CreatorSeriesModel> {
    return this.creators.createMySeries(user.userId, dto);
  }

  @Get('me/featured-posts')
  @ApiOperation({ operationId: 'getMyFeaturedPosts' })
  @ApiOkResponse({ type: [FeaturedPostModel] })
  getFeaturedPosts(
    @CurrentUser() user: AuthUser,
  ): Promise<FeaturedPostModel[]> {
    return this.featuredPosts.listMine(user.userId);
  }

  // 전체 교체다. 목록의 차례가 순서이고 한 트랜잭션으로 바뀐다(부분 저장 없음).
  @Put('me/featured-posts')
  @HttpCode(200)
  @ApiOperation({ operationId: 'replaceMyFeaturedPosts' })
  @ApiOkResponse({ type: [FeaturedPostModel] })
  replaceFeaturedPosts(
    @CurrentUser() user: AuthUser,
    @Body() dto: ReplaceFeaturedPostsDto,
  ): Promise<FeaturedPostModel[]> {
    return this.featuredPosts.replaceMine(user.userId, dto.items);
  }
}
