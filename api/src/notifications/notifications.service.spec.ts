import { Logger } from '@nestjs/common';
import { FakeClock } from '../../test/support/fake-clock';
import { FakePushPort } from '../../test/support/fake-push.port';
import { NOTIFICATION_CATALOG } from './notification-catalog';
import {
  NewNotificationRow,
  NotificationSettingsRow,
  NotificationsRepository,
} from './notifications.repository';
import { NotificationsService } from './notifications.service';

const OWNER = '11111111-1111-4111-8111-111111111111';
const CREATOR = '22222222-2222-4222-8222-222222222222';
// 한국 시간 2026-11-11 12:00 수요일 — 방해 금지에 걸리지 않는다.
const NOON = new Date('2026-11-11T03:00:00.000Z');
// 한국 시간 2026-11-11 23:30.
const LATE = new Date('2026-11-11T14:30:00.000Z');

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 유일 제약은 db-spec이 확인한다.
class FakeNotificationsRepository extends NotificationsRepository {
  readonly rows: (NewNotificationRow & { id: string })[] = [];
  readonly settings = new Map<string, NotificationSettingsRow>();
  failCreate = false;
  failSettings = false;

  constructor() {
    super(null as never);
  }

  create(row: NewNotificationRow): Promise<{ id: string } | null> {
    if (this.failCreate) return Promise.reject(new Error('db down'));
    const dup =
      row.dedupeKey !== null &&
      this.rows.some(
        (r) => r.userId === row.userId && r.dedupeKey === row.dedupeKey,
      );
    if (dup) return Promise.resolve(null);
    const id = `n-${this.rows.length + 1}`;
    this.rows.push({ ...row, id });
    return Promise.resolve({ id });
  }

  findSettings(userId: string): Promise<NotificationSettingsRow | null> {
    if (this.failSettings) return Promise.reject(new Error('db down'));
    return Promise.resolve(this.settings.get(userId) ?? null);
  }
}

const ALL_OFF: NotificationSettingsRow = {
  mutualInterest: false,
  offers: false,
  messages: false,
  settlement: false,
  recommendations: false,
  quietHours: 'OFF',
};

