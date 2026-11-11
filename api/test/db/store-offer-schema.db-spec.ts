import { prisma } from './setup-db';

const OWNER = '44444444-4444-4444-8444-444444444441';
const OWNER_2 = '44444444-4444-4444-8444-444444444442';
const CREATOR = '44444444-4444-4444-8444-444444444443';

let storeId: string;

beforeEach(async () => {
  // 각 테스트 전에 setup-db가 모든 테이블을 비우므로 기준 데이터를 여기서 다시 만든다.
  await prisma.user.createMany({
    data: [
      { id: OWNER, role: 'STORE' },
      { id: OWNER_2, role: 'STORE' },
      { id: CREATOR, role: 'CREATOR' },
    ],
  });
  const store = await prisma.store.create({ data: { ownerId: OWNER } });
  storeId = store.id;
});

function createApplication(input: {
  status: 'APPLIED' | 'CANCELLED' | 'OFFERED' | 'CLOSED';
  deletedAt?: Date;
}) {
  return prisma.application.create({
    data: { storeId, creatorId: CREATOR, ...input },
  });
}

function createOffer(input: {
  status: 'SENT' | 'ACCEPTED' | 'DECLINED' | 'EXPIRED' | 'CANCELLED';
  deletedAt?: Date;
}) {
  return prisma.offer.create({
    data: {
      storeId,
      creatorId: CREATOR,
      format: 'REELS',
      rewardType: 'VOUCHER',
      expiresAt: new Date('2026-12-01T00:00:00Z'),
      ...input,
    },
  });
}

describe('applications', () => {
  it('rejects a second live application for the same store and creator', async () => {
    await createApplication({ status: 'APPLIED' });
    await expect(createApplication({ status: 'APPLIED' })).rejects.toThrow();
  });

  it('rejects an OFFERED application while another one is APPLIED', async () => {
    await createApplication({ status: 'APPLIED' });
    await expect(createApplication({ status: 'OFFERED' })).rejects.toThrow();
  });

  it('allows a new application after the previous one was cancelled', async () => {
    await createApplication({ status: 'CANCELLED' });
    await expect(
      createApplication({ status: 'APPLIED' }),
    ).resolves.toBeDefined();
  });

  it('allows a new application after the previous one was closed', async () => {
    await createApplication({ status: 'CLOSED' });
    await expect(
      createApplication({ status: 'APPLIED' }),
    ).resolves.toBeDefined();
  });

  it('allows a new application after the previous one was soft-deleted', async () => {
    await createApplication({ status: 'APPLIED', deletedAt: new Date() });
    await expect(
      createApplication({ status: 'APPLIED' }),
    ).resolves.toBeDefined();
  });
});

describe('offers', () => {
  it('rejects a second open offer for the same store and creator', async () => {
    await createOffer({ status: 'SENT' });
    await expect(createOffer({ status: 'ACCEPTED' })).rejects.toThrow();
  });

  it('allows a new offer after the previous one was declined', async () => {
    await createOffer({ status: 'DECLINED' });
    await expect(createOffer({ status: 'SENT' })).resolves.toBeDefined();
  });

  it('allows a new offer after the previous one expired or was cancelled', async () => {
    await createOffer({ status: 'EXPIRED' });
    await createOffer({ status: 'CANCELLED' });
    await expect(createOffer({ status: 'SENT' })).resolves.toBeDefined();
  });

  it('allows a new offer after the previous one was soft-deleted', async () => {
    await createOffer({ status: 'SENT', deletedAt: new Date() });
    await expect(createOffer({ status: 'SENT' })).resolves.toBeDefined();
  });
});

describe('stores', () => {
  it('allows only one store per owner', async () => {
    await expect(
      prisma.store.create({ data: { ownerId: OWNER } }),
    ).rejects.toThrow();
  });

  it('starts as an unpublished page-step store in the food and cafe category', async () => {
    const store = await prisma.store.findUniqueOrThrow({
      where: { id: storeId },
    });
    expect(store.status).toBe('DRAFT');
    expect(store.onboardingStep).toBe('PAGE');
    expect(store.industry).toBe('FOOD_CAFE');
  });

  it('keeps one draft per store and kind', async () => {
    const data = {
      storeId,
      kind: 'CARD_NEWS' as const,
      bodyLabel: '본문',
      body: '본문',
      scenes: [],
    };
    await prisma.storeContentDraft.create({ data });
    await expect(prisma.storeContentDraft.create({ data })).rejects.toThrow();
    const other = await prisma.storeContentDraft.create({
      data: { ...data, kind: 'BLOG' },
    });
    expect(other.version).toBe(1);
    expect(other.regenerationsOnDay).toBe(0);
  });
});

describe('creator profiles', () => {
  it('allows only one profile per user and requires a region', async () => {
    const data = {
      userId: CREATOR,
      displayName: '지민',
      regionSido: '서울특별시',
    };
    await prisma.creatorProfile.create({ data });
    await expect(prisma.creatorProfile.create({ data })).rejects.toThrow();
  });
});
