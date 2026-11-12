import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { NotificationSettingsModel } from './dto/notification-settings.model';
import { UpdateNotificationSettingsDto } from './dto/update-notification-settings.dto';
import { NotificationSettingsService } from './notification-settings.service';

// 알림 설정(E5). 사람 하나에 하나라 경로가 /me 아래다.
@ApiBearerAuth()
@Controller('me/notification-settings')
export class NotificationSettingsController {
  constructor(private readonly settings: NotificationSettingsService) {}

  @Get()
  @ApiOperation({ operationId: 'getNotificationSettings' })
  @ApiOkResponse({ type: NotificationSettingsModel })
  get(@CurrentUser() user: AuthUser): Promise<NotificationSettingsModel> {
    return this.settings.get(user.userId);
  }

  @Put()
  @ApiOperation({ operationId: 'putNotificationSettings' })
  @ApiOkResponse({ type: NotificationSettingsModel })
  put(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateNotificationSettingsDto,
  ): Promise<NotificationSettingsModel> {
    return this.settings.put(user.userId, dto);
  }
}
