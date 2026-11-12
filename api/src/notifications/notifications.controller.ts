import { Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import {
  NotificationPageModel,
  UnreadCountModel,
} from './dto/notification.model';
import { NotificationInboxService } from './notification-inbox.service';

// 알림함(E3). 본인의 알림만 다루고, 지금 역할의 것만 보인다.
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly inbox: NotificationInboxService) {}

  @Get()
  @ApiOperation({ operationId: 'listNotifications' })
  @ApiOkResponse({ type: NotificationPageModel })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: ListNotificationsQueryDto,
  ): Promise<NotificationPageModel> {
    return this.inbox.list(user.userId, query.tab, query.cursor);
  }

  @Get('unread-count')
  @ApiOperation({ operationId: 'countUnreadNotifications' })
  @ApiOkResponse({ type: UnreadCountModel })
  async unreadCount(@CurrentUser() user: AuthUser): Promise<UnreadCountModel> {
    return { count: await this.inbox.unreadCount(user.userId) };
  }

  // "read-all"은 ":id/read"보다 한 칸 짧아 서로 읽히지 않는다.
  @Post('read-all')
  @HttpCode(204)
  @ApiOperation({ operationId: 'readAllNotifications' })
  @ApiNoContentResponse()
  readAll(@CurrentUser() user: AuthUser): Promise<void> {
    return this.inbox.markAllRead(user.userId);
  }

  @Post(':id/read')
  @HttpCode(204)
  @ApiOperation({ operationId: 'readNotification' })
  @ApiNoContentResponse()
  read(@CurrentUser() user: AuthUser, @Param('id') id: string): Promise<void> {
    return this.inbox.markRead(user.userId, id);
  }
}
