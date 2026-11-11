import { Injectable } from '@nestjs/common';
import {
  NotificationKind,
  NotificationTab,
  QuietHours,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationParams } from './notification-catalog';

export interface NewNotificationRow {
  userId: string;
  role: UserRole;
  kind: NotificationKind;
  tab: NotificationTab;
  params: NotificationParams;
  actorUserId: string | null;
  actorName: string | null;
  actorPhotoPath: string | null;
  targetKind: string;
  targetId: string | null;
  dedupeKey: string | null;
}

export interface NotificationSettingsRow {
  mutualInterest: boolean;
  offers: boolean;
  messages: boolean;
  settlement: boolean;
  recommendations: boolean;
  quietHours: QuietHours;
}

@Injectable()
export class NotificationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // (userId, dedupeKey)가 이미 있으면 null. ON CONFLICT DO NOTHING으로 넣어, 같은 키가 동시에 와도
  // 한 줄만 만들어지고 나머지는 예외 없이 null을 받는다.
  async create(row: NewNotificationRow): Promise<{ id: string } | null> {
    const created = await this.prisma.notification.createManyAndReturn({
      data: [row],
      skipDuplicates: true,
      select: { id: true },
    });
    return created[0] ?? null;
  }

  // 설정 행이 없는 사람은 null이다. 기본값으로 보는 것은 서비스의 몫이다.
  findSettings(userId: string): Promise<NotificationSettingsRow | null> {
    return this.prisma.notificationSetting.findFirst({
      where: { userId, deletedAt: null },
      select: {
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: true,
        quietHours: true,
      },
    });
  }
}
