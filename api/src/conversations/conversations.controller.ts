import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ConversationsService } from './conversations.service';
import {
  ConversationDetailModel,
  ConversationSummaryModel,
} from './dto/conversation.model';
import { ListMessagesQuery } from './dto/list-messages.query';
import { MarkReadDto } from './dto/mark-read.dto';
import { MessageModel } from './dto/message.model';
import { SendMessageDto } from './dto/send-message.dto';
import { MutedModel, SetMutedDto } from './dto/set-muted.dto';

// 대화방 목록·방·메시지. 방의 참가자가 아니면 어느 길이든 404다(ID가 있는지도 알려 주지 않는다).
@ApiBearerAuth()
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversations: ConversationsService) {}

  @Get()
  @ApiOperation({
    operationId: 'listConversations',
    summary:
      '내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순. 내가 거절한 요청은 빠진다.',
  })
  @ApiOkResponse({ type: [ConversationSummaryModel] })
  list(@CurrentUser() user: AuthUser): Promise<ConversationSummaryModel[]> {
    return this.conversations.list(user.userId);
  }

  @Get(':id')
  @ApiOperation({
    operationId: 'getConversation',
    summary: '방 머리: 상대, 협업 단계, 조건, 내가 할 수 있는 일.',
  })
  @ApiOkResponse({ type: ConversationDetailModel })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ConversationDetailModel> {
    return this.conversations.get(user.userId, id);
  }

  @Get(':id/messages')
  @ApiOperation({
    operationId: 'listMessages',
    summary:
      '메시지를 번호 오름차순으로. afterSeq(빠진 번호 받기)나 beforeSeq(위로 넘기기)를 주고, 둘 다 없으면 마지막 50개.',
  })
  @ApiOkResponse({ type: [MessageModel] })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  listMessages(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Query() query: ListMessagesQuery,
  ): Promise<MessageModel[]> {
    return this.conversations.listMessages(user.userId, id, query);
  }

  @Post(':id/messages')
  @ApiOperation({
    operationId: 'sendMessage',
    summary:
      '글이나 콘텐츠 카드를 보낸다. 같은 clientId로 다시 보내면 첫 메시지를 돌려준다. 열린 방에만 보낼 수 있다.',
  })
  @ApiCreatedResponse({ type: MessageModel })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  send(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: SendMessageDto,
  ): Promise<MessageModel> {
    return this.conversations.send(user.userId, id, body);
  }

  @Post(':id/read')
  @HttpCode(204)
  @ApiOperation({
    operationId: 'markConversationRead',
    summary: '여기까지 읽었다고 알린다. 읽은 번호는 줄어들지 않는다.',
  })
  @ApiNoContentResponse()
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  async markRead(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: MarkReadDto,
  ): Promise<void> {
    await this.conversations.markRead(user.userId, id, body.seq);
  }

  @Post(':id/request/accept')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'acceptMessageRequest',
    summary:
      '메시지 요청을 수락해 대화를 연다. 받은 사람만. 협업은 INQUIRY에 남고, 요청을 보낸 사람에게 알린다.',
  })
  @ApiOkResponse({ type: ConversationDetailModel })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  acceptRequest(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<ConversationDetailModel> {
    return this.conversations.acceptRequest(user.userId, id);
  }

  @Post(':id/request/decline')
  @HttpCode(204)
  @ApiOperation({
    operationId: 'declineMessageRequest',
    summary:
      '메시지 요청을 거절한다. 받은 사람만. 협업은 끝나 같은 캠페인으로 다시 요청할 수 없고, 상대에게 알리지 않는다.',
  })
  @ApiNoContentResponse()
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  async declineRequest(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<void> {
    await this.conversations.declineRequest(user.userId, id);
  }

  @Put(':id/mute')
  @ApiOperation({
    operationId: 'setConversationMuted',
    summary: '이 방의 알림을 끄거나 켠다.',
  })
  @ApiOkResponse({ type: MutedModel })
  @ApiNotFoundResponse({ description: '방이 없거나 내가 참가자가 아니다.' })
  setMuted(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() body: SetMutedDto,
  ): Promise<MutedModel> {
    return this.conversations.setMuted(user.userId, id, body.muted);
  }
}
