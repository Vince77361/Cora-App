import type { Prisma } from '@prisma/client';
import { prisma } from './setup-db';

const BRAND = '66666666-6666-4666-8666-666666666661';
const BRAND_2 = '66666666-6666-4666-8666-666666666662';
const CREATOR = '66666666-6666-4666-8666-666666666663';
const CREATOR_2 = '66666666-6666-4666-8666-666666666664';
const STORE_OWNER = '66666666-6666-4666-8666-666666666665';
const STORE_OWNER_2 = '66666666-6666-4666-8666-666666666666';

// 거절 이유까지 확인한다. 아무 오류나 통과하면 검증 오류나 외래 키 오류로도 테스트가 통과해 버린다.
// 유일 제약 위반은 Prisma가 P2002와 위반한 인덱스의 열(meta.target)로 알려 준다.
function uniqueOn(...columns: string[]) {
  return { code: 'P2002', meta: { target: columns } };
}
// CHECK 위반은 Prisma가 코드 있는 오류로 바꾸지 않아, Postgres의 문장에 든 제약 이름으로 가린다.
// 오류 문장 안에서 따옴표가 \"로 이스케이프되어 있어 백슬래시는 있어도 없어도 맞게 한다.
function violatesCheck(name: string): RegExp {
  return new RegExp(`violates check constraint \\\\?"${name}\\\\?"`);
}

beforeEach(async () => {
  // 각 테스트 전에 setup-db가 모든 테이블을 비우므로 기준 데이터를 여기서 다시 만든다.
  await prisma.user.createMany({
    data: [
      { id: BRAND, role: 'BRAND' },
      { id: BRAND_2, role: 'BRAND' },
      { id: CREATOR, role: 'CREATOR' },
      { id: CREATOR_2, role: 'CREATOR' },
      { id: STORE_OWNER, role: 'STORE' },
      { id: STORE_OWNER_2, role: 'STORE' },
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
    await expect(createCampaign()).rejects.toMatchObject(uniqueOn('brand_id'));
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
    // Prisma 클라이언트는 budget이 없으면 DB에 가기 전에 막으므로, NOT NULL은 직접 INSERT로 확인한다.
    const insert = (budget: number | null) => prisma.$executeRaw`
      INSERT INTO campaigns (
        id, brand_id, status, headline, fee, budget, product_provided, format,
        start_from, trial_days, must_include, not_required, updated_at
      ) VALUES (
        gen_random_uuid(), ${BRAND}::uuid, 'CLOSED', '예산 없음', 300000,
        ${budget}, false, 'REELS', '2026-12-01', 'ANY', ARRAY[]::text[],
        ARRAY[]::not_required[], now())`;
    // 예산만 다른 같은 INSERT가 성공하니, 거절 이유는 budget이 비어서다(23502는 NOT NULL 위반).
    await expect(insert(300000)).resolves.toBe(1);
    await expect(insert(null)).rejects.toMatchObject({
      code: 'P2010',
      meta: { code: '23502' },
    });
  });

  it('keeps the budget in 10,000 won steps from the fee up to 100,000,000', async () => {
    const budgetRange = violatesCheck('campaigns_budget_range');
    await expect(createCampaign({ budget: 299999 })).rejects.toThrow(
      budgetRange,
    );
    await expect(createCampaign({ budget: 305000 })).rejects.toThrow(
      budgetRange,
    );
    await expect(createCampaign({ budget: 100010000 })).rejects.toThrow(
      budgetRange,
    );
    await expect(createCampaign({ budget: 300000 })).resolves.toBeDefined();
  });

  it('keeps at most three must-include lines', async () => {
    await expect(
      createCampaign({ brandId: BRAND_2, mustInclude: ['a', 'b', 'c', 'd'] }),
    ).rejects.toThrow(violatesCheck('campaigns_must_include_max'));
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
    ).rejects.toMatchObject(uniqueOn('actor_id', 'target_kind', 'target_id'));

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
    ).rejects.toMatchObject(
      uniqueOn('actor_id', 'target_kind', 'target_id', 'campaign_id'),
    );
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

  it('keeps one store decision per creator with campaign null and keeps stores apart', async () => {
    // 사장님의 결정은 캠페인이 없다(campaign_id IS NULL). 부분 유니크 인덱스가 가게마다 크리에이터 하나에 결정 하나로 막는다.
    const store = {
      actorId: STORE_OWNER,
      targetKind: 'CREATOR' as const,
      targetId: CREATOR,
      campaignId: null,
    };
    await prisma.swipeDecision.create({
      data: { ...store, decision: 'HOLD' },
    });
    await expect(
      prisma.swipeDecision.create({ data: { ...store, decision: 'LIKE' } }),
    ).rejects.toMatchObject(uniqueOn('actor_id', 'target_kind', 'target_id'));
    // 다른 가게는 같은 크리에이터에게 따로 결정한다.
    await expect(
      prisma.swipeDecision.create({
        data: { ...store, actorId: STORE_OWNER_2, decision: 'LIKE' },
      }),
    ).resolves.toBeDefined();
    // 사장님의 결정은 서로 관심(matches)을 만들지 않는다.
    expect(await prisma.match.count()).toBe(0);
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

  it('rejects a brand proposal that has only the performance rate or only the cap', async () => {
    const campaign = await createCampaign();
    const pair = violatesCheck('swipe_decisions_proposed_perf_pair');
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, campaignId: campaign.id, proposedPerfRate: 2000 },
      }),
    ).rejects.toThrow(pair);
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, campaignId: campaign.id, proposedPerfCap: 100000 },
      }),
    ).rejects.toThrow(pair);
    // 둘 다 없으면 된다(조건 없이 좋아요만 한 경우).
    await expect(
      prisma.swipeDecision.create({
        data: { ...base, campaignId: campaign.id },
      }),
    ).resolves.toBeDefined();
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
    ).rejects.toMatchObject(uniqueOn('campaign_id', 'creator_id'));
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
    ).rejects.toMatchObject(uniqueOn('collaboration_id'));
  });
});

