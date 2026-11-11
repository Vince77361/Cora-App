import { DEV_ACCOUNTS } from '../../seed/lib/dev-accounts';
import { runMockSeed } from '../../seed/lib/mock-seed';
import { PrismaMockSeedDb } from '../../seed/lib/mock-seed-db';
import { FakeClock } from '../support/fake-clock';
import { FakeStoragePort } from '../support/fake-storage.port';
import { prisma } from './setup-db';

const OTHER_OWNER = '55555555-5555-4555-8555-555555555551';
const OTHER_CREATOR = '55555555-5555-4555-8555-555555555552';

const accountIds = new Map(
  DEV_ACCOUNTS.map((a, i) => [
    a.phone,
    `00000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`,
  ]),
);

const run = () =>
  runMockSeed(
    {
      db: new PrismaMockSeedDb(prisma),
      storage: new FakeStoragePort(),
      clock: new FakeClock(),
      log: () => undefined,
    },
    accountIds,
  );

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      ...DEV_ACCOUNTS.map((a) => ({
        id: accountIds.get(a.phone) as string,
        role: a.role,
      })),
      { id: OTHER_OWNER, role: 'STORE' },
      { id: OTHER_CREATOR, role: 'CREATOR' },
    ],
  });
});

describe('PrismaMockSeedDb', () => {
  it('creates the store, profiles, applicants and declined offer', async () => {
    await run();

    expect(await prisma.creatorProfile.count()).toBe(5);
    const store = await prisma.store.findUniqueOrThrow({
      where: { ownerId: accountIds.get('010-0000-0001') as string },
    });
    expect(store.status).toBe('PUBLISHED');
    expect(store.onboardingStep).toBe('DONE');
    expect(await prisma.storeSourceLink.count()).toBe(2);
    expect(
      await prisma.application.count({ where: { status: 'APPLIED' } }),
    ).toBe(3);
    expect(await prisma.offer.count({ where: { status: 'DECLINED' } })).toBe(1);
  });

  it('keeps the same row counts when run twice and ids of store and profiles', async () => {
    await run();
    const store = await prisma.store.findFirstOrThrow();

    await run();

    expect((await prisma.store.findFirstOrThrow()).id).toBe(store.id);
    expect(await prisma.store.count()).toBe(1);
    expect(await prisma.creatorProfile.count()).toBe(5);
    expect(await prisma.storeSourceLink.count()).toBe(2);
    expect(await prisma.application.count()).toBe(3);
    expect(await prisma.offer.count()).toBe(1);
  });

  it('resets rows made during a demo but leaves other accounts alone', async () => {
    await run();
    const store = await prisma.store.findFirstOrThrow();
    const seoyun = accountIds.get('010-0000-0003') as string;
    await prisma.application.create({
      data: { storeId: store.id, creatorId: seoyun, status: 'APPLIED' },
    });
    const otherStore = await prisma.store.create({
      data: { ownerId: OTHER_OWNER },
    });
    await prisma.application.create({
      data: {
        storeId: otherStore.id,
        creatorId: OTHER_CREATOR,
        status: 'APPLIED',
      },
    });

    await run();

    expect(
      await prisma.application.count({ where: { creatorId: seoyun } }),
    ).toBe(0);
    expect(
      await prisma.application.count({ where: { storeId: otherStore.id } }),
    ).toBe(1);
    expect(await prisma.application.count()).toBe(4);
  });
});