describe('NotificationsService', () => {
  let repo: FakeNotificationsRepository;
  let push: FakePushPort;
  let clock: FakeClock;
  let service: NotificationsService;
  const offerEvent = {
    userId: CREATOR,
    role: 'CREATOR' as const,
    kind: 'OFFER_RECEIVED' as const,
    params: { format: 'REELS', pieceCount: 1 },
    actor: { userId: OWNER, name: '한그릇 라멘', photoPath: 'stores/a.jpg' },
    target: { kind: 'OFFER_INBOX' as const, id: 'offer-1' },
  };

  beforeEach(() => {
    repo = new FakeNotificationsRepository();
    push = new FakePushPort();
    clock = new FakeClock(NOON);
    service = new NotificationsService(repo, push, clock);
  });

  it('records a row and pushes when the switch is on', async () => {
    await service.notify(offerEvent);
    expect(repo.rows).toHaveLength(1);
    expect(repo.rows[0]).toMatchObject({
      userId: CREATOR,
      role: 'CREATOR',
      kind: 'OFFER_RECEIVED',
      tab: 'MATCHING',
      params: { format: 'REELS', pieceCount: 1 },
      actorUserId: OWNER,
      actorName: '한그릇 라멘',
      actorPhotoPath: 'stores/a.jpg',
      targetKind: 'OFFER_INBOX',
      targetId: 'offer-1',
    });
    expect(push.sent).toHaveLength(1);
    expect(push.sent[0]).toMatchObject({
      userId: CREATOR,
      body: '한그릇 라멘이 릴스 1편 오퍼를 보냈어요.',
    });
  });

  it('records a row but does not push when the switch is off', async () => {
    repo.settings.set(CREATOR, { ...ALL_OFF, offers: false });
    await service.notify(offerEvent);
    expect(repo.rows).toHaveLength(1);
    expect(push.sent).toEqual([]);
  });

  it('pushes only when the matching switch is on', async () => {
    repo.settings.set(CREATOR, { ...ALL_OFF, offers: true });
    await service.notify(offerEvent);
    expect(push.sent).toHaveLength(1);
    // 정산 스위치만 켜져 있으면 오퍼 알림은 가지 않는다.
    push.sent.length = 0;
    repo.settings.set(CREATOR, { ...ALL_OFF, settlement: true });
    await service.notify({
      ...offerEvent,
      target: { kind: 'OFFER_INBOX', id: 'o2' },
    });
    expect(push.sent).toEqual([]);
  });

  it('pushes an essential notice even when every switch is off', async () => {
    repo.settings.set(OWNER, ALL_OFF);
    await service.notify({
      userId: OWNER,
      role: 'STORE',
      kind: 'CONTENT_SUBMITTED',
      actor: { userId: CREATOR, name: '하루 한 컵', photoPath: null },
      target: { kind: 'COLLABORATION', id: 'c-1' },
    });
    expect(push.sent).toHaveLength(1);
    expect(push.sent[0].body).toBe('하루 한 컵님이 콘텐츠를 올렸어요.');
  });

  it('records but does not push during quiet hours, essential included', async () => {
    clock.set(LATE);
    await service.notify(offerEvent);
    await service.notify({
      userId: OWNER,
      role: 'STORE',
      kind: 'CONTENT_SUBMITTED',
      actor: { userId: CREATOR, name: '하루 한 컵', photoPath: null },
      target: { kind: 'COLLABORATION', id: 'c-1' },
    });
    expect(repo.rows).toHaveLength(2);
    expect(push.sent).toEqual([]);
  });

  it('pushes at night when quiet hours are off', async () => {
    clock.set(LATE);
    repo.settings.set(CREATOR, { ...ALL_OFF, offers: true, quietHours: 'OFF' });
    await service.notify(offerEvent);
    expect(push.sent).toHaveLength(1);
  });

  it('uses the defaults when the person has no settings row', async () => {
    // 기본값: 방해 금지 NIGHT, 추천 소식 꺼짐, 나머지 켜짐.
    await service.notify(offerEvent);
    expect(push.sent).toHaveLength(1);
    push.sent.length = 0;
    clock.set(LATE);
    await service.notify({
      ...offerEvent,
      target: { kind: 'OFFER_INBOX', id: 'o2' },
    });
    expect(push.sent).toEqual([]);
  });

  it('does nothing for a repeated dedupe key', async () => {
    const event = { ...offerEvent, dedupeKey: 'offer-received:offer-1' };
    await service.notify(event);
    await service.notify(event);
    expect(repo.rows).toHaveLength(1);
    expect(push.sent).toHaveLength(1);
  });

  it('treats the same dedupe key for different people as different', async () => {
    await service.notify({ ...offerEvent, dedupeKey: 'k' });
    await service.notify({ ...offerEvent, userId: OWNER, dedupeKey: 'k' });
    expect(repo.rows).toHaveLength(2);
  });

  it('passes the notification id, target and role in the push data', async () => {
    await service.notify(offerEvent);
    expect(push.sent[0].data).toEqual({
      notificationId: 'n-1',
      targetKind: 'OFFER_INBOX',
      targetId: 'offer-1',
      role: 'CREATOR',
    });
  });

  it('does not push when the room is muted', async () => {
    await service.notify({ ...offerEvent, roomMuted: true });
    expect(repo.rows).toHaveLength(1);
    expect(push.sent).toEqual([]);
  });

  it('keeps a push failure from failing the notify and logs no personal data', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    push.fail = true;
    await expect(service.notify(offerEvent)).resolves.toBeUndefined();
    expect(repo.rows).toHaveLength(1);
    expect(warn).toHaveBeenCalledTimes(1);
    const logged = JSON.stringify(warn.mock.calls);
    expect(logged).not.toContain('push down');
    expect(logged).not.toContain('한그릇');
    warn.mockRestore();
  });

  it('keeps a settings read failure from failing the notify', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repo.failSettings = true;
    await expect(service.notify(offerEvent)).resolves.toBeUndefined();
    expect(repo.rows).toHaveLength(1);
    expect(push.sent).toEqual([]);
    warn.mockRestore();
  });

  it('lets a failure to record the row reach the caller', async () => {
    repo.failCreate = true;
    await expect(service.notify(offerEvent)).rejects.toThrow('db down');
    expect(push.sent).toEqual([]);
  });

  it('pushes without a row for a kind that stays out of the inbox', async () => {
    // tab이 null인 종류(5번 계획의 대화 메시지)는 이 계획에 없어, 카탈로그를 잠시 바꿔 확인한다.
    const original = NOTIFICATION_CATALOG.OFFER_RECEIVED;
    NOTIFICATION_CATALOG.OFFER_RECEIVED = { ...original, tab: null };
    try {
      await service.notify(offerEvent);
    } finally {
      NOTIFICATION_CATALOG.OFFER_RECEIVED = original;
    }
    expect(repo.rows).toEqual([]);
    expect(push.sent).toHaveLength(1);
    expect(push.sent[0].data).toMatchObject({ notificationId: null });
  });
  it('stamps the row with the clock time', async () => {
    clock.set(new Date('2026-11-20T01:23:45.678Z'));
    await service.notify(offerEvent);
    expect(repo.rows[0].createdAt).toEqual(
      new Date('2026-11-20T01:23:45.678Z'),
    );
  });

  describe('required inputs', () => {
    it('rejects a missing amount before writing a row or pushing', async () => {
      await expect(
        service.notify({
          userId: CREATOR,
          role: 'CREATOR',
          kind: 'SETTLEMENT_CONFIRMED',
          target: { kind: 'WALLET', id: null },
        }),
      ).rejects.toThrow('SETTLEMENT_CONFIRMED');
      expect(repo.rows).toEqual([]);
      expect(push.sent).toEqual([]);
    });

    it('rejects a missing day count', async () => {
      await expect(
        service.notify({
          userId: CREATOR,
          role: 'CREATOR',
          kind: 'SUBMIT_REMINDER',
          target: { kind: 'COLLABORATION', id: 'c-1' },
        }),
      ).rejects.toThrow('days');
      expect(repo.rows).toEqual([]);
    });

    it('rejects an offer without a format or piece count', async () => {
      await expect(
        service.notify({ ...offerEvent, params: {} }),
      ).rejects.toThrow('format, pieceCount');
      expect(repo.rows).toEqual([]);
    });

    it('rejects a kind that needs an actor name when there is none', async () => {
      await expect(
        service.notify({
          userId: OWNER,
          role: 'STORE',
          kind: 'CONTENT_SUBMITTED',
          target: { kind: 'COLLABORATION', id: 'c-1' },
        }),
      ).rejects.toThrow('actor');
      expect(repo.rows).toEqual([]);
    });

    it('names the missing keys but never the values or the actor name', async () => {
      const error = await service
        .notify({
          ...offerEvent,
          params: { format: 'REELS' },
          dedupeKey: 'k',
        })
        .catch((e: unknown) => e);
      expect(error).toBeInstanceOf(Error);
      const { name, message } = error as Error;
      expect(name).toBe('InvalidNotificationInput');
      expect(message).toContain('pieceCount');
      expect(message).not.toContain('한그릇');
    });

    it('accepts an amount of zero where zero is a real value', async () => {
      await service.notify({
        userId: OWNER,
        role: 'STORE',
        kind: 'CREATOR_CANCELLED',
        params: { amount: 0 },
        actor: { userId: CREATOR, name: '하루 한 컵', photoPath: null },
        target: { kind: 'COLLABORATION', id: 'c-1' },
      });
      expect(repo.rows).toHaveLength(1);
      expect(push.sent[0].body).toBe('하루 한 컵님이 협업을 그만뒀어요.');
    });
  });
});
