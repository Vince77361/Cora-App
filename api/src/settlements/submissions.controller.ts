import { Body, Controller, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { SubmissionResultModel } from './dto/submission-result.model';
import { SubmitContentDto } from './dto/submit-content.dto';
import { SubmissionsService } from './submissions.service';

@ApiBearerAuth()
@Controller()
export class SubmissionsController {
  constructor(private readonly submissions: SubmissionsService) {}

  @Post('collaborations/:id/submission')
  @HttpCode(200)
  @ApiOperation({ operationId: 'submitContentLink' })
  @ApiOkResponse({ type: SubmissionResultModel })
  submit(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: SubmitContentDto,
  ): Promise<SubmissionResultModel> {
    return this.submissions.submit(user.userId, id, dto.url);
  }
}
