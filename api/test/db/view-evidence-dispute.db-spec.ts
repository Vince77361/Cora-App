import { SettlementsRepository } from '../../src/settlements/settlements.repository';
import { prisma } from './setup-db';

const OWNER = '99999999-9999-4999-8999-999999999991';
const CREATOR = '99999999-9999-4999-8999-999999999992';

// 조회수 캡처(view_evidences)와 이의(settlement_disputes) 표. RLS는 rls.db-spec이 모든 표에서 확인한다.
describe('view evidence and settlement disputes', () => {
  let collaborationId: string;

  beforeEach(async () => {
    await prisma.user.createMany({
      data: [
        { id: OWNER, role: 'STORE' },
        { id: CREATOR, role: 'CREATOR' },
      ],
    });
    const store = await prisma.store.create({ data: { ownerId: OWNER } });
    const collaboration = await prisma.collaboration.create({
      data: {
        kind: 'STORE_OFFER',
        stage: 'COUNTING',
        commissionerId: OWNER,
        creatorId: CREATOR,
        storeId: store.id,
        terms: {},
        settlementMethod: 'PER_VIEW',
      },
    });
    collaborationId = collaboration.id;
    await prisma.settlement.create({
      data: {
        collaborationId,
        finalViews: 100,
        payoutAmount: 10,
        refundAmount: 20,
        status: 'UNCONFIRMED',
        settledAt: null,
      },
    });
  });

  it('allows one dispute per person and collaboration', async () => {
    const repo = new SettlementsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await expect(
        repo.createDispute(
          { collaborationId, raisedById: OWNER, reason: '다시 봐 주세요' },
          tx,
        ),
      ).resolves.toBe(true);
      await expect(
        repo.createDispute(
          { collaborationId, raisedById: OWNER, reason: '또요' },
          tx,
        ),
      ).resolves.toBe(false);
      await expect(
        repo.createDispute(
          { collaborationId, raisedById: CREATOR, reason: '저도요' },
          tx,
        ),
      ).resolves.toBe(true);
    });
    expect(await prisma.settlementDispute.count()).toBe(2);
  });

  it('moves a calculation to disputed only from unconfirmed and holds the settlement row', async () => {
    const repo = new SettlementsRepository(prisma as never);
    await prisma.$transaction(async (tx) => {
      await expect(repo.disputeCalculation(collaborationId, tx)).resolves.toBe(
        true,
      );
      await expect(repo.disputeCalculation(collaborationId, tx)).resolves.toBe(
        false,
      );
      await expect(
        repo.confirmCalculation(collaborationId, 'AUTO', new Date(), {}, tx),
      ).resolves.toBe(false);
    });
    expect(
      (
        await prisma.settlement.findUniqueOrThrow({
          where: { collaborationId },
        })
      ).status,
    ).toBe('DISPUTED');
  });

  it('confirms a disputed calculation only when asked from the disputed state and writes the corrected values', async () => {
    const repo = new SettlementsRepository(prisma as never);
    await prisma.settlement.update({
      where: { collaborationId },
      data: { status: 'DISPUTED' },
    });
    const at = new Date('2026-12-10T00:00:00.000Z');
    await prisma.$transaction(async (tx) => {
      await expect(
        repo.confirmCalculation(collaborationId, 'OPERATOR', at, {}, tx),
      ).resolves.toBe(false);
      await expect(
        repo.confirmCalculation(
          collaborationId,
          'OPERATOR',
          at,
          {
            from: 'DISPUTED',
            corrected: {
              finalViews: 50,
              payoutAmount: 5,
              refundAmount: 25,
              fixedCashAmount: 0,
              viewPayAmount: 5,
            },
          },
          tx,
        ),
      ).resolves.toBe(true);
    });
    expect(
      await prisma.settlement.findUniqueOrThrow({ where: { collaborationId } }),
    ).toMatchObject({
      status: 'CONFIRMED',
      confirmedBy: 'OPERATOR',
      finalViews: 50,
      payoutAmount: 5,
      refundAmount: 25,
      settledAt: at,
    });
  });

  it('stores a capture, finds it and marks it confirmed once', async () => {
    const repo = new SettlementsRepository(prisma as never);
    const at = new Date('2026-12-10T00:00:00.000Z');
    await prisma.$transaction(async (tx) => {
      await repo.createEvidence(
        {
          collaborationId,
          filePath: `evidence/${CREATOR}/x.jpg`,
          statedViews: 777,
          submittedById: CREATOR,
        },
        tx,
      );
      await repo.confirmEvidence(collaborationId, '김운영', at, tx);
      await repo.confirmEvidence(
        collaborationId,
        '다른 운영자',
        new Date(),
        tx,
      );
    });
    expect(await repo.findEvidence(collaborationId)).toMatchObject({
      statedViews: 777,
      confirmedAt: at,
      confirmedBy: '김운영',
    });
  });
});