describe('collaborations of a brand campaign', () => {
  it('rejects a second brand collaboration for the same campaign and creator', async () => {
    const campaign = await createCampaign();
    await createBrandCollaboration(campaign.id);
    await expect(createBrandCollaboration(campaign.id)).rejects.toMatchObject(
      uniqueOn('campaign_id', 'creator_id'),
    );
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

  it('keeps one store recommendation row per store owner and day', async () => {
    const make = (day: Date) =>
      prisma.dailyRecommendation.create({
        data: {
          userId: STORE_OWNER,
          scope: 'STORE',
          campaignId: null,
          day,
          items,
        },
      });
    await make(day);
    await expect(make(day)).rejects.toMatchObject(
      uniqueOn('user_id', 'scope', 'day'),
    );
    await expect(make(new Date('2026-12-02'))).resolves.toBeDefined();
  });

  it('keeps one recommendation row per user, scope, campaign and day', async () => {
    const make = (campaignId: string | null, scope: 'BRAND' | 'CREATOR') =>
      prisma.dailyRecommendation.create({
        data: { userId: BRAND, scope, campaignId, day, items },
      });
    // 캠페인이 없는 줄(크리에이터 쪽 추천)은 NULL이라 부분 유니크 인덱스로 막는다.
    await make(null, 'CREATOR');
    await expect(make(null, 'CREATOR')).rejects.toMatchObject(
      uniqueOn('user_id', 'scope', 'day'),
    );

    const campaign = await createCampaign();
    await make(campaign.id, 'BRAND');
    await expect(make(campaign.id, 'BRAND')).rejects.toMatchObject(
      uniqueOn('user_id', 'scope', 'campaign_id', 'day'),
    );
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
    await expect(
      prisma.creatorPrinciples.create({ data }),
    ).rejects.toMatchObject(uniqueOn('creator_id'));
  });

  it('keeps one brand profile per user', async () => {
    const data = {
      userId: BRAND,
      name: '모닝브루',
      industry: 'FOOD_CAFE' as const,
    };
    await prisma.brandProfile.create({ data });
    await expect(prisma.brandProfile.create({ data })).rejects.toMatchObject(
      uniqueOn('user_id'),
    );
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
    const pair = violatesCheck('terms_versions_perf_pair');
    await expect(version({ perfRatePerThousand: 2000 })).rejects.toThrow(pair);
    await expect(version({ perfCap: 100000 })).rejects.toThrow(pair);
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
    ).rejects.toMatchObject(uniqueOn('collaboration_id', 'version'));
  });

  it('accepts only 7 or 14 payout days', async () => {
    await expect(version({ payoutDays: 10 })).rejects.toThrow(
      violatesCheck('terms_versions_payout_days'),
    );
    await expect(version({ payoutDays: 14 })).resolves.toBeDefined();
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
