import { Injectable } from '@nestjs/common';
import { Clock } from '../common/clock';
import { NotificationSettingsModel } from './dto/notification-settings.model';
import { UpdateNotificationSettingsDto } from './dto/update-notification-settings.dto';
import {
  NotificationSettingsRow,
  NotificationsRepository,
} from './notifications.repository';
import { DEFAULT_SETTINGS } from './notifications.service';

// 다섯 스위치 가운데 켜진 수.
export function enabledCount(settings: NotificationSettingsRow): number {
  return [
    settings.mutualInterest,
    settings.offers,
    settings.messages,
    settings.settlement,
    settings.recommendations,
  ].filter(Boolean).length;
}

function toModel(settings: NotificationSettingsRow): NotificationSettingsModel {
  return {
    mutualInterest: settings.mutualInterest,
    offers: settings.offers,
    messages: settings.messages,
    settlement: settings.settlement,
    recommendations: settings.recommendations,
    quietHours: settings.quietHours,
    enabledCount: enabledCount(settings),
  };
}

// E5. 설정은 사람(계정) 하나에 하나이고, 역할과 상관없다. 행이 없으면 처음 값으로 보여 주고 읽기만으로 행을 만들지 않는다.
@Injectable()
export class NotificationSettingsService {
  constructor(
    private readonly notifications: NotificationsRepository,
    private readonly clock: Clock,
  ) {}

  async get(userId: string): Promise<NotificationSettingsModel> {
    return toModel(
      (await this.notifications.findSettings(userId)) ?? DEFAULT_SETTINGS,
    );
  }

  async put(
    userId: string,
    dto: UpdateNotificationSettingsDto,
  ): Promise<NotificationSettingsModel> {
    const before =
      (await this.notifications.findSettings(userId)) ?? DEFAULT_SETTINGS;
    const next: NotificationSettingsRow = {
      mutualInterest: dto.mutualInterest,
      offers: dto.offers,
      messages: dto.messages,
      settlement: dto.settlement,
      recommendations: dto.recommendations,
      quietHours: dto.quietHours,
    };
    // 추천 소식은 광고성 정보라 켠 시각을 수신 동의로 기록한다. 꺼짐 → 켜짐일 때만 새로 찍고,
    // 끌 때는 값을 지우지 않는다: 동의했던 이력을 남기기 위해서다(켜진 채 다시 저장해도 그대로).
    const turnedOn = next.recommendations && !before.recommendations;
    return toModel(
      await this.notifications.upsertSettings(
        userId,
        next,
        turnedOn ? this.clock.now() : null,
      ),
    );
  }
}
