import type { Prisma } from '@prisma/client';
import { prisma } from './setup-db';

const BRAND = '66666666-6666-4666-8666-666666666661';
const BRAND_2 = '66666666-6666-4666-8666-666666666662';
const CREATOR = '66666666-6666-4666-8666-666666666663';
const CREATOR_2 = '66666666-6666-4666-8666-666666666664';

beforeEach(async () => {
  // 각 테스트 전에 setup-db가 모든 테이블을 비우므로 기준 데이터를 여기서 다시 만든다.
  await prisma.user.createMany({
    data: [
      { id: BRAND, role: 'BRAND' },
      { id: BRAND_2, role: 'BRAND' },
      { id: CREATOR, role: 'CREATOR' },
      { id: CREATOR_2, role: 'CREATOR' },
    ],
  });
});

function createCampaign(
  over: Partial<Prisma.CampaignUncheckedCreateInput> = {},
) {
  return prisma.campaign.create({
    data: {
      brandId: BRAND,
      status: 'ACTIVE',
      headline: '여름 신상 릴스 제작',
      fee: 300000,
      budget: 1000000,
      productProvided: true,
      format: 'REELS',
      startFrom: new Date('2026-12-01'),
      trialDays: 'D7',
      mustInclude: ['제품 사용 장면'],
      notRequired: ['FACE'],
      ...over,
    },
  });
}

async function createBrandCollaboration(
  campaignId: string,
  creatorId = CREATOR,
) {
  return prisma.collaboration.create({
    data: {
      kind: 'BRAND_CONTRACT',
      stage: 'MATCHED',
      commissionerId: BRAND,
      creatorId,
      campaignId,
      terms: {},
      settlementMethod: 'FIXED',
    },
  });
}

describe('campaigns', () => {
  it('allows only one active campaign per brand', async () => {
    await createCampaign();
    await expect(createCampaign()).rejects.toThrow();
    // 다른 브랜드는 영향이 없다.
    await expect(createCampaign({ brandId: BRAND_2 })).resolves.toBeDefined();
  });

  it('allows a new campaign after the previous one is closed', async () => {
    const first = await createCampaign();
    await prisma.campaign.update({
      where: { id: first.id },
      data: { status: 'CLOSED' },
    });
    await expect(createCampaign()).resolves.toBeDefined();
    // 닫힌 캠페인은 여러 개여도 된다.
    await createCampaign({ status: 'CLOSED' });
    expect(await prisma.campaign.count({ where: { brandId: BRAND } })).toBe(3);
  });

  it('ignores a deleted active campaign in the one-active rule', async () => {
    await createCampaign({ deletedAt: new Date() });
    await expect(createCampaign()).resolves.toBeDefined();
  });

  it('requires a campaign budget', async () => {
    const data = {
      brandId: BRAND,
      headline: '예산 없음',
      fee: 300000,
      productProvided: false,
      format: 'REELS',
      startFrom: new Date('2026-12-01'),
      trialDays: 'ANY',
    };
    // 타입을 우회해 budget 없이 넣어 본다. NOT NULL이라 거절돼야 한다.
    await expect(
      prisma.campaign.create({
        data: data as unknown as Prisma.CampaignUncheckedCreateInput,
      }),
    ).rejects.toThrow();
  });

  it('keeps the budget in 10,000 won steps from the fee up to 100,000,000', async () => {
    await expect(createCampaign({ budget: 299999 })).rejects.toThrow();
    await expect(createCampaign({ budget: 305000 })).rejects.toThrow();
    await expect(createCampaign({ budget: 100010000 })).rejects.toThrow();
    await expect(createCampaign({ budget: 300000 })).resolves.toBeDefined();
  });

  it('keeps at most three must-include lines', async () => {
    await expect(
      createCampaign({ brandId: BRAND_2, mustInclude: ['a', 'b', 'c', 'd'] }),
    ).rejects.toThrow();
    await expect(
      createCampaign({ brandId: BRAND_2, mustInclude: ['a', 'b', 'c'] }),
    ).resolves.toBeDefined();
  });
});

