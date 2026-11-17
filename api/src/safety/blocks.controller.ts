import { Controller, HttpCode, Param, Post } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ConversationDetailModel } from '../conversations/dto/conversation.model';
import { SafetyService } from './safety.service';

@ApiBearerAuth()
@Controller('conversations')
export class BlocksController {
  constructor(private readonly safety: SafetyService) {}

  @Post(':id/block')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'blockConversationMember',
    summary:
      '이 방의 상대를 차단한다. 두 사람 사이의 모든 방이 닫히고 계약 전 협업이 끝난다. 상대에게는 알리지 않는다.',
  })
  @ApiOkResponse({ type: ConversationDetailModel })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  @ApiConflictResponse({
    description: '두 사람 사이에 돈이 보관 중인 협업이 있다.',
  })
  block(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ConversationDetailModel> {
    return this.safety.block(user.userId, id);
  }
}
