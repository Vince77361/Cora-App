import { randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { Clock } from '../src/common/clock';
import { NotificationsService } from '../src/notifications/notifications.service';
import { createTestApp, httpOf } from './helpers/create-test-app';
import { truncateTestDb } from './helpers/truncate-test-db';
import { FakeClock } from './support/fake-clock';
import { OTHER, USER_A } from './support/fake-token-verifier';

const auth = { Authorization: 'Bearer user-a' };
const authB = { Authorization: 'Bearer user-b' };
const DAY = 24 * 60 * 60 * 1000;
// FakeClock의 처음 시각(한국 시간 2026-11-11 12:00).
const NOW = new Date('2026-11-11T03:00:00.000Z');

interface ItemBody {
  id: string;
  tab: string;
  text: string;
  glyph: string | null;
  actor: { name: string; photoUrl: string | null } | null;
  target: { kind: string; id: string | null };
  createdAt: string;
  read: boolean;
}
interface PageBody {
  items: ItemBody[];
  nextCursor: string | null;
}
interface SettingsBody {
  mutualInterest: boolean;
  offers: boolean;
  messages: boolean;
  settlement: boolean;
  recommendations: boolean;
  quietHours: string;
  enabledCount: number;
}
const codeOf = (res: request.Response) =>
  (res.body as { error: { code: string } }).error.code;

describe('notification inbox and settings', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let server: ReturnType<typeof httpOf>;
  let clock: FakeClock;
  let notifications: NotificationsService;

  const setRole = (
    role: 'STORE' | 'CREATOR' | 'BRAND',
    headers: Record<string, string> = auth,
  ) =>
    request(server).patch('/me/role').set(headers).send({ role }).expect(200);
  const list = (query = '', headers: Record<string, string> = auth) =>
    request(server).get(`/notifications${query}`).set(headers);
  const page = async (query = '') =>
    (await list(query).expect(200)).body as PageBody;
  const unread = async (headers: Record<string, string> = auth) =>
    (
      (
        await request(server)
          .get('/notifications/unread-count')
          .set(headers)
          .expect(200)
      ).body as { count: number }
    ).count;
  const read = (id: string, headers: Record<string, string> = auth) =>
    request(server).post(`/notifications/${id}/read`).set(headers).send();
  const readAll = (headers: Record<string, string> = auth) =>
    request(server).post('/notifications/read-all').set(headers).send();
  const getSettings = (headers: Record<string, string> = auth) =>
    request(server).get('/me/notification-settings').set(headers);
  const putSettings = (body: Record<string, unknown>) =>
    request(server).put('/me/notification-settings').set(auth).send(body);

  // 사건을 보내는 길(notify)로 줄을 만든다. 시각은 시계가 정한다.
  const notifyAs = (
    userId: string,
    role: 'STORE' | 'CREATOR',
    kind:
      | 'OFFER_RECEIVED'
      | 'SETTLEMENT_CONFIRMED'
      | 'PAYMENT_FUNDED'
      | 'SUBMIT_REMINDER',
    extra: { name?: string; photoPath?: string | null } = {},
  ) =>
    notifications.notify({
      userId,
      role,
      kind,
      params:
        kind === 'OFFER_RECEIVED'
          ? { format: 'REELS', pieceCount: 1 }
          : kind === 'SETTLEMENT_CONFIRMED'
            ? { amount: 43200 }
            : kind === 'SUBMIT_REMINDER'
              ? { days: 3 }
              : {},
      actor:
        kind === 'OFFER_RECEIVED' || kind === 'PAYMENT_FUNDED'
          ? {
              userId: OTHER,
              name: extra.name ?? '한그릇 라멘',
              photoPath:
                extra.photoPath === undefined
                  ? 'stores/ramen.jpg'
                  : extra.photoPath,
            }
          : undefined,
      target:
        kind === 'OFFER_RECEIVED'
          ? { kind: 'OFFER_INBOX', id: 'offer-1' }
          : kind === 'SETTLEMENT_CONFIRMED'
            ? { kind: 'WALLET', id: null }
            : { kind: 'COLLABORATION', id: 'c-1' },
    });

  // 페이지 시험용으로 줄을 한꺼번에 넣는다.
  const seedRows = (
    count: number,
    at: (i: number) => Date,
    over: { userId?: string; role?: 'STORE' | 'CREATOR' } = {},
  ) =>
    prisma.notification.createMany({
      data: Array.from({ length: count }, (_, i) => ({
        userId: over.userId ?? USER_A,
        role: over.role ?? 'STORE',
        kind: 'PAYMENT_FUNDED' as const,
        tab: 'COLLABORATION' as const,
        params: {},
        actorName: `가게 ${i}`,
        targetKind: 'COLLABORATION',
        targetId: `c-${i}`,
        createdAt: at(i),
      })),
    });

  beforeAll(async () => {
    prisma = new PrismaClient();
    app = await createTestApp();
    server = httpOf(app);
    clock = app.get<FakeClock>(Clock);
    notifications = app.get(NotificationsService);
  });
  beforeEach(async () => {
    await truncateTestDb(prisma);
    clock.set(NOW);
    await setRole('STORE');
    await setRole('CREATOR', authB);
  });
  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('rejects requests with no token', async () => {
    await request(server).get('/notifications').expect(401);
    await request(server).get('/notifications/unread-count').expect(401);
    await request(server)
      .post(`/notifications/${randomUUID()}/read`)
      .expect(401);
    await request(server).post('/notifications/read-all').expect(401);
    await request(server).get('/me/notification-settings').expect(401);
    await request(server).put('/me/notification-settings').send({}).expect(401);
  });

  describe('list', () => {
    it('lists only my notifications for my current role, newest first', async () => {
      clock.set(new Date(NOW.getTime() - 2 * 60 * 60 * 1000));
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED', {
        name: '모아 스튜디오',
      });
      clock.set(new Date(NOW.getTime() - 60 * 60 * 1000));
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED', {
        name: '한그릇 라멘',
      });
      // 같은 사람의 다른 역할, 다른 사람의 줄은 보이지 않는다.
      await notifyAs(USER_A, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      await notifyAs(OTHER, 'CREATOR', 'SETTLEMENT_CONFIRMED');

      const body = await page();
      expect(body.nextCursor).toBeNull();
      expect(body.items.map((i) => i.text)).toEqual([
        '한그릇 라멘이 결제했어요. 방문하고 촬영해 주세요.',
        '모아 스튜디오가 결제했어요. 방문하고 촬영해 주세요.',
      ]);
      expect(body.items[0]).toEqual({
        id: expect.any(String) as string,
        tab: 'COLLABORATION',
        text: '한그릇 라멘이 결제했어요. 방문하고 촬영해 주세요.',
        glyph: null,
        actor: {
          name: '한그릇 라멘',
          photoUrl: 'https://fake-storage.test/public/stores/ramen.jpg',
        },
        target: { kind: 'COLLABORATION', id: 'c-1' },
        createdAt: new Date(NOW.getTime() - 60 * 60 * 1000).toISOString(),
        read: false,
      });

      // 역할을 바꾸면 그 역할의 줄만 보인다.
      await setRole('CREATOR');
      const creator = await page();
      expect(creator.items).toHaveLength(1);
      expect(creator.items[0]).toMatchObject({
        tab: 'SETTLEMENT',
        text: '정산 43,200원이 다음 주 수요일에 들어와요.',
        glyph: 'WON',
        actor: null,
        target: { kind: 'WALLET', id: null },
      });
    });

    it('returns an empty page for a person who has not picked a role', async () => {
      await prisma.user.update({ where: { id: USER_A }, data: { role: null } });
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      expect(await page()).toEqual({ items: [], nextCursor: null });
      expect(await unread()).toBe(0);
    });

    it('filters by tab', async () => {
      await notifyAs(USER_A, 'CREATOR', 'OFFER_RECEIVED');
      await notifyAs(USER_A, 'CREATOR', 'SUBMIT_REMINDER');
      await notifyAs(USER_A, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      await setRole('CREATOR');

      const tabs = async (q: string) => (await page(q)).items.map((i) => i.tab);
      expect(await tabs('')).toHaveLength(3);
      expect(await tabs('?tab=ALL')).toHaveLength(3);
      expect(await tabs('?tab=MATCHING')).toEqual(['MATCHING']);
      expect(await tabs('?tab=COLLABORATION')).toEqual(['COLLABORATION']);
      expect(await tabs('?tab=SETTLEMENT')).toEqual(['SETTLEMENT']);
      expect(codeOf(await list('?tab=OTHER').expect(400))).toBe(
        'VALIDATION_FAILED',
      );
    });

    it('pages by 30 with a cursor', async () => {
      // 시각이 같은 줄이 섞여도 순서가 갈리지 않는다(id가 두 번째 기준).
      await seedRows(
        65,
        (i) => new Date(NOW.getTime() - Math.floor(i / 5) * 1000),
      );
      const first = await page();
      expect(first.items).toHaveLength(30);
      expect(first.nextCursor).not.toBeNull();
      const second = await page(
        `?cursor=${encodeURIComponent(first.nextCursor ?? '')}`,
      );
      expect(second.items).toHaveLength(30);
      const third = await page(
        `?cursor=${encodeURIComponent(second.nextCursor ?? '')}`,
      );
      expect(third.items).toHaveLength(5);
      expect(third.nextCursor).toBeNull();

      const ids = [...first.items, ...second.items, ...third.items].map(
        (i) => i.id,
      );
      expect(new Set(ids).size).toBe(65);
      const times = [...first.items, ...second.items, ...third.items].map(
        (i) => i.createdAt,
      );
      expect([...times].sort().reverse()).toEqual(times);
    });

    it('ends with no cursor when exactly 30 rows remain', async () => {
      await seedRows(30, (i) => new Date(NOW.getTime() - i * 1000));
      const only = await page();
      expect(only.items).toHaveLength(30);
      expect(only.nextCursor).toBeNull();
    });

    it('keeps the next page intact when a newer row arrives in between', async () => {
      await seedRows(40, (i) => new Date(NOW.getTime() - (i + 10) * 1000));
      const first = await page();
      await seedRows(3, (i) => new Date(NOW.getTime() - i));
      const second = await page(
        `?cursor=${encodeURIComponent(first.nextCursor ?? '')}`,
      );
      expect(second.items).toHaveLength(10);
      const firstIds = new Set(first.items.map((i) => i.id));
      expect(second.items.some((i) => firstIds.has(i.id))).toBe(false);
    });

    it('rejects a malformed cursor', async () => {
      expect(codeOf(await list('?cursor=not-a-cursor').expect(400))).toBe(
        'VALIDATION_FAILED',
      );
    });

    it('hides notifications older than 90 days', async () => {
      await seedRows(1, () => new Date(NOW.getTime() - 91 * DAY));
      await seedRows(1, () => new Date(NOW.getTime() - 89 * DAY));
      expect(await page()).toMatchObject({
        items: [{ read: false }],
        nextCursor: null,
      });
      expect((await page()).items).toHaveLength(1);
      expect(await unread()).toBe(1);
      // 시계를 앞으로 보내면 89일 전이던 줄도 창을 벗어난다.
      clock.advance(2 * DAY);
      expect((await page()).items).toHaveLength(0);
      expect(await unread()).toBe(0);
    });

    it('renders the actor name from the copy taken when it was created', async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED', {
        name: '옛 이름 식당',
        photoPath: null,
      });
      // 줄은 만들 때의 사본으로 그려진다: 읽을 때 상대(사용자·가게)를 다시 읽지 않는다.
      const [item] = (await page()).items;
      expect(item.text).toBe(
        '옛 이름 식당이 결제했어요. 방문하고 촬영해 주세요.',
      );
      expect(item.actor).toEqual({ name: '옛 이름 식당', photoUrl: null });
    });

    it('marks read rows as read', async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      const [item] = (await page()).items;
      await read(item.id).expect(204);
      expect((await page()).items[0].read).toBe(true);
    });
  });

  describe('unread count', () => {
    it('counts unread notifications of my current role', async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      await notifyAs(USER_A, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      await notifyAs(OTHER, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      expect(await unread()).toBe(2);
      expect(await unread(authB)).toBe(1);
      const [item] = (await page()).items;
      await read(item.id).expect(204);
      expect(await unread()).toBe(1);
      await setRole('CREATOR');
      expect(await unread()).toBe(1);
    });
  });

  describe('read', () => {
    it("marks one as read and returns 404 for someone else's", async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      await notifyAs(OTHER, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      const mine = await prisma.notification.findFirstOrThrow({
        where: { userId: USER_A },
      });
      const theirs = await prisma.notification.findFirstOrThrow({
        where: { userId: OTHER },
      });

      // 남의 알림: 404이고 아무것도 바뀌지 않는다(읽음도, 수정 시각도).
      const before = await prisma.notification.findUniqueOrThrow({
        where: { id: theirs.id },
      });
      const res = await read(theirs.id).expect(404);
      expect(codeOf(res)).toBe('NOT_FOUND');
      expect(
        await prisma.notification.findUniqueOrThrow({
          where: { id: theirs.id },
        }),
      ).toEqual(before);
      expect(await unread(authB)).toBe(1);

      await read(mine.id).expect(204);
      const after = await prisma.notification.findUniqueOrThrow({
        where: { id: mine.id },
      });
      expect(after.readAt).toEqual(NOW);
    });

    it('returns 404 for an id that does not exist or is malformed', async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      expect(codeOf(await read(randomUUID()).expect(404))).toBe('NOT_FOUND');
      expect(codeOf(await read('not-a-uuid').expect(404))).toBe('NOT_FOUND');
      expect(await unread()).toBe(1);
    });

    it('keeps the first read time when the same one is read again', async () => {
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      const mine = await prisma.notification.findFirstOrThrow({
        where: { userId: USER_A },
      });
      await read(mine.id).expect(204);
      clock.advance(DAY);
      await read(mine.id).expect(204);
      const after = await prisma.notification.findUniqueOrThrow({
        where: { id: mine.id },
      });
      expect(after.readAt).toEqual(NOW);
    });

    it('marks all of my current role as read, whatever tab is open', async () => {
      await notifyAs(USER_A, 'CREATOR', 'OFFER_RECEIVED');
      await notifyAs(USER_A, 'CREATOR', 'SUBMIT_REMINDER');
      await notifyAs(USER_A, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      // 다른 역할과 다른 사람의 줄은 그대로다.
      await notifyAs(USER_A, 'STORE', 'PAYMENT_FUNDED');
      await notifyAs(OTHER, 'CREATOR', 'SETTLEMENT_CONFIRMED');
      await setRole('CREATOR');

      await readAll().expect(204);
      expect(await unread()).toBe(0);
      expect((await page('?tab=MATCHING')).items.every((i) => i.read)).toBe(
        true,
      );
      expect((await page('?tab=SETTLEMENT')).items.every((i) => i.read)).toBe(
        true,
      );
      expect(await unread(authB)).toBe(1);
      await setRole('STORE');
      expect(await unread()).toBe(1);
    });
  });

  describe('settings', () => {
    it('returns default settings and saves changes', async () => {
      expect((await getSettings().expect(200)).body).toEqual({
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: false,
        quietHours: 'NIGHT',
        enabledCount: 4,
      });
      const res = await putSettings({
        mutualInterest: false,
        offers: true,
        messages: false,
        settlement: true,
        recommendations: false,
        quietHours: 'WEEKEND',
      }).expect(200);
      const expected: SettingsBody = {
        mutualInterest: false,
        offers: true,
        messages: false,
        settlement: true,
        recommendations: false,
        quietHours: 'WEEKEND',
        enabledCount: 2,
      };
      expect(res.body).toEqual(expected);
      expect((await getSettings().expect(200)).body).toEqual(expected);
      // 설정은 사람 하나에 하나다: 다른 사람의 설정은 그대로 기본값이다.
      expect(
        ((await getSettings(authB).expect(200)).body as SettingsBody)
          .enabledCount,
      ).toBe(4);
      expect(await prisma.notificationSetting.count()).toBe(1);
    });

    it('overwrites an earlier save', async () => {
      const all = {
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: true,
        quietHours: 'OFF',
      };
      await putSettings({ ...all, offers: false }).expect(200);
      const res = await putSettings(all).expect(200);
      expect(res.body).toEqual({ ...all, enabledCount: 5 });
      expect(await prisma.notificationSetting.count()).toBe(1);
    });

    it('stamps the consent time when recommendations are turned on', async () => {
      const base = {
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        quietHours: 'NIGHT',
      };
      const agreedAt = async () =>
        (
          await prisma.notificationSetting.findFirstOrThrow({
            where: { userId: USER_A },
          })
        ).recommendationsAgreedAt;

      // 꺼진 채로 저장하면 동의 시각이 없다.
      await putSettings({ ...base, recommendations: false }).expect(200);
      expect(await agreedAt()).toBeNull();

      // 꺼짐 → 켜짐: 지금 시각.
      await putSettings({ ...base, recommendations: true }).expect(200);
      expect(await agreedAt()).toEqual(NOW);

      // 켜진 채로 다시 저장해도 시각은 그대로다.
      clock.advance(DAY);
      await putSettings({
        ...base,
        recommendations: true,
        offers: false,
      }).expect(200);
      expect(await agreedAt()).toEqual(NOW);

      // 끄면 동의했던 기록은 남는다.
      clock.advance(DAY);
      await putSettings({ ...base, recommendations: false }).expect(200);
      expect(await agreedAt()).toEqual(NOW);

      // 다시 켜면 새 동의 시각이다.
      clock.advance(DAY);
      await putSettings({ ...base, recommendations: true }).expect(200);
      expect(await agreedAt()).toEqual(new Date(NOW.getTime() + 3 * DAY));
    });

    it('stamps the consent time on the very first save with recommendations on', async () => {
      await putSettings({
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: true,
        quietHours: 'NIGHT',
      }).expect(200);
      const row = await prisma.notificationSetting.findFirstOrThrow({
        where: { userId: USER_A },
      });
      expect(row.recommendationsAgreedAt).toEqual(NOW);
    });

    it('rejects an invalid body', async () => {
      const ok = {
        mutualInterest: true,
        offers: true,
        messages: true,
        settlement: true,
        recommendations: false,
        quietHours: 'NIGHT',
      };
      expect(
        codeOf(await putSettings({ ...ok, quietHours: 'DAY' }).expect(400)),
      ).toBe('VALIDATION_FAILED');
      expect(
        codeOf(await putSettings({ ...ok, offers: 'yes' }).expect(400)),
      ).toBe('VALIDATION_FAILED');
      const { offers: _omit, ...missing } = ok;
      void _omit;
      await putSettings(missing).expect(400);
      await putSettings({ ...ok, enabledCount: 4 }).expect(400);
      expect(await prisma.notificationSetting.count()).toBe(0);
    });
  });
});
