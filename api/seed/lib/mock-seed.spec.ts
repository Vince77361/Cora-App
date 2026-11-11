import { SIDO_LIST } from '../../src/common/regions';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { DEV_ACCOUNTS } from './dev-accounts';
import { runMockSeed } from './mock-seed';
import {
  MockApplicationData,
  MockCreatorProfileData,
  MockOfferData,
  MockSeedDb,
  MockSourceLinkData,
  MockStoreData,
} from './mock-seed-db';

const DAY_MS = 24 * 60 * 60 * 1000;
const NOW = new Date('2026-11-12T05:00:00.000Z');
const STORE_ID = 'store-1';

// 손으로 쓴 가짜. 목업이 아닌 계정의 행(other*)을 미리 넣어 두고 시드가 건드리는지 본다.
class FakeMockSeedDb implements MockSeedDb {
  readonly profiles = new Map<string, MockCreatorProfileData>();
  stores = new Map<string, MockStoreData>();
  links: MockSourceLinkData[] = [];
  applications: (MockApplicationData & { storeId: string })[] = [];
  offers: (MockOfferData & { storeId: string })[] = [];

  upsertCreatorProfile(
    userId: string,
    data: MockCreatorProfileData,
  ): Promise<void> {
    this.profiles.set(userId, data);
    return Promise.resolve();
  }

  upsertStore(
    ownerId: string,
    data: MockStoreData,
    links: MockSourceLinkData[],
  ): Promise<{ storeId: string }> {
    this.stores.set(ownerId, data);
    this.links = links;
    return Promise.resolve({ storeId: STORE_ID });
  }

  resetCollaboration(input: {
    storeId: string;
    mockCreatorIds: string[];
    applications: MockApplicationData[];
    offers: MockOfferData[];
  }): Promise<void> {
    const inScope = (r: { storeId: string; creatorId: string }) =>
      r.storeId === input.storeId || input.mockCreatorIds.includes(r.creatorId);
    this.applications = this.applications.filter((r) => !inScope(r));
    this.offers = this.offers.filter((r) => !inScope(r));
    for (const a of input.applications) {
      this.applications.push({ ...a, storeId: input.storeId });
    }
    for (const o of input.offers) {
      this.offers.push({ ...o, storeId: input.storeId });
    }
    return Promise.resolve();
  }
}

const accountIds = new Map(
  DEV_ACCOUNTS.map((a, i) => [
    a.phone,
    `00000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`,
  ]),
);
const idOf = (phone: string) => accountIds.get(phone) as string;

function setup() {
  const db = new FakeMockSeedDb();
  const storage = new FakeStoragePort();
  const lines: string[] = [];
  const run = () =>
    runMockSeed(
      { db, storage, clock: new FakeClock(NOW), log: (l) => lines.push(l) },
      accountIds,
    );
  return { db, storage, lines, run };
}

