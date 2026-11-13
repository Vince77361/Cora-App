import { balances, assertBalanced } from '../../src/ledger/ledger-postings';
import { SIDO_LIST } from '../../src/common/regions';
import { endKind, proposalGroup } from '../../src/offers/proposal-rules';
import { readTerms } from '../../src/stores/reward-terms';
import { FakeClock } from '../../test/support/fake-clock';
import { FakeStoragePort } from '../../test/support/fake-storage.port';
import { DEV_ACCOUNTS } from './dev-accounts';
import { runMockSeed } from './mock-seed';
import {
  MockApplicationData,
  MockCreatorProfileData,
  MockOfferData,
  MockSeedDb,
  MockSeriesData,
  MockSourceLinkData,
  MockStoreData,
  MockStoreFlowInput,
  MockCollaborationData,
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
  collaborations: (MockCollaborationData & { storeId: string })[] = [];
  series: MockSeriesData[] = [];

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

  resetStoreFlow(input: MockStoreFlowInput): Promise<void> {
    const inScope = (r: { storeId: string; creatorId: string }) =>
      r.storeId === input.storeId || input.mockCreatorIds.includes(r.creatorId);
    this.applications = this.applications.filter((r) => !inScope(r));
    const goneOfferKeys = new Set(
      this.offers.filter(inScope).map((o) => o.key),
    );
    this.offers = this.offers.filter((r) => !inScope(r));
    // 지우는 오퍼에 붙은 협업만 함께 지운다.
    this.collaborations = this.collaborations.filter(
      (c) => !goneOfferKeys.has(c.offerKey),
    );
    this.series = this.series.filter(
      (r) => !input.mockCreatorIds.includes(r.creatorId),
    );
    for (const a of input.applications) {
      this.applications.push({ ...a, storeId: input.storeId });
    }
    for (const o of input.offers) {
      this.offers.push({ ...o, storeId: input.storeId });
    }
    this.collaborations.push({
      ...input.collaboration,
      storeId: input.storeId,
    });
    this.series.push(...input.series);
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

  it('seeds the sample store with the new recruit terms and a slug', async () => {
    const { db, run } = setup();

    await run();

    expect(db.stores.get(idOf('010-0000-0001'))).toMatchObject({
      name: '한그릇 라멘',
      category: '라멘집',
      neighborhood: '성수동',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      signatureMenu: '돈코츠 라멘 11,000원',
      slug: 'hangeureut-ramen',
      tags: ['진한국물', '바좌석', '조용한오후'],
      customerPhrases: ['국물이 진해요', '혼밥하기 좋아요'],
      recruitLine: '첫 숟가락 릴스',
      defaultFormat: 'REELS',
      defaultVoucherName: '식사권',
      defaultVoucherValue: 40000,
      defaultVoucherPeople: 2,
      defaultFixedCash: 0,
      defaultViewRatePerThousand: 2000,
      defaultPerViewCap: 60000,
      defaultUsageRights: 'STORE_REPOST_3M',
      trialPostCount: 9,
      trialSnoozedUntil: null,
      trialHintSeenAt: null,
      publishedAt: NOW,
    });
    expect(db.links.map((l) => [l.kind, l.summary])).toEqual([
      ['NAVER_MAP', '사진 12장, 메뉴 8개 찾음'],
      ['CATCHTABLE', '영업시간 찾음'],
      ['INSTAGRAM', null],
    ]);
    expect(db.links[0].url.startsWith('https://naver.me/')).toBe(true);
    expect(db.links[2].url.startsWith('https://www.instagram.com/')).toBe(true);
  });

  it('ends the trial contract 28 days after the seed day in Korean time', async () => {
    const { db, run } = setup();

    await run();

    // 2026-11-12 14:00 KST + 28일 = 12월 10일.
    expect(db.stores.get(idOf('010-0000-0001'))?.trialEndsOn).toEqual(
      new Date('2026-12-10T00:00:00.000Z'),
    );
  });

  it('seeds five applicants of whom three have a pitch', async () => {
    const { db, run } = setup();

    await run();

    expect(db.applications).toHaveLength(5);
    expect(
      db.applications.map((a) => [a.creatorId, a.createdAt.getTime()]),
    ).toEqual([
      [idOf('010-0000-0004'), NOW.getTime()],
      [idOf('010-0000-0005'), NOW.getTime() - DAY_MS],
      [idOf('010-0000-0006'), NOW.getTime() - 2 * DAY_MS],
      [idOf('010-0000-0007'), NOW.getTime() - 3 * DAY_MS],
      [idOf('010-0000-0003'), NOW.getTime() - 4 * DAY_MS],
    ]);
    // 캔버스 G2의 세 문장.
    expect(
      db.applications
        .filter((a) => a.pitch !== null)
        .map((a) => [a.creatorId, a.pitch]),
    ).toEqual([
      [idOf('010-0000-0004'), '김 오르는 첫 숟가락을 슬로모션으로 찍을게요'],
      [idOf('010-0000-0007'), '출근 전 라멘 한 그릇, 손만 나오게 찍을게요'],
      [idOf('010-0000-0003'), '바 좌석 18석의 조용한 오후를 담을게요'],
    ]);
  });

  it('seeds one proposal waiting for the owner and two waiting for creators', async () => {
    const { db, run } = setup();

    await run();

    // 제안함의 묶음은 서버가 쓰는 규칙 그대로 본다(사장님 쪽).
    const group = (o: MockOfferData) =>
      proposalGroup({ ...o, paymentDueAt: null }, 'STORE', NOW);
    const waitingForOwner = db.offers.filter((o) => group(o) === 'MY_TURN');
    expect(waitingForOwner).toHaveLength(1);
    expect(waitingForOwner[0]).toMatchObject({
      creatorId: idOf('010-0000-0004'),
      turn: 'STORE',
      status: 'SENT',
    });
    // 역제안: 판본 2는 크리에이터가 쓴 카드뉴스 1편이다.
    expect(waitingForOwner[0].versions.map((v) => v.number)).toEqual([1, 2]);
    expect(waitingForOwner[0].versions[1]).toMatchObject({
      authorParty: 'CREATOR',
      format: 'CARD_NEWS',
      pieces: 1,
      fixedCash: 30000,
      principles: ['#얼굴출연없음'],
      series: { name: '동네 점심 지도', format: 'CARD_NEWS' },
    });
    const waitingForCreators = db.offers.filter((o) => group(o) === 'WAITING');
    expect(waitingForCreators.map((o) => o.creatorId).sort()).toEqual(
      [idOf('010-0000-0003'), idOf('010-0000-0007')].sort(),
    );
    expect(waitingForCreators.every((o) => o.turn === 'CREATOR')).toBe(true);
  });

  it('seeds two ended proposals, one agreed and one ended for schedule', async () => {
    const { db, run } = setup();

    await run();

    const ended = db.offers.filter(
      (o) =>
        proposalGroup({ ...o, paymentDueAt: null }, 'STORE', NOW) === 'ENDED',
    );
    expect(ended).toHaveLength(2);
    expect(
      ended
        .map((o) => [endKind({ ...o, paymentDueAt: null }, NOW), o.endReason])
        .sort(),
    ).toEqual([
      ['AGREED', null],
      ['ENDED', 'SCHEDULE'],
    ]);
    // 거절한 제안은 30초 되돌리기 시간이 지나 사장님에게 이미 거절로 보인다.
    const declined = ended.find((o) => o.status === 'DECLINED');
    expect(
      NOW.getTime() - (declined?.declinedAt as Date).getTime(),
    ).toBeGreaterThan(30_000);
  });

  it('keeps at most one open proposal per creator so the unique index holds', async () => {
    const { db, run } = setup();

    await run();

    const open = db.offers.filter(
      (o) => o.status === 'SENT' || (o.status === 'ACCEPTED' && !o.closedAt),
    );
    const creators = open.map((o) => o.creatorId);
    expect(new Set(creators).size).toBe(creators.length);
    // 지원이 하나뿐이어야 하는 것도 같다.
    const applicants = db.applications.map((a) => a.creatorId);
    expect(new Set(applicants).size).toBe(applicants.length);
  });

  it('seeds a confirmed settlement of 12500 views with a balanced ledger', async () => {
    const { db, run } = setup();

    await run();

    expect(db.collaborations).toHaveLength(1);
    const [c] = db.collaborations;
    expect(c.creatorId).toBe(idOf('010-0000-0004'));
    expect(c.settlement).toMatchObject({
      finalViews: 12500,
      payoutAmount: 25000,
      refundAmount: 35000,
      status: 'CONFIRMED',
      fixedCashAmount: 0,
      viewPayAmount: 25000,
      confirmedBy: 'AUTO',
      usualViews: 4000,
      multiplierTenths: 31,
    });
    expect(c.payout.amount).toBe(25000);
    expect(c.refund.amount).toBe(35000);
    // 조건 사본은 서버가 읽는 모양이고, 협업은 가장 새 판본이 아니라 수락된 판본 1의 조건이다.
    expect(readTerms(c.terms)).toMatchObject({
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
      settlementMethod: 'PER_VIEW',
    });
    // 7일째 조회수가 최종 조회수이고 0~7일째 줄이 모두 있다.
    expect(c.snapshots.map((s) => s.dayIndex)).toEqual([
      0, 1, 2, 3, 4, 5, 6, 7,
    ]);
    expect(c.snapshots[7].views).toBe(12500);
    expect(c.snapshots[7].takenAt).toEqual(c.countingEndsAt);
    // 장부: 결제 승인 + 정산이 불변식을 지키고 에스크로가 0원이 된다.
    const entries = [...c.fundingPostings, ...c.settlementPostings].map(
      (p) => ({
        debitAccount: p.debit,
        creditAccount: p.credit,
        amount: p.amount,
      }),
    );
    expect(() => assertBalanced(entries)).not.toThrow();
    expect(balances(entries)).toEqual({
      PG_IN: -66000,
      ESCROW: 0,
      CREATOR_PAYABLE: 25000,
      STORE_REFUND: 35000,
      FEE_REVENUE: 6000,
    });
    expect(c.payment).toMatchObject({
      amountEscrow: 60000,
      amountFee: 6000,
      feeRate: 10,
    });
    // 협업의 오퍼는 협업이 끝나 닫힌 수락 오퍼 하나다.
    const offer = db.offers.find((o) => o.key === c.offerKey);
    expect(offer).toMatchObject({ status: 'ACCEPTED', creatorId: c.creatorId });
    expect(offer?.closedAt).toEqual(c.settlement.settledAt);
    expect(offer?.versions).toHaveLength(1);
    // 지급일이 지나 송금 행은 끝난 상태로 만들 수 있다.
    expect(c.payout.scheduledFor.getTime()).toBeLessThanOrEqual(NOW.getTime());
  });

  it('gives creator 0003 three series from the canvas', async () => {
    const { db, run } = setup();

    await run();

    expect(db.series).toEqual([
      {
        creatorId: idOf('010-0000-0003'),
        name: '한 그릇 일기',
        format: 'REELS',
        note: '30초 릴스 · 손 중심',
      },
      {
        creatorId: idOf('010-0000-0003'),
        name: '동네 점심 지도',
        format: 'CARD_NEWS',
        note: '카드뉴스 5장',
      },
      {
        creatorId: idOf('010-0000-0003'),
        name: '소리로 먹는 집',
        format: 'REELS',
        note: 'ASMR 릴스',
      },
    ]);
  });

  it('is safe to run twice and drops rows made during a demo', async () => {
    const { db, run } = setup();
    await run();
    const first = JSON.stringify([
      db.applications,
      db.offers,
      db.collaborations,
      db.series,
    ]);
    // 시연 중 0001이 서윤에게 낸 지원과 서윤이 만든 시리즈.
    db.applications.push({
      storeId: STORE_ID,
      creatorId: idOf('010-0000-0003'),
      pitch: null,
      createdAt: NOW,
    });
    db.series.push({
      creatorId: idOf('010-0000-0003'),
      name: '시연 시리즈',
      format: 'BLOG',
      note: null,
    });

    await run();

    expect(
      JSON.stringify([
        db.applications,
        db.offers,
        db.collaborations,
        db.series,
      ]),
    ).toBe(first);
  });

  it('leaves rows of other accounts untouched', async () => {
    const { db, run } = setup();
    db.applications.push({
      storeId: 'other-store',
      creatorId: 'other-creator',
      pitch: null,
      createdAt: NOW,
    });
    db.series.push({
      creatorId: 'other-creator',
      name: '남의 시리즈',
      format: 'REELS',
      note: null,
    });

    await run();

    expect(
      db.applications.filter((a) => a.storeId === 'other-store'),
    ).toHaveLength(1);
    expect(
      db.series.filter((x) => x.creatorId === 'other-creator'),
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
