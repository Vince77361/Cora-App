import { createOffer } from '../helpers/create-offer';
import { prisma } from './setup-db';

const OWNER = '77777777-7777-4777-8777-777777777771';
const CREATOR = '77777777-7777-4777-8777-777777777772';
const T0 = new Date('2026-12-01T00:00:00.000Z');

let storeId: string;

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: OWNER, role: 'STORE' },
      { id: CREATOR, role: 'CREATOR' },
    ],
  });
  storeId = (await prisma.store.create({ data: { ownerId: OWNER } })).id;
});

function offerWithVersionOne(status: 'SENT' | 'ACCEPTED' = 'SENT') {
  return createOffer(prisma, {
    storeId,
    creatorId: CREATOR,
    format: 'REELS',
    voucherName: '식사권',
    voucherValue: 40000,
    voucherPeople: 2,
    status,
    expiresAt: new Date('2026-12-08T00:00:00Z'),
    createdAt: T0,
  });
}

function version(offerId: string, number: number) {
  return prisma.offerVersion.create({
    data: {
      offerId,
      number,
      authorParty: 'CREATOR',
      format: 'REELS',
      fixedCash: 0,
      usageRights: 'NONE',
    },
  });
}

describe('offer versions', () => {
  it('rejects two versions with the same number for one offer', async () => {
    const offer = await offerWithVersionOne();
    await expect(version(offer.id, 1)).rejects.toThrow();
    await expect(version(offer.id, 2)).resolves.toBeDefined();
    await expect(version(offer.id, 2)).rejects.toThrow();
  });

  it('lets two offers each have their own version 1', async () => {
    const first = await offerWithVersionOne();
    await prisma.offer.update({
      where: { id: first.id },
      data: { status: 'CANCELLED' },
    });
    const second = await offerWithVersionOne();
    expect(await prisma.offerVersion.count({ where: { number: 1 } })).toBe(2);
    expect(second.id).not.toBe(first.id);
  });

  it('refuses a version for an offer that does not exist', async () => {
    await expect(
      version('77777777-7777-4777-8777-777777777779', 1),
    ).rejects.toThrow();
  });

  it('keeps the original terms on version 1 and the flow on the offer', async () => {
    const offer = await offerWithVersionOne();
    const row = await prisma.offer.findUniqueOrThrow({
      where: { id: offer.id },
      include: { versions: true },
    });
    expect(row).toMatchObject({
      latestVersion: 1,
      turn: 'CREATOR',
      initiatedBy: 'STORE',
      endReason: null,
      endedBy: null,
    });
    expect(row.versions[0]).toMatchObject({
      number: 1,
      authorParty: 'STORE',
      voucherName: '식사권',
      createdAt: T0,
    });
  });

  // 2번 R11 안전망: 이 인덱스는 Prisma 스키마 밖이라 마이그레이션이 지우거나 바꿔도 컴파일이 알려 주지 않는다.
  it('keeps the partial unique index for open offers', async () => {
    const rows = await prisma.$queryRaw<{ indexdef: string }[]>`
      SELECT indexdef FROM pg_indexes
      WHERE indexname = 'offers_open_store_creator_key'
        AND schemaname = current_schema()`;
    expect(rows).toHaveLength(1);
    const def = rows[0].indexdef;
    expect(def).toContain('UNIQUE');
    expect(def).toContain('closed_at IS NULL');
    expect(def).toContain('deleted_at IS NULL');
    // 진행 중에는 두 번째 SENT가 막히고, 닫힌 뒤에는 들어간다.
    const open = await offerWithVersionOne('ACCEPTED');
    await expect(offerWithVersionOne()).rejects.toThrow();
    await prisma.offer.update({
      where: { id: open.id },
      data: { closedAt: T0 },
    });
    await expect(offerWithVersionOne()).resolves.toBeDefined();
  });
});
