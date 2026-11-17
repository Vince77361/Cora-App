import type { Collaboration, TermsVersion } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { CreatorsService } from '../creators/creators.service';
import { ProposalInboxService } from './proposal-inbox.service';
import { TermsService } from './terms.service';

const BRAND = '11111111-1111-4111-8111-111111111111';
const ME_CREATOR = '22222222-2222-4222-8222-222222222222';
const NOON = new Date('2026-11-11T03:00:00.000Z');

function collaboration(
  id: string,
  over: Partial<Collaboration>,
): Collaboration {
  return {
    id,
    kind: 'BRAND_CONTRACT',
    stage: 'MATCHED',
    commissionerId: BRAND,
    creatorId: ME_CREATOR,
    dropReason: null,
    droppedById: null,
    createdAt: NOON,
    updatedAt: NOON,
    ...over,
  } as Collaboration;
}

function version(collaborationId: string): TermsVersion {
  return {
    collaborationId,
    version: 1,
    proposedById: null,
    format: 'REELS',
    pieces: 1,
    brandConfirmedAt: null,
    creatorConfirmedAt: null,
    createdAt: NOON,
    updatedAt: NOON,
  } as TermsVersion;
}

// 읽은 횟수를 세는 손 구현. 상대 프로필을 줄마다 읽지 않고 종류별로 한 번에 읽는지 본다.
class FakeCollaborations {
  constructor(private readonly rows: Collaboration[]) {}
  listBrandContractsForInbox(): Promise<Collaboration[]> {
    return Promise.resolve(this.rows);
  }
}
class FakeTerms {
  constructor(private readonly ids: string[]) {}
  latestMany(): Promise<Map<string, TermsVersion>> {
    return Promise.resolve(new Map(this.ids.map((id) => [id, version(id)])));
  }
}
class FakeBrands {
  profileReads = 0;
  findProfiles(ids: string[]) {
    this.profileReads += 1;
    return Promise.resolve(
      new Map(ids.map((id) => [id, { name: '느린결', photoUrl: null }])),
    );
  }
}
class FakeCreators {
  summaryReads = 0;
  singleReads = 0;
  getSummaries(ids: string[]) {
    this.summaryReads += 1;
    return Promise.resolve(
      new Map(
        ids.map((id) => [
          id,
          { displayName: `크리에이터 ${id}`, photoUrl: null },
        ]),
      ),
    );
  }
  getSummary() {
    this.singleReads += 1;
    return Promise.resolve(null);
  }
}

describe('ProposalInboxService', () => {
  function build(rows: Collaboration[]) {
    const brands = new FakeBrands();
    const creators = new FakeCreators();
    const service = new ProposalInboxService(
      new FakeCollaborations(rows) as unknown as CollaborationsRepository,
      new FakeTerms(rows.map((r) => r.id)) as unknown as TermsService,
      brands as unknown as BrandsService,
      creators as unknown as CreatorsService,
    );
    return { service, brands, creators };
  }

  it('reads the creator profiles of many rows in one read when a brand lists', async () => {
    const creatorIds = [
      '33333333-3333-4333-8333-333333333333',
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
    ];
    const { service, brands, creators } = build(
      creatorIds.map((creatorId, i) => collaboration(`c${i}`, { creatorId })),
    );
    const rows = await service.list(BRAND);
    expect(rows).toHaveLength(3);
    expect(rows.map((r) => r.counterpart.name).sort()).toEqual(
      creatorIds.map((id) => `크리에이터 ${id}`).sort(),
    );
    expect(creators.summaryReads).toBe(1);
    expect(creators.singleReads).toBe(0);
    expect(brands.profileReads).toBe(0);
  });

  it('reads the brand profiles of many rows in one read when a creator lists', async () => {
    const brandIds = [
      '66666666-6666-4666-8666-666666666666',
      '77777777-7777-4777-8777-777777777777',
    ];
    const { service, brands, creators } = build(
      brandIds.map((commissionerId, i) =>
        collaboration(`c${i}`, { commissionerId }),
      ),
    );
    expect(await service.list(ME_CREATOR)).toHaveLength(2);
    expect(brands.profileReads).toBe(1);
    expect(creators.summaryReads).toBe(0);
    expect(creators.singleReads).toBe(0);
  });
});