describe('runMockSeed', () => {
  it('writes the five creator profiles from the canvas values', async () => {
    const { db, run } = setup();

    await run();

    expect(db.profiles.size).toBe(5);
    expect(db.profiles.get(idOf('010-0000-0003'))).toMatchObject({
      displayName: '서윤의 작은 취향',
      contentFocus: null,
      instagramHandle: 'seoyun.objects',
    });
    expect(db.profiles.get(idOf('010-0000-0004'))).toMatchObject({
      displayName: '하루 한 컵',
      contentFocus: '리빙 릴스',
      instagramHandle: 'onecup.day',
    });
    expect(db.profiles.get(idOf('010-0000-0005'))).toMatchObject({
      displayName: '성수 한 끼',
      contentFocus: '맛집 릴스',
      photoPath: null,
    });
    expect(db.profiles.get(idOf('010-0000-0006'))).toMatchObject({
      displayName: '면치기 일기',
      contentFocus: '라멘 리뷰',
      photoPath: null,
    });
    expect(db.profiles.get(idOf('010-0000-0007'))).toMatchObject({
      displayName: '민의 옷장 기록',
      contentFocus: null,
    });
    for (const p of db.profiles.values()) {
      expect(p.regionSido).toBe(SIDO_LIST[0]);
      expect(p.regionSigungu).toBeNull();
    }
  });

  it('uploads photos under creators/<id> and stores/<id> and stores those paths', async () => {
    const { db, storage, run } = setup();

    await run();

    const seoyun = idOf('010-0000-0003');
    const owner = idOf('010-0000-0001');
    expect(db.profiles.get(seoyun)?.photoPath).toBe(
      `creators/${seoyun}/seed-profile.jpg`,
    );
    expect(db.stores.get(owner)?.coverPhotoPath).toBe(
      `stores/${owner}/seed-cover.png`,
    );
    // 사진이 있는 크리에이터 3명 + 가게 사진 1장.
    expect(storage.uploaded.map((u) => u.path).sort()).toEqual(
      [
        `creators/${idOf('010-0000-0003')}/seed-profile.jpg`,
        `creators/${idOf('010-0000-0004')}/seed-profile.png`,
        `creators/${idOf('010-0000-0007')}/seed-profile.jpg`,
        `stores/${owner}/seed-cover.png`,
      ].sort(),
    );
    expect(storage.uploaded.every((u) => u.bytes.length > 0)).toBe(true);
  });

  it('publishes the ramen store with the default reels voucher-plus-views terms', async () => {
    const { db, run } = setup();

    await run();

    expect(db.stores.get(idOf('010-0000-0001'))).toMatchObject({
      name: '한그릇 라멘',
      category: '라멘집',
      neighborhood: '성수동',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      signatureMenu: '돈코츠 라멘 11,000원',
      defaultFormat: 'REELS',
      defaultRewardType: 'BOTH',
      defaultVoucherName: '2인 식사권',
      defaultVoucherValue: 40000,
      publishedAt: NOW,
    });
    expect(db.links.map((l) => [l.kind, l.summary])).toEqual([
      ['NAVER_MAP', '사진 12장, 메뉴 8개 찾음'],
      ['CATCHTABLE', '영업시간 찾음'],
    ]);
    expect(db.links[0].url.startsWith('https://naver.me/')).toBe(true);
  });

  it('adds the three applicants dated today, yesterday and two days ago', async () => {
    const { db, run } = setup();

    await run();

    expect(db.applications).toEqual([
      {
        storeId: STORE_ID,
        creatorId: idOf('010-0000-0004'),
        createdAt: NOW,
      },
      {
        storeId: STORE_ID,
        creatorId: idOf('010-0000-0005'),
        createdAt: new Date(NOW.getTime() - DAY_MS),
      },
      {
        storeId: STORE_ID,
        creatorId: idOf('010-0000-0006'),
        createdAt: new Date(NOW.getTime() - 2 * DAY_MS),
      },
    ]);
  });

  it('adds one declined offer to min that is past the 30 second undo window', async () => {
    const { db, run } = setup();

    await run();

    expect(db.offers).toHaveLength(1);
    const [offer] = db.offers;
    expect(offer).toMatchObject({
      creatorId: idOf('010-0000-0007'),
      format: 'REELS',
      rewardType: 'BOTH',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: 10,
      perViewCap: 100000,
    });
    expect(NOW.getTime() - offer.declinedAt.getTime()).toBeGreaterThan(30_000);
    // 오퍼 사본은 아직 기한 안에 거절된 것으로 모순이 없어야 한다.
    expect(offer.declinedAt.getTime()).toBeLessThan(offer.expiresAt.getTime());
    expect(offer.createdAt.getTime()).toBeLessThan(offer.declinedAt.getTime());
  });

  it('gives creator 0003 no applications or offers', async () => {
    const { db, run } = setup();

    await run();

    const seoyun = idOf('010-0000-0003');
    expect(db.applications.some((a) => a.creatorId === seoyun)).toBe(false);
    expect(db.offers.some((o) => o.creatorId === seoyun)).toBe(false);
  });

  it('gives the same rows when run twice and drops rows made during a demo', async () => {
    const { db, run } = setup();
    await run();
    const first = JSON.stringify([db.applications, db.offers]);
    // 시연 중 0001이 서윤에게 보낸 오퍼와 서윤의 지원.
    db.applications.push({
      storeId: STORE_ID,
      creatorId: idOf('010-0000-0003'),
      createdAt: NOW,
    });

    await run();

    expect(JSON.stringify([db.applications, db.offers])).toBe(first);
  });

  it('leaves rows of other accounts untouched', async () => {
    const { db, run } = setup();
    db.applications.push({
      storeId: 'other-store',
      creatorId: 'other-creator',
      createdAt: NOW,
    });

    await run();

    expect(
      db.applications.filter((a) => a.storeId === 'other-store'),
    ).toHaveLength(1);
  });

  it('logs only last four digits and counts', async () => {
    const { lines, run } = setup();

    await run();

    expect(lines.length).toBeGreaterThan(0);
    for (const line of lines) {
      expect(line).not.toMatch(/010|@|cora-dev-only|[0-9a-f]{8}-|supabase/);
    }
  });
});
