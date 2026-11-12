import { Injectable } from '@nestjs/common';
import {
  NotificationKind,
  NotificationTab,
  QuietHours,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationParams } from './notification-catalog';
import { NotificationCursor } from './notification-cursor';

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
  createdAt: Date;
}

export interface NotificationSettingsRow {
  mutualInterest: boolean;
  offers: boolean;
  messages: boolean;
  settlement: boolean;
  recommendations: boolean;
  quietHours: QuietHours;
}

// 알림함이 읽는 한 줄. 알림함에 남는 줄은 항상 탭이 있다.
export interface InboxRow {
  id: string;
  kind: NotificationKind;
  tab: NotificationTab;
  params: NotificationParams;
  actorName: string | null;
  actorPhotoPath: string | null;
  targetKind: string;
  targetId: string | null;
  createdAt: Date;
  readAt: Date | null;
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

  // 지금 역할의 줄을 최신순으로, since 이후만. after가 있으면 그 위치(만든 시각, id) 다음부터 limit줄.
  // 정렬 기준이 (만든 시각, id) 둘이라 시각이 같은 줄이 있어도 쪽 사이에 빠지거나 겹치지 않는다.
  async listInbox(input: {
    userId: string;
    role: UserRole;
    tab: NotificationTab | null;
    since: Date;
    after: NotificationCursor | null;
    limit: number;
  }): Promise<InboxRow[]> {
    const rows = await this.prisma.notification.findMany({
      where: {
        userId: input.userId,
        role: input.role,
        deletedAt: null,
        createdAt: { gte: input.since },
        tab: input.tab ?? { not: null },
        ...(input.after
          ? {
              OR: [
                { createdAt: { lt: input.after.createdAt } },
                {
                  createdAt: input.after.createdAt,
                  id: { lt: input.after.id },
                },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: input.limit,
      select: {
        id: true,
        kind: true,
        tab: true,
        params: true,
        actorName: true,
        actorPhotoPath: true,
        targetKind: true,
        targetId: true,
        createdAt: true,
        readAt: true,
      },
    });
    return rows.flatMap((row) =>
      row.tab
        ? [{ ...row, tab: row.tab, params: row.params as NotificationParams }]
        : [],
    );
  }

  countUnread(userId: string, role: UserRole, since: Date): Promise<number> {
    return this.prisma.notification.count({
      where: {
        userId,
        role,
        deletedAt: null,
        readAt: null,
        createdAt: { gte: since },
      },
    });
  }

  // 내 줄이면 true(이미 읽었어도), 아니거나 없으면 false. 갱신 조건에 userId를 넣어 남의 줄은 쓰지 않는다.
  // 이미 읽은 줄은 처음 읽은 시각을 지키려고 readAt이 비었을 때만 쓴다.
  async markRead(id: string, userId: string, now: Date): Promise<boolean> {
    const updated = await this.prisma.notification.updateMany({
      where: { id, userId, deletedAt: null, readAt: null },
      data: { readAt: now },
    });
    if (updated.count > 0) return true;
    return (
      (await this.prisma.notification.count({
        where: { id, userId, deletedAt: null },
      })) > 0
    );
  }

  // 지금 역할의 읽지 않은 줄 전부(탭과 상관없이, 90일 밖의 줄도).
  async markAllRead(userId: string, role: UserRole, now: Date): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, role, deletedAt: null, readAt: null },
      data: { readAt: now },
    });
  }

  // agreedAt이 있으면 추천 소식 동의 시각을 그 값으로 쓴다. 없으면 기존 값을 그대로 둔다.
  async upsertSettings(
    userId: string,
    values: NotificationSettingsRow,
    agreedAt: Date | null,
  ): Promise<NotificationSettingsRow> {
    return this.prisma.notificationSetting.upsert({
      where: { userId },
      create: { userId, ...values, recommendationsAgreedAt: agreedAt },
      update: {
        ...values,
        ...(agreedAt ? { recommendationsAgreedAt: agreedAt } : {}),
      },
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