describe('swipe_decisions', () => {
  const base = {
    actorId: BRAND,
    targetKind: 'CREATOR' as const,
    targetId: CREATOR,
    decision: 'LIKE' as const,
  };

  it('keeps one decision per actor, target and campaign', async () => {
    // 캠페인이 없는 결정(크리에이터 → 가게 등)은 NULL이라 일반 유니크로는 중복을 못 막는다.
    await prisma.swipeDecision.create({ data: { ...base, campaignId: null } });
    await expect(
      prisma.swipeDecision.create({ data: { ...base, campaignId: null } }),
    ).rejects.toThrow();

    // 캠페인이 있는 결정은 같은 캠페인에서만 겹친다.
    const campaign = await createCampaign();
    const other = await createCampaign({ brandId: BRAND_2 });
    await prisma.swipeDecision.create({
      data: { ...base, campaignId: campaign.id },
    });
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, campaignId: campaign.id },
      }),
    ).rejects.toThrow();
    // 같은 대상이라도 다른 캠페인이거나 캠페인이 없으면 따로 센다.
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, actorId: BRAND_2, campaignId: other.id },
      }),
    ).resolves.toBeDefined();
    // 다른 대상은 겹치지 않는다.
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, targetId: CREATOR_2, campaignId: campaign.id },
      }),
    ).resolves.toBeDefined();
  });

  it('keeps the brand proposal amounts on a like decision', async () => {
    const campaign = await createCampaign();
    const row = await prisma.swipeDecision.create({
      data: {
        ...base,
        campaignId: campaign.id,
        note: '릴스 톤이 좋아요',
        proposedFee: 350000,
        proposedProductProvided: true,
        proposedPerfRate: 2000,
        proposedPerfCap: 100000,
      },
    });
    expect(row).toMatchObject({
      decision: 'LIKE',
      proposedFee: 350000,
      proposedProductProvided: true,
      proposedPerfRate: 2000,
      proposedPerfCap: 100000,
      passReason: null,
    });
  });

  it('stores a pass reason and allows none', async () => {
    await prisma.swipeDecision.create({
      data: { ...base, decision: 'PASS', passReason: 'MOOD', campaignId: null },
    });
    const none = await prisma.swipeDecision.create({
      data: {
        ...base,
        targetId: CREATOR_2,
        decision: 'PASS',
        campaignId: null,
      },
    });
    expect(none.passReason).toBeNull();
  });
});

describe('matches', () => {
  it('rejects a second match for the same campaign and creator', async () => {
    const campaign = await createCampaign();
    const first = await createBrandCollaboration(campaign.id);
    await prisma.match.create({
      data: {
        campaignId: campaign.id,
        creatorId: CREATOR,
        collaborationId: first.id,
        matchedAt: new Date('2026-12-01T00:00:00Z'),
      },
    });
    const second = await createBrandCollaboration(campaign.id, CREATOR_2);
    await expect(
      prisma.match.create({
        data: {
          campaignId: campaign.id,
          creatorId: CREATOR,
          collaborationId: second.id,
          matchedAt: new Date('2026-12-01T00:00:00Z'),
        },
      }),
    ).rejects.toThrow();
    // 한 협업에는 매칭이 하나뿐이다.
    await expect(
      prisma.match.create({
        data: {
          campaignId: campaign.id,
          creatorId: CREATOR_2,
          collaborationId: first.id,
          matchedAt: new Date('2026-12-01T00:00:00Z'),
        },
      }),
    ).rejects.toThrow();
  });
});

describe('collaborations of a brand campaign', () => {
  it('rejects a second brand collaboration for the same campaign and creator', async () => {
    const campaign = await createCampaign();
    await createBrandCollaboration(campaign.id);
    await expect(createBrandCollaboration(campaign.id)).rejects.toThrow();
    // 같은 캠페인의 다른 크리에이터는 된다.
    await expect(
      createBrandCollaboration(campaign.id, CREATOR_2),
    ).resolves.toBeDefined();
  });

  it('keeps campaign-less collaborations free of the brand rule', async () => {
    const store = await prisma.store.create({ data: { ownerId: BRAND_2 } });
    const make = () =>
      prisma.collaboration.create({
        data: {
          kind: 'STORE_OFFER',
          stage: 'AWAITING_PAYMENT',
          commissionerId: BRAND_2,
          creatorId: CREATOR,
          storeId: store.id,
          terms: {},
          settlementMethod: 'FIXED',
        },
      });
    await make();
    await expect(make()).resolves.toBeDefined();
  });
});

describe('daily_recommendations', () => {
  const day = new Date('2026-12-01');
  const items = [{ kind: 'CREATOR', id: CREATOR }];

  it('keeps one recommendation row per user, scope, campaign and day', async () => {
    const make = (campaignId: string | null, scope: 'BRAND' | 'CREATOR') =>
      prisma.dailyRecommendation.create({
        data: { userId: BRAND, scope, campaignId, day, items },
      });
    // 캠페인이 없는 줄(크리에이터 쪽 추천)은 NULL이라 부분 유니크 인덱스로 막는다.
    await make(null, 'CREATOR');
    await expect(make(null, 'CREATOR')).rejects.toThrow();

    const campaign = await createCampaign();
    await make(campaign.id, 'BRAND');
    await expect(make(campaign.id, 'BRAND')).rejects.toThrow();
    // 날짜가 다르면 새 줄이다.
    await expect(
      prisma.dailyRecommendation.create({
        data: {
          userId: BRAND,
          scope: 'BRAND',
          campaignId: campaign.id,
          day: new Date('2026-12-02'),
          items,
        },
      }),
    ).resolves.toBeDefined();
  });
});

