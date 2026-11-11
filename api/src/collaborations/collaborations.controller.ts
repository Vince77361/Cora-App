import { Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { CollaborationsService } from './collaborations.service';
import { CollaborationQueryDto } from './dto/collaboration-query.dto';
import { CollaborationModel } from './dto/collaboration.model';

@ApiBearerAuth()
@Controller('collaborations')
export class CollaborationsController {
  constructor(private readonly collaborations: CollaborationsService) {}

  @Get()
  @ApiOperation({ operationId: 'listCollaborations' })
  @ApiOkResponse({ type: [CollaborationModel] })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: CollaborationQueryDto,
  ): Promise<CollaborationModel[]> {
    return this.collaborations.list(user.userId, query.scope);
  }

  @Get(':id')
  @ApiOperation({ operationId: 'getCollaboration' })
  @ApiOkResponse({ type: CollaborationModel })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<CollaborationModel> {
    return this.collaborations.get(user.userId, id);
  }

  @Post(':id/cancel')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'cancelCollaboration',
    summary:
      '크리에이터가 링크를 제출하기 전에 협업을 그만둔다(수수료까지 전액 환급).',
  })
  @ApiOkResponse({ type: CollaborationModel })
  cancel(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<CollaborationModel> {
    return this.collaborations.cancel(user.userId, id);
  }

  @Post(':id/cancel-requests')
  @ApiOperation({
    operationId: 'requestCollaborationCancel',
    summary: '사장님이 취소를 요청한다. 3일 안에 답이 없으면 사라진다.',
  })
  @ApiCreatedResponse({ type: CollaborationModel })
  requestCancel(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<CollaborationModel> {
    return this.collaborations.requestCancel(user.userId, id);
  }

  @Post(':id/cancel-requests/:requestId/accept')
  @HttpCode(200)
  @ApiOperation({
    operationId: 'acceptCollaborationCancel',
    summary:
      '크리에이터가 사장님의 취소 요청에 동의한다(직접 그만두는 것과 같은 처리).',
  })
  @ApiOkResponse({ type: CollaborationModel })
  acceptCancel(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Param('requestId') requestId: string,
  ): Promise<CollaborationModel> {
    return this.collaborations.acceptCancel(user.userId, id, requestId);
  }
}
