import { NotificationsRepository } from '../../src/notifications/notifications.repository';
import { prisma } from './setup-db';

const USER = '66666666-6666-4666-8666-666666666661';
const OTHER = '66666666-6666-4666-8666-666666666662';

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: USER, role: 'CREATOR' },
      { id: OTHER, role: 'STORE' },
    ],
  });
});

function row(over: { userId?: string; dedupeKey?: string | null } = {}) {
  return {
    userId: over.userId ?? USER,
    role: 'CREATOR' as const,
    kind: 'OFFER_RECEIVED' as const,
    tab: 'MATCHING' as const,
    params: { format: 'REELS', pieceCount: 1 },
    targetKind: 'OFFER_INBOX',
    dedupeKey: over.dedupeKey ?? null,
  };
}

describe('notifications', () => {
  it('rejects two rows with the same user and dedupe key', async () => {
    await prisma.notification.create({ data: row({ dedupeKey: 'k1' }) });
    await expect(
      prisma.notification.create({ data: row({ dedupeKey: 'k1' }) }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });

  it('allows the same dedupe key for different users', async () => {
    await prisma.notification.create({ data: row({ dedupeKey: 'k1' }) });
    await prisma.notification.create({
      data: { ...row({ userId: OTHER, dedupeKey: 'k1' }), role: 'STORE' },
    });
    expect(await prisma.notification.count()).toBe(2);
  });

  it('allows many rows without a dedupe key', async () => {
    await prisma.notification.create({ data: row() });
    await prisma.notification.create({ data: row() });
    expect(await prisma.notification.count()).toBe(2);
  });

  it('creates a row that carries timestamps and a soft-delete column', async () => {
    const created = await prisma.notification.create({ data: row() });
    expect(created.createdAt).toBeInstanceOf(Date);
    expect(created.updatedAt).toBeInstanceOf(Date);
    expect(created.deletedAt).toBeNull();
    expect(created.readAt).toBeNull();
  });
});

describe('NotificationsRepository', () => {
  const repo = () => new NotificationsRepository(prisma as never);

  it('returns null instead of throwing for a repeated dedupe key', async () => {
    const input = {
      ...row({ dedupeKey: 'k2' }),
      actorUserId: null,
      actorName: null,
      actorPhotoPath: null,
      targetId: null,
      createdAt: new Date('2026-11-11T03:00:00.000Z'),
    };
    const first = await repo().create(input);
    const second = await repo().create(input);
    expect(first).toEqual({ id: expect.any(String) as string });
    expect(second).toBeNull();
    expect(await prisma.notification.count()).toBe(1);
  });

  it('keeps exactly one row when the same key arrives at the same time', async () => {
    const input = {
      ...row({ dedupeKey: 'k3' }),
      actorUserId: null,
      actorName: null,
      actorPhotoPath: null,
      targetId: null,
      createdAt: new Date('2026-11-11T03:00:00.000Z'),
    };
    const results = await Promise.all(
      Array.from({ length: 5 }, () => repo().create(input)),
    );
    expect(results.filter((r) => r !== null)).toHaveLength(1);
    expect(await prisma.notification.count()).toBe(1);
  });

  it('has no settings row for a new person and the defaults once one exists', async () => {
    expect(await repo().findSettings(USER)).toBeNull();
    await prisma.notificationSetting.create({ data: { userId: USER } });
    expect(await repo().findSettings(USER)).toEqual({
      mutualInterest: true,
      offers: true,
      messages: true,
      settlement: true,
      recommendations: false,
      quietHours: 'NIGHT',
    });
  });

  it('keeps one settings row per person', async () => {
    await prisma.notificationSetting.create({ data: { userId: USER } });
    await expect(
      prisma.notificationSetting.create({ data: { userId: USER } }),
    ).rejects.toMatchObject({ code: 'P2002' });
  });

  it('stores the createdAt it is given instead of the database clock', async () => {
    const at = new Date('2026-01-02T03:04:05.678Z');
    await repo().create({
      ...row({ dedupeKey: 'k4' }),
      actorUserId: null,
      actorName: null,
      actorPhotoPath: null,
      targetId: null,
      createdAt: at,
    });
    expect((await prisma.notification.findFirstOrThrow()).createdAt).toEqual(
      at,
    );
  });

  it('pages the inbox by time then id without skipping rows that share a time', async () => {
    const at = new Date('2026-11-11T03:00:00.000Z');
    await prisma.notification.createMany({
      data: Array.from({ length: 7 }, () => ({ ...row(), createdAt: at })),
    });
    const since = new Date('2026-01-01T00:00:00.000Z');
    const base = { userId: USER, role: 'CREATOR' as const, tab: null, since };
    const first = await repo().listInbox({ ...base, after: null, limit: 3 });
    const second = await repo().listInbox({
      ...base,
      after: { createdAt: first[2].createdAt, id: first[2].id },
      limit: 3,
    });
    const third = await repo().listInbox({
      ...base,
      after: { createdAt: second[2].createdAt, id: second[2].id },
      limit: 3,
    });
    const ids = [...first, ...second, ...third].map((r) => r.id);
    expect(ids).toHaveLength(7);
    expect(new Set(ids).size).toBe(7);
  });

  it("does not touch someone else's row when marking read", async () => {
    const theirs = await prisma.notification.create({
      data: { ...row({ userId: OTHER }), role: 'STORE' },
    });
    const now = new Date('2026-11-11T03:00:00.000Z');
    expect(await repo().markRead(theirs.id, USER, now)).toBe(false);
    expect(
      await prisma.notification.findUniqueOrThrow({ where: { id: theirs.id } }),
    ).toEqual(theirs);
  });

  it('upserts settings once per person and keeps the consent time unless one is given', async () => {
    const values = {
      mutualInterest: true,
      offers: true,
      messages: true,
      settlement: true,
      recommendations: true,
      quietHours: 'NIGHT' as const,
    };
    const at = new Date('2026-11-11T03:00:00.000Z');
    await repo().upsertSettings(USER, values, at);
    await repo().upsertSettings(
      USER,
      { ...values, recommendations: false },
      null,
    );
    const saved = await prisma.notificationSetting.findFirstOrThrow({
      where: { userId: USER },
    });
    expect(saved.recommendations).toBe(false);
    expect(saved.recommendationsAgreedAt).toEqual(at);
    expect(await prisma.notificationSetting.count()).toBe(1);
  });
});