describe('creator_principles and brand_profiles', () => {
  it('keeps one principles row per creator', async () => {
    const data = {
      creatorId: CREATOR,
      fields: ['FOOD_CAFE' as const],
      blockedIndustries: ['ALCOHOL' as const],
      faceOk: true,
      scriptOk: false,
      honestReview: true,
      feeBand: 'W300K' as const,
      trialDays: 'D7' as const,
    };
    await prisma.creatorPrinciples.create({ data });
    await expect(prisma.creatorPrinciples.create({ data })).rejects.toThrow();
  });

  it('keeps one brand profile per user', async () => {
    const data = {
      userId: BRAND,
      name: '모닝브루',
      industry: 'FOOD_CAFE' as const,
    };
    await prisma.brandProfile.create({ data });
    await expect(prisma.brandProfile.create({ data })).rejects.toThrow();
  });
});

describe('creator_profiles card fields', () => {
  it('saves the card headline and photo on the creator profile', async () => {
    const row = await prisma.creatorProfile.create({
      data: {
        userId: CREATOR,
        displayName: '민지',
        regionSido: '서울특별시',
        cardHeadline: '카페 릴스 전문',
        cardPhotoPath: `creator-cards/${CREATOR}/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg`,
      },
    });
    expect(row.cardHeadline).toBe('카페 릴스 전문');
    expect(row.cardPhotoPath).toContain('creator-cards/');
  });
});

describe('terms_versions', () => {
  async function version(
    over: Partial<Prisma.TermsVersionUncheckedCreateInput> = {},
  ) {
    // 한 테스트에서 여러 번 불러도 같은 협업에 붙게, 있으면 다시 쓴다. 번호는 새로 매긴다.
    const collaboration =
      (await prisma.collaboration.findFirst()) ??
      (await createBrandCollaboration((await createCampaign()).id));
    const version = (await prisma.termsVersion.count()) + 1;
    return prisma.termsVersion.create({
      data: {
        collaborationId: collaboration.id,
        version,
        title: '여름 신상 릴스',
        fee: 300000,
        startDate: new Date('2026-12-01'),
        format: 'REELS',
        pieces: 1,
        productProvided: true,
        revisionScope: 'DRAFT_1',
        usageRights: 'REPOST_ONLY',
        payoutDays: 7,
        ...over,
      },
    });
  }

  it('stores a performance bonus on a terms version only as a rate and cap pair', async () => {
    await expect(version({ perfRatePerThousand: 2000 })).rejects.toThrow();
    await expect(version({ perfCap: 100000 })).rejects.toThrow();
    const both = await version({
      perfRatePerThousand: 2000,
      perfCap: 100000,
    });
    expect(both).toMatchObject({ perfRatePerThousand: 2000, perfCap: 100000 });
  });

  it('allows a version without a performance bonus', async () => {
    const row = await version();
    expect(row).toMatchObject({
      perfRatePerThousand: null,
      perfCap: null,
      proposedById: null,
      brandConfirmedAt: null,
      creatorConfirmedAt: null,
    });
  });

  it('keeps one row per collaboration and version number', async () => {
    const first = await version();
    await expect(
      prisma.termsVersion.create({
        data: {
          collaborationId: first.collaborationId,
          version: 1,
          title: '같은 번호',
          fee: 300000,
          startDate: new Date('2026-12-01'),
          format: 'REELS',
          pieces: 1,
          productProvided: true,
          revisionScope: 'NONE',
          usageRights: 'NONE',
          payoutDays: 14,
        },
      }),
    ).rejects.toThrow();
  });

  it('accepts only 7 or 14 payout days', async () => {
    await expect(version({ payoutDays: 10 })).rejects.toThrow();
  });
});

describe('row level security', () => {
  it('has row level security on the new tables', async () => {
    const rows = await prisma.$queryRaw<{ relname: string }[]>`
      SELECT c.relname FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = current_schema() AND c.relkind = 'r'
        AND c.relrowsecurity
        AND c.relname IN (
          'creator_principles', 'brand_profiles', 'campaigns',
          'swipe_decisions', 'matches', 'daily_recommendations',
          'terms_versions')`;
    expect(rows).toHaveLength(7);
  });
});
