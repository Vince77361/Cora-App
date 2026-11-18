import { Body, Controller, Delete, Get, HttpCode, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CompleteInstagramConnectDto } from './dto/complete-instagram-connect.dto';
import { FeaturedPostDraftModel } from './dto/featured-post-draft.model';
import { ImportInstagramPostsDto } from './dto/import-instagram-posts.dto';
import {
  InstagramConnectionModel,
  InstagramConnectUrlModel,
} from './dto/instagram-connection.model';
import { InstagramPostModel } from './dto/instagram-post.model';
import { InstagramService } from './instagram.service';

@ApiBearerAuth()
@Controller('instagram')
export class InstagramController {
  constructor(private readonly instagram: InstagramService) {}

  @Post('connect')
  @HttpCode(200)
  @ApiOperation({ operationId: 'beginInstagramConnect' })
  @ApiOkResponse({ type: InstagramConnectUrlModel })
  begin(@CurrentUser() user: AuthUser): Promise<InstagramConnectUrlModel> {
    return this.instagram.begin(user.userId);
  }

  @Post('connect/complete')
  @HttpCode(200)
  @ApiOperation({ operationId: 'completeInstagramConnect' })
  @ApiOkResponse({ type: InstagramConnectionModel })
  complete(
    @CurrentUser() user: AuthUser,
    @Body() dto: CompleteInstagramConnectDto,
  ): Promise<InstagramConnectionModel> {
    return this.instagram.complete(user.userId, dto.code);
  }

  @Get('connection')
  @ApiOperation({ operationId: 'getInstagramConnection' })
  @ApiOkResponse({ type: InstagramConnectionModel })
  get(@CurrentUser() user: AuthUser): Promise<InstagramConnectionModel> {
    return this.instagram.getMine(user.userId);
  }

  @Get('posts')
  @ApiOperation({
    operationId: 'listInstagramPosts',
    summary: '연동한 인스타그램 계정의 게시물 목록(연동이 없으면 404)',
  })
  @ApiOkResponse({ type: [InstagramPostModel] })
  listPosts(@CurrentUser() user: AuthUser): Promise<InstagramPostModel[]> {
    return this.instagram.listPosts(user.userId);
  }

  @Post('posts/import')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'importInstagramPosts',
    summary:
      '고른 게시물의 파일을 서버로 복사하고 대표 게시물 초안을 돌려준다(저장은 PUT /creators/me/featured-posts)',
  })
  @ApiOkResponse({ type: [FeaturedPostDraftModel] })
  importPosts(
    @CurrentUser() user: AuthUser,
    @Body() dto: ImportInstagramPostsDto,
  ): Promise<FeaturedPostDraftModel[]> {
    return this.instagram.importPosts(user.userId, dto.postIds);
  }

  @Delete('connection')
  @HttpCode(204)
  @ApiOperation({ operationId: 'disconnectInstagram' })
  @ApiNoContentResponse()
  disconnect(@CurrentUser() user: AuthUser): Promise<void> {
    return this.instagram.disconnect(user.userId);
  }
}
