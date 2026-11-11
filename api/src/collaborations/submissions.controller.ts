import { Body, Controller, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { SubmissionsService } from '../settlements/submissions.service';
import { CollaborationsService } from './collaborations.service';
import { CollaborationModel } from './dto/collaboration.model';
import { SubmitContentDto } from './dto/submit-content.dto';

// 링크 제출은 정산 모듈이 처리하고, 응답의 협업 모델은 이 모듈이 만든다(원장 판단 R8, R10).
@ApiBearerAuth()
@Controller()
export class SubmissionsController {
  constructor(
    private readonly submissions: SubmissionsService,
    private readonly collaborations: CollaborationsService,
  ) {}

  @Post('collaborations/:id/submission')
  @HttpCode(200)
  @ApiOperation({ operationId: 'submitContentLink' })
  @ApiOkResponse({ type: CollaborationModel })
  async submit(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SubmitContentDto,
  ): Promise<CollaborationModel> {
    await this.submissions.submit(user.userId, id, dto.url);
    return this.collaborations.get(user.userId, id);
  }
}
