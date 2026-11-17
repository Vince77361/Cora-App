import { Body, Controller, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ConversationsService } from '../conversations/conversations.service';
import { SubmissionsService } from '../settlements/submissions.service';
import { CollaborationsService } from './collaborations.service';
import { CollaborationModel } from './dto/collaboration.model';
import { SubmitContentDto } from './dto/submit-content.dto';

// 링크 제출은 정산 모듈이 처리하고, 응답의 협업 모델은 이 모듈이 만든다(원장 판단 R8, R10).
// 정산 모듈은 대화 모듈을 모른다(대화 모듈이 협업·계약을 거쳐 정산 모듈을 쓴다). 그래서 브랜드 계약의 방 갱신(conversation.updated)은
// 정산 모듈이 아니라 두 모듈을 모두 아는 이 컨트롤러가 제출이 저장된 뒤에 한다.
@ApiBearerAuth()
@Controller()
export class SubmissionsController {
  constructor(
    private readonly submissions: SubmissionsService,
    private readonly collaborations: CollaborationsService,
    private readonly conversations: ConversationsService,
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
    const model = await this.collaborations.get(user.userId, id);
    // 브랜드 계약은 방 머리의 단계가 PUBLISHED로 바뀐다. 전달이 실패해도 제출은 이미 저장됐다(publishUpdated가 던지지 않는다).
    if (model.kind === 'BRAND_CONTRACT') {
      const roomId = await this.conversations.idForCollaboration(id);
      if (roomId) await this.conversations.publishUpdated(roomId, 'STATUS');
    }
    return model;
  }
}
