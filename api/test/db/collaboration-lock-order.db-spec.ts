import { PrismaClient } from '@prisma/client';
import { CancelRequestsRepository } from '../../src/collaborations/cancel-requests.repository';
import { OpsRepository } from '../../src/ops/ops.repository';
import { SettlementsRepository } from '../../src/settlements/settlements.repository';
import { createOffer } from '../helpers/create-offer';
import { prisma } from './setup-db';

const OWNER = '88888888-8888-4888-8888-888888888881';
const CREATOR = '88888888-8888-4888-8888-888888888882';
const MISSING = '88888888-8888-4888-8888-8888888888ff';
const T0 = new Date('2026-12-01T00:00:00.000Z');

// 협업을 잠그는 두 함수는 오퍼 → 협업 순서로 잠근다(결제 승인·판본 수락과 같은 순서).
// 다른 연결이 NOWAIT으로 잡으려 할 때 이미 잠겨 있으면 실패하는 것으로 확인한다.
describe('collaboration lock order', () => {
  let other: PrismaClient;
  let offerId: string;
  let collaborationId: string;

  beforeAll(() => {
    other = new PrismaClient();
  });
  afterAll(async () => {
    await other.$disconnect();
  });

  beforeEach(async () => {
    await prisma.user.createMany({
      data: [
        { id: OWNER, role: 'STORE' },
        { id: CREATOR, role: 'CREATOR' },
      ],
    });
    const store = await prisma.store.create({ data: { ownerId: OWNER } });
    const offer = await createOffer(prisma, {
      storeId: store.id,
      creatorId: CREATOR,
      status: 'ACCEPTED',
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      expiresAt: new Date('2026-12-08T00:00:00Z'),
      createdAt: T0,
    });
    offerId = offer.id;
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'FUNDED',
        commissionerId: OWNER,
        creatorId: CREATOR,
        offerId,
        storeId: store.id,
        terms: { format: 'REELS', pieces: 1, fixedCash: 0 },
        settlementMethod: 'NONE',
      },
    });
    collaborationId = collaboration.id;
  });

  const tryLockOffer = () =>
    other.$queryRaw`SELECT id FROM offers WHERE id = ${offerId}::uuid FOR UPDATE NOWAIT`;
  const tryLockCollaboration = () =>
    other.$queryRaw`SELECT id FROM collaborations WHERE id = ${collaborationId}::uuid FOR UPDATE NOWAIT`;

  it('locks the linked offer along with the collaboration for cancel requests', async () => {
    const repo = new CancelRequestsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await repo.lockCollaboration(collaborationId, tx);
      await expect(tryLockOffer()).rejects.toThrow();
      await expect(tryLockCollaboration()).rejects.toThrow();
    });
    // 트랜잭션이 끝나면 풀린다.
    await expect(tryLockOffer()).resolves.toHaveLength(1);
  });

  it('locks the linked offer along with the collaboration for ops commands', async () => {
    const repo = new OpsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await expect(repo.lockCollaboration(collaborationId, tx)).resolves.toBe(
        true,
      );
      await expect(tryLockOffer()).rejects.toThrow();
      await expect(tryLockCollaboration()).rejects.toThrow();
    });
    await expect(tryLockOffer()).resolves.toHaveLength(1);
  });

  it('still locks a collaboration that has no offer', async () => {
    const orphan = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'FUNDED',
        commissionerId: OWNER,
        creatorId: CREATOR,
        terms: { format: 'REELS', pieces: 1, fixedCash: 0 },
        settlementMethod: 'NONE',
      },
    });
    const cancelRepo = new CancelRequestsRepository(prisma as never);
    const opsRepo = new OpsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await cancelRepo.lockCollaboration(orphan.id, tx);
      await expect(opsRepo.lockCollaboration(orphan.id, tx)).resolves.toBe(
        true,
      );
    });
  });

  it('reports a missing collaboration as false for ops commands', async () => {
    const repo = new OpsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await expect(repo.lockCollaboration(MISSING, tx)).resolves.toBe(false);
    });
  });

  describe('settlement rows', () => {
    const tryLockSettlement = () =>
      other.$queryRaw`SELECT id FROM settlements WHERE collaboration_id = ${collaborationId}::uuid FOR UPDATE NOWAIT`;
    const createUnconfirmed = () =>
      prisma.settlement.create({
        data: {
          collaborationId,
          finalViews: 12500,
          payoutAmount: 25000,
          refundAmount: 35000,
          status: 'UNCONFIRMED',
          settledAt: null,
        },
      });

    it('locks the settlement row first for ops commands when there is one', async () => {
      await createUnconfirmed();
      const repo = new OpsRepository(prisma as never);
      await prisma.$transaction(async (tx) => {
        await expect(repo.lockCollaboration(collaborationId, tx)).resolves.toBe(
          true,
        );
        await expect(tryLockSettlement()).rejects.toThrow();
        await expect(tryLockOffer()).rejects.toThrow();
        await expect(tryLockCollaboration()).rejects.toThrow();
      });
      await expect(tryLockSettlement()).resolves.toHaveLength(1);
    });

    it('locks the offer and the collaboration before creating a calculation', async () => {
      const repo = new SettlementsRepository(prisma as never);
      await prisma.$transaction(async (tx) => {
        await expect(repo.lockCollaboration(collaborationId, tx)).resolves.toBe(
          true,
        );
        await expect(tryLockOffer()).rejects.toThrow();
        await expect(tryLockCollaboration()).rejects.toThrow();
      });
      await expect(tryLockCollaboration()).resolves.toHaveLength(1);
    });

    it('holds the settlement row after confirming it and refuses a second confirmation', async () => {
      await createUnconfirmed();
      const repo = new SettlementsRepository(prisma as never);
      const now = new Date('2026-12-10T00:00:00.000Z');
      await prisma.$transaction(async (tx) => {
        await expect(
          repo.confirmCalculation(collaborationId, 'AUTO', now, null, tx),
        ).resolves.toBe(true);
        await expect(tryLockSettlement()).rejects.toThrow();
        await expect(
          repo.confirmCalculation(collaborationId, 'AUTO', now, null, tx),
        ).resolves.toBe(false);
      });
      expect(
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId },
        }),
      ).toMatchObject({
        status: 'CONFIRMED',
        confirmedBy: 'AUTO',
        settledAt: now,
        confirmedAt: now,
      });
    });

    it('confirms only a calculation read from the asked source', async () => {
      await createUnconfirmed();
      await prisma.settlement.update({
        where: { collaborationId },
        data: { evidenceSource: 'CAPTURE' },
      });
      const repo = new SettlementsRepository(prisma as never);
      const now = new Date('2026-12-10T00:00:00.000Z');
      await prisma.$transaction(async (tx) => {
        await expect(
          repo.confirmCalculation(
            collaborationId,
            'AUTO',
            now,
            'CONNECTED_ACCOUNT',
            tx,
          ),
        ).resolves.toBe(false);
        await expect(
          repo.confirmCalculation(collaborationId, 'OPERATOR', now, null, tx),
        ).resolves.toBe(true);
      });
    });

    it('never confirms a disputed calculation', async () => {
      await createUnconfirmed();
      await prisma.settlement.update({
        where: { collaborationId },
        data: { status: 'DISPUTED' },
      });
      const repo = new SettlementsRepository(prisma as never);
      await prisma.$transaction(async (tx) => {
        await expect(
          repo.confirmCalculation(
            collaborationId,
            'AUTO',
            new Date(),
            null,
            tx,
          ),
        ).resolves.toBe(false);
      });
    });
  });
});
