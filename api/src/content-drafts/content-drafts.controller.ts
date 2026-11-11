import {
  Controller,
  Get,
  HttpCode,
  Param,
  ParseEnumPipe,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
} from '@nestjs/swagger';
import { ContentDraftKind } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { AppError } from '../common/errors/app-error';
import { ContentDraftsService } from './content-drafts.service';
import { ContentDraftModel } from './dto/content-draft.model';

@ApiBearerAuth()
@Controller('stores/me/content-drafts')
export class ContentDraftsController {
  constructor(private readonly drafts: ContentDraftsService) {}

  @Get()
  @ApiOperation({ operationId: 'listMyContentDrafts' })
  @ApiOkResponse({ type: [ContentDraftModel] })
  list(@CurrentUser() user: AuthUser): Promise<ContentDraftModel[]> {
    return this.drafts.list(user.userId);
  }

  @Post(':kind/regenerate')
  @HttpCode(200)
  @ApiOperation({ operationId: 'regenerateMyContentDraft' })
  @ApiParam({
    name: 'kind',
    enum: ContentDraftKind,
    enumName: 'ContentDraftKind',
  })
  @ApiOkResponse({ type: ContentDraftModel })
  regenerate(
    @CurrentUser() user: AuthUser,
    @Param(
      'kind',
      new ParseEnumPipe(ContentDraftKind, {
        exceptionFactory: () =>
          new AppError('VALIDATION_FAILED', '초안 종류가 올바르지 않아요.'),
      }),
    )
    kind: ContentDraftKind,
  ): Promise<ContentDraftModel> {
    return this.drafts.regenerate(user.userId, kind);
  }
}
