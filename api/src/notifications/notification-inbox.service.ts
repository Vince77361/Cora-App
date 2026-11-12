import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { Clock } from '../common/clock';
import { StoragePort } from '../integrations/storage/storage.port';
import { UsersService } from '../users/users.service';
import {
  NotificationPageModel,
  NotificationModel,
} from './dto/notification.model';
import { NotificationTabFilter } from './dto/list-notifications-query.dto';
import { NOTIFICATION_CATALOG } from './notification-catalog';
import { decodeCursor, encodeCursor } from './notification-cursor';
import { InboxRow, NotificationsRepository } from './notifications.repository';

// 알림함에 보이는 기간과 한 번에 주는 줄 수(2026-11-11 소유자 결정).
export const INBOX_DAYS = 90;
export const INBOX_PAGE_SIZE = 30;
const DAY_MS = 24 * 60 * 60 * 1000;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// E3 알림함. 지금 역할(users.role)의 알림만 다룬다: 역할이 여럿인 계정에서 다른 역할 앞의 알림이 섞이지 않게 한다.
@Injectable()
export class NotificationInboxService {
  constructor(
    private readonly notifications: NotificationsRepository,
    private readonly users: UsersService,
    private readonly storage: StoragePort,
    private readonly clock: Clock,
  ) {}

  async list(
    userId: string,
    tab: NotificationTabFilter | undefined,
    cursor: string | undefined,
  ): Promise<NotificationPageModel> {
    const role = await this.users.getRole(userId);
    if (!role) return { items: [], nextCursor: null };
    // 잘못된 cursor는 역할을 읽은 뒤가 아니라 가능한 한 일찍 거절한다.
    const after = cursor ? decodeCursor(cursor) : null;
    const rows = await this.notifications.listInbox({
      userId,
      role,
      tab: !tab || tab === 'ALL' ? null : tab,
      since: this.since(),
      after,
      // 한 줄 더 읽어 다음 쪽이 있는지 안다.
      limit: INBOX_PAGE_SIZE + 1,
    });
    const shown = rows.slice(0, INBOX_PAGE_SIZE);
    const last = shown[shown.length - 1];
    return {
      items: shown.map((row) => this.toModel(row)),
      nextCursor:
        rows.length > INBOX_PAGE_SIZE && last
          ? encodeCursor({ createdAt: last.createdAt, id: last.id })
          : null,
    };
  }

  async unreadCount(userId: string): Promise<number> {
    const role = await this.users.getRole(userId);
    if (!role) return 0;
    return this.notifications.countUnread(userId, role, this.since());
  }

  // 내 알림이 아니거나 없거나 id 모양이 틀리면 모두 404. 어느 경우인지 알려 주지 않는다.
  async markRead(userId: string, id: string): Promise<void> {
    if (
      !UUID.test(id) ||
      !(await this.notifications.markRead(id, userId, this.clock.now()))
    ) {
      throw new AppError('NOT_FOUND', '알림을 찾을 수 없어요.');
    }
  }

  async markAllRead(userId: string): Promise<void> {
    const role: UserRole | null = await this.users.getRole(userId);
    if (!role) return;
    await this.notifications.markAllRead(userId, role, this.clock.now());
  }

  private since(): Date {
    return new Date(this.clock.now().getTime() - INBOX_DAYS * DAY_MS);
  }

  // 문구는 만들 때 저장하지 않았다: 종류·값·상대 사본으로 읽을 때 그린다(푸시와 같은 render).
  private toModel(row: InboxRow): NotificationModel {
    const entry = NOTIFICATION_CATALOG[row.kind];
    return {
      id: row.id,
      tab: row.tab,
      text: entry.render({ actorName: row.actorName, params: row.params }),
      glyph: entry.glyph,
      actor:
        row.actorName === null
          ? null
          : {
              name: row.actorName,
              photoUrl: row.actorPhotoPath
                ? this.storage.publicUrl(row.actorPhotoPath)
                : null,
            },
      target: { kind: row.targetKind, id: row.targetId },
      createdAt: row.createdAt.toISOString(),
      read: row.readAt !== null,
    };
  }
}
