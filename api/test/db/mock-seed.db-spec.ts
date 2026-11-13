import { DEV_ACCOUNTS } from '../../seed/lib/dev-accounts';
import { assertBalanced, balances } from '../../src/ledger/ledger-postings';
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
  it('creates the store, profiles, applicants, proposals and the settled collaboration', async () => {
    await run();

    expect(await prisma.creatorProfile.count()).toBe(5);
    const store = await prisma.store.findUniqueOrThrow({
      where: { ownerId: accountIds.get('010-0000-0001') as string },
    });
    expect(store).toMatchObject({
      status: 'PUBLISHED',
      onboardingStep: 'DONE',
      slug: 'hangeureut-ramen',
      recruitLine: '첫 숟가락 릴스',
      trialPostCount: 9,
    });
    expect(store.tags).toEqual(['진한국물', '바좌석', '조용한오후']);
    expect(await prisma.storeSourceLink.count()).toBe(3);
    const applications = await prisma.application.findMany({
      where: { status: 'APPLIED' },
    });
    expect(applications).toHaveLength(5);
    expect(applications.filter((a) => a.pitch !== null)).toHaveLength(3);
    expect(await prisma.offer.count()).toBe(5);
    expect(await prisma.offer.count({ where: { status: 'SENT' } })).toBe(3);
    expect(await prisma.offerVersion.count()).toBe(6);
    expect(await prisma.creatorSeries.count()).toBe(3);
  });

  it('settles one collaboration whose ledger is balanced and money rows are done', async () => {
    await run();

    const collaboration = await prisma.collaboration.findFirstOrThrow({
      include: { settlement: true, payouts: true, refunds: true, offer: true },
    });
    expect(collaboration.stage).toBe('SETTLED');
    expect(collaboration.settlement).toMatchObject({
      finalViews: 12500,
      payoutAmount: 25000,
      refundAmount: 35000,
      usualViews: 4000,
      multiplierTenths: 31,
    });
    expect(collaboration.payouts).toMatchObject([
      { amount: 25000, status: 'DONE' },
    ]);
    expect(collaboration.refunds).toMatchObject([
      { amount: 35000, status: 'DONE' },
    ]);
    expect(collaboration.offer?.closedAt).not.toBeNull();
    expect(await prisma.viewSnapshot.count()).toBe(8);
    const entries = await prisma.ledgerEntry.findMany({
      where: { collaborationId: collaboration.id },
    });
    expect(() => assertBalanced(entries)).not.toThrow();
    expect(balances(entries).ESCROW).toBe(0);
  });

  it('keeps the same row counts when run twice and ids of store and profiles', async () => {
    await run();
    const store = await prisma.store.findFirstOrThrow();

    await run();

    expect((await prisma.store.findFirstOrThrow()).id).toBe(store.id);
    expect(await prisma.store.count()).toBe(1);
    expect(await prisma.creatorProfile.count()).toBe(5);
    expect(await prisma.storeSourceLink.count()).toBe(3);
    expect(await prisma.application.count()).toBe(5);
    expect(await prisma.offer.count()).toBe(5);
    expect(await prisma.offerVersion.count()).toBe(6);
    expect(await prisma.collaboration.count()).toBe(1);
    expect(await prisma.payment.count()).toBe(1);
    expect(await prisma.ledgerEntry.count()).toBe(4);
    expect(await prisma.settlement.count()).toBe(1);
    expect(await prisma.payout.count()).toBe(1);
    expect(await prisma.refund.count()).toBe(1);
    expect(await prisma.creatorSeries.count()).toBe(3);
  });

  it('resets rows made during a demo but leaves other accounts alone', async () => {
    await run();
    const seoyun = accountIds.get('010-0000-0003') as string;
    await prisma.creatorSeries.create({
      data: { creatorId: seoyun, name: '시연 시리즈', format: 'BLOG' },
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
    await prisma.creatorSeries.create({
      data: { creatorId: OTHER_CREATOR, name: '남의 시리즈', format: 'REELS' },
    });
    // 남의 가게의 오퍼에 붙은 협업과 장부.
    const otherOffer = await prisma.offer.create({
      data: {
        storeId: otherStore.id,
        creatorId: OTHER_CREATOR,
        status: 'ACCEPTED',
        turn: 'CREATOR',
        initiatedBy: 'STORE',
        expiresAt: new Date(),
        closedAt: new Date(),
      },
    });
    const otherCollaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'FUNDED',
        commissionerId: OTHER_OWNER,
        creatorId: OTHER_CREATOR,
        offerId: otherOffer.id,
        storeId: otherStore.id,
        terms: {},
        settlementMethod: 'PER_VIEW',
      },
    });
    await prisma.ledgerEntry.create({
      data: {
        collaborationId: otherCollaboration.id,
        batchId: OTHER_CREATOR,
        debitAccount: 'PG_IN',
        creditAccount: 'ESCROW',
        amount: 1000,
        reason: 'PAYMENT_ESCROW',
        idempotencyKey: 'other',
      },
    });

    await run();

    expect(
      await prisma.creatorSeries.count({ where: { creatorId: seoyun } }),
    ).toBe(3);
    expect(
      await prisma.application.count({ where: { storeId: otherStore.id } }),
    ).toBe(1);
    expect(
      await prisma.creatorSeries.count({ where: { creatorId: OTHER_CREATOR } }),
    ).toBe(1);
    expect(await prisma.collaboration.count()).toBe(2);
    expect(
      await prisma.ledgerEntry.count({
        where: { collaborationId: otherCollaboration.id },
      }),
    ).toBe(1);
  });
});
