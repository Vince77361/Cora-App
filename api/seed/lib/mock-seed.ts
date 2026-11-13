import { readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import type { ContentFormat } from '@prisma/client';
import { Clock } from '../../src/common/clock';
import { kstDateString } from '../../src/common/kst';
import { SIDO_LIST } from '../../src/common/regions';
import { StoragePort } from '../../src/integrations/storage/storage.port';
import {
  postingsForPaymentApproved,
  postingsForSettlement,
} from '../../src/ledger/ledger-postings';
import { nextPayday } from '../../src/settlements/payday';
import {
  feeFor,
  multiplierTenthsOf,
  settleReward,
} from '../../src/settlements/settlement-math';
import {
  buildTerms,
  copyOfTerms,
  maxCashBurden,
  settlementMethodOfReward,
} from '../../src/stores/reward-terms';
import type { OfferTermsModel } from '../../src/stores/dto/offer-terms.model';
import {
  MockApplicationData,
  MockOfferData,
  MockSeedDb,
  MockVersionData,
} from './mock-seed-db';

export interface MockSeedDeps {
  db: MockSeedDb;
  storage: StoragePort;
  clock: Clock;
  log: (line: string) => void;
}

interface MockJson {
  creators: {
    key: string;
    name: string;
    handle: string;
    avatarImage: string | null;
  }[];
  stores: {
    key: string;
    name: string;
    category: string;
    area: string;
    image: string;
    signatureMenu: { name: string; price: string };
    openingHours: string;
    seats: string;
    bestShootingTime: string;
    intro: string;
  }[];
  storeFlow: {
    storePage: {
      slug: string;
      tags: string[];
      customerPhrases: string[];
      recruitLine: string;
      instagramUrl: string;
    };
    trial: { monthlyFee: number; postCount: number; endsInDays: number };
    pitches: Record<string, string>;
    counterOffer: {
      creator: string;
      format: ContentFormat;
      fixedCash: number;
      idea: string;
      principles: string[];
      series: string;
    };
    series: { name: string; format: ContentFormat; note: string | null }[];
    result: {
      creator: string;
      views: number;
      usualViews: number;
      postUrl: string;
    };
  };
}

const MOCK_ROOT = join(__dirname, '../mock');
const DAY_MS = 24 * 60 * 60 * 1000;

// 번호 → 목업 크리에이터. contentFocus는 A9 캔버스(NStoreHome)의 지원자 줄 앞부분에 있는 것만 쓰고,
// 캔버스에 없으면 null이다(서윤, 민).
const CREATORS: readonly {
  phone: string;
  key: string;
  contentFocus: string | null;
}[] = [
  { phone: '010-0000-0003', key: 'seoyun', contentFocus: null },
  { phone: '010-0000-0004', key: 'onecup', contentFocus: '리빙 릴스' },
  { phone: '010-0000-0005', key: 'seongsuMeal', contentFocus: '맛집 릴스' },
  { phone: '010-0000-0006', key: 'noodleDiary', contentFocus: '라멘 리뷰' },
  { phone: '010-0000-0007', key: 'min', contentFocus: null },
];

const STORE_OWNER_PHONE = '010-0000-0001';
// 캔버스에 활동 지역이 없어서 시연용으로 모두 서울특별시, 구·군 없음으로 둔다.
const CREATOR_REGION_SIDO = SIDO_LIST[0];
const STORE_REGION_SIGUNGU = '성동구';

// A9 캔버스 첫 탭의 지원 순서(하루 한 컵, 성수 한 끼, 면치기 일기)에 G2 캔버스의 나머지 둘(민, 서윤)을 더한 지원자 다섯 명.
// 지원한 날은 며칠 전인지(0은 오늘). 한 줄(pitch)은 G2 캔버스의 세 문장이 있는 사람만 갖는다.
const APPLICANTS: readonly { key: string; daysAgo: number }[] = [
  { key: 'onecup', daysAgo: 0 },
  { key: 'seongsuMeal', daysAgo: 1 },
  { key: 'noodleDiary', daysAgo: 2 },
  { key: 'min', daysAgo: 3 },
  { key: 'seoyun', daysAgo: 4 },
];
const OFFER_RESPONSE_DAYS = 7;

// 7일 결과(G1)의 협업 시간표(며칠 전). 지급일(정산 다음 주 수요일)이 지나 지급·환급이 끝난 상태가 되도록
// 정산을 열흘 전으로 둔다. 제출은 정산 7일 전(측정 기간)이다.
const COLLAB_TIMELINE = {
  offerCreatedDaysAgo: 30,
  acceptedDaysAgo: 29,
  fundedDaysAgo: 28,
  submittedDaysAgo: 17,
  settledDaysAgo: 10,
};
// 협업의 0~6일째 쌓인 조회수. 7일째 값은 최종 조회수(G1의 12,500회)다.
const SNAPSHOT_VIEWS_BEFORE_FINAL = [0, 1800, 4200, 6900, 9000, 10800, 11900];
// 수수료율은 서버 기본값(FEE_RATE_STORE_OFFER 10%)이다. 시드는 환경 값을 읽지 않는다.
const FEE_RATE_PERCENT = 10;

const CONTENT_TYPES: Record<string, string> = {
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
};

function readMock(): MockJson {
  return JSON.parse(
    readFileSync(join(MOCK_ROOT, 'mock.json'), 'utf8'),
  ) as MockJson;
}

// 같은 경로에 다시 올려도 덮어쓰므로(upsert) 시드를 몇 번 돌려도 파일은 늘지 않는다.
async function uploadImage(
  storage: StoragePort,
  imageFile: string,
  path: string,
): Promise<void> {
  const contentType = CONTENT_TYPES[extname(imageFile)];
  if (!contentType) throw new Error('목업 사진 확장자를 알 수 없어요.');
  await storage.upload(
    path,
    readFileSync(join(MOCK_ROOT, imageFile)),
    contentType,
  );
}

// 목업 크리에이터 프로필, 0001의 가게, 지원, 제안함, 정산이 끝난 협업 하나, 서윤의 시리즈를 항상 같은 상태로 맞춘다.
// 시연 중 0001이 만든 오퍼·지원도 다시 돌리면 초기화된다.
export async function runMockSeed(
  deps: MockSeedDeps,
  accountIds: ReadonlyMap<string, string>,
): Promise<void> {
  const { db, storage, clock, log } = deps;
  const mock = readMock();
  const now = clock.now();
  const idOf = (phone: string): string => {
    const id = accountIds.get(phone);
    if (!id) throw new Error('목업 시드에 필요한 개발 계정이 없어요.');
    return id;
  };
  const creatorOf = (key: string) => {
    const spec = CREATORS.find((c) => c.key === key);
    const creator = mock.creators.find((c) => c.key === key);
    if (!spec || !creator) throw new Error('목업 크리에이터를 찾지 못했어요.');
    return { spec, creator, userId: idOf(spec.phone) };
  };

  for (const spec of CREATORS) {
    const { creator, userId } = creatorOf(spec.key);
    let photoPath: string | null = null;
    if (creator.avatarImage) {
      photoPath = `creators/${userId}/seed-profile${extname(creator.avatarImage)}`;
      await uploadImage(storage, creator.avatarImage, photoPath);
    }
    await db.upsertCreatorProfile(userId, {
      displayName: creator.name,
      contentFocus: spec.contentFocus,
      instagramHandle: creator.handle.replace(/^@/, ''),
      photoPath,
      regionSido: CREATOR_REGION_SIDO,
      regionSigungu: null,
    });
    log(`…${spec.phone.slice(-4)} CREATOR: 프로필 맞춤(${creator.name})`);
  }

  const flow = mock.storeFlow;
  const mockStore = mock.stores.find((s) => s.key === 'hangeureutRamen');
  if (!mockStore) throw new Error('목업 가게를 찾지 못했어요.');
  const ownerId = idOf(STORE_OWNER_PHONE);
  const coverPhotoPath = `stores/${ownerId}/seed-cover${extname(mockStore.image)}`;
  await uploadImage(storage, mockStore.image, coverPhotoPath);
  // 기본 조건은 앱 규칙(buildTerms)을 거친 값으로 저장한다: 릴스 + 식사권 + 조회수 수당(빈 값은 기본값).
  const terms = buildTerms({
    format: 'REELS',
    reward: { voucher: {}, perView: {} },
  });
  const { storeId } = await db.upsertStore(
    ownerId,
    {
      name: mockStore.name,
      category: mockStore.category,
      neighborhood: mockStore.area,
      regionSido: SIDO_LIST[0],
      regionSigungu: STORE_REGION_SIGUNGU,
      coverPhotoPath,
      signatureMenu: `${mockStore.signatureMenu.name} ${mockStore.signatureMenu.price}`,
      hours: mockStore.openingHours,
      seats: mockStore.seats,
      bestShootingTime: mockStore.bestShootingTime,
      intro: mockStore.intro,
      slug: flow.storePage.slug,
      tags: flow.storePage.tags,
      customerPhrases: flow.storePage.customerPhrases,
      recruitLine: flow.storePage.recruitLine,
      // 종료일은 시드를 돌린 날의 한국 날짜 + 28일이라, 돌릴 때마다 "한 달 남았어요" 줄이 보인다.
      trialMonthlyFee: flow.trial.monthlyFee,
      trialEndsOn: new Date(
        `${kstDateString(new Date(now.getTime() + flow.trial.endsInDays * DAY_MS))}T00:00:00.000Z`,
      ),
      trialPostCount: flow.trial.postCount,
      trialSnoozedUntil: null,
      trialHintSeenAt: null,
      defaultFormat: terms.format,
      defaultVoucherName: terms.voucherName,
      defaultVoucherValue: terms.voucherValue,
      defaultVoucherPeople: terms.voucherPeople,
      defaultFixedCash: terms.fixedCash,
      defaultViewRatePerThousand: terms.viewRatePerThousand,
      defaultPerViewCap: terms.perViewCap,
      defaultUsageRights: terms.usageRights,
      publishedAt: now,
    },
    [
      {
        kind: 'NAVER_MAP',
        url: 'https://naver.me/seedhangeureut',
        summary: '사진 12장, 메뉴 8개 찾음',
      },
      {
        kind: 'CATCHTABLE',
        url: 'https://app.catchtable.co.kr/ct/shop/seedhangeureut',
        summary: '영업시간 찾음',
      },
      // 평소 조회수를 읽을 가게 인스타그램 계정이다(체험단 비교와 7일 결과가 쓴다).
      { kind: 'INSTAGRAM', url: flow.storePage.instagramUrl, summary: null },
    ],
  );
  log(`…${STORE_OWNER_PHONE.slice(-4)} STORE: 가게 맞춤(${mockStore.name})`);

  const at = (daysAgo: number) => new Date(now.getTime() - daysAgo * DAY_MS);
  // "어제·2일 전 지원"이 보이도록 createdAt을 앞당겨 저장한다. 앱 API는 만들 수 없는 값이라 시드에서만 쓴다.
  const applications: MockApplicationData[] = APPLICANTS.map((a) => ({
    creatorId: creatorOf(a.key).userId,
    pitch: flow.pitches[a.key] ?? null,
    createdAt: at(a.daysAgo),
  }));

  const versionOf = (
    number: number,
    author: 'STORE' | 'CREATOR',
    t: OfferTermsModel,
    createdAt: Date,
    extra: Partial<
      Pick<MockVersionData, 'idea' | 'principles' | 'series'>
    > = {},
  ): MockVersionData => ({
    number,
    authorParty: author,
    format: t.format,
    pieces: t.pieces,
    voucherName: t.voucherName,
    voucherValue: t.voucherValue,
    voucherPeople: t.voucherPeople,
    fixedCash: t.fixedCash,
    viewRatePerThousand: t.viewRatePerThousand,
    perViewCap: t.perViewCap,
    usageRights: t.usageRights,
    idea: extra.idea ?? null,
    principles: extra.principles ?? [],
    series: extra.series ?? null,
    createdAt,
  });
  // 사장님이 처음 보내는 제안(판본 1)은 가게의 모집 조건이다.
  const storeVersion = (createdAt: Date) =>
    versionOf(1, 'STORE', terms, createdAt);
  const counter = flow.counterOffer;
  const counterSeries = flow.series.find((x) => x.name === counter.series);
  if (!counterSeries) throw new Error('목업 시리즈를 찾지 못했어요.');
  const counterTerms = buildTerms({
    format: counter.format,
    reward: { voucher: {}, fixedCash: counter.fixedCash, perView: {} },
  });
  const sent = (
    key: string,
    creatorKey: string,
    createdAt: Date,
    versions: MockVersionData[],
    turn: 'STORE' | 'CREATOR',
  ): MockOfferData => ({
    key,
    creatorId: creatorOf(creatorKey).userId,
    status: 'SENT',
    turn,
    initiatedBy: 'STORE',
    endReason: null,
    endedBy: null,
    createdAt,
    // 마지막 판본이 나온 날부터 답할 기한을 센다.
    expiresAt: new Date(
      versions[versions.length - 1].createdAt.getTime() +
        OFFER_RESPONSE_DAYS * DAY_MS,
    ),
    acceptedAt: null,
    declinedAt: null,
    closedAt: null,
    versions,
  });

  const settledAt = at(COLLAB_TIMELINE.settledDaysAgo);
  const acceptedAt = at(COLLAB_TIMELINE.acceptedDaysAgo);
  const offers: MockOfferData[] = [
    // F3 내가 응답할 차례: 하루 한 컵이 카드뉴스로 고쳐 보낸 판본 2.
    sent(
      'myTurn',
      counter.creator,
      at(3),
      [
        storeVersion(at(3)),
        versionOf(2, 'CREATOR', counterTerms, at(1), {
          idea: counter.idea,
          principles: counter.principles,
          series: counterSeries,
        }),
      ],
      'STORE',
    ),
    // F3 상대 대기: 민은 "2일 안에 답이 와요", 서윤은 방금 보낸 것.
    sent('waitingMin', 'min', at(5), [storeVersion(at(5))], 'CREATOR'),
    sent('waitingSeoyun', 'seoyun', at(1), [storeVersion(at(1))], 'CREATOR'),
    // F3 종료: 서윤이 일정이 맞지 않아 끝낸 제안.
    {
      key: 'endedSchedule',
      creatorId: creatorOf('seoyun').userId,
      status: 'DECLINED',
      turn: 'CREATOR',
      initiatedBy: 'STORE',
      endReason: 'SCHEDULE',
      endedBy: 'CREATOR',
      createdAt: at(20),
      expiresAt: new Date(at(20).getTime() + OFFER_RESPONSE_DAYS * DAY_MS),
      acceptedAt: null,
      declinedAt: at(18),
      closedAt: null,
      versions: [storeVersion(at(20))],
    },
    // F3 종료: 합의 완료. 하루 한 컵과 끝까지 간 협업(G1)의 오퍼다. 협업이 끝나 닫혀 있다.
    {
      key: 'agreed',
      creatorId: creatorOf(flow.result.creator).userId,
      status: 'ACCEPTED',
      turn: 'CREATOR',
      initiatedBy: 'STORE',
      endReason: null,
      endedBy: null,
      createdAt: at(COLLAB_TIMELINE.offerCreatedDaysAgo),
      expiresAt: new Date(
        at(COLLAB_TIMELINE.offerCreatedDaysAgo).getTime() +
          OFFER_RESPONSE_DAYS * DAY_MS,
      ),
      acceptedAt,
      declinedAt: null,
      closedAt: settledAt,
      versions: [storeVersion(at(COLLAB_TIMELINE.offerCreatedDaysAgo))],
    },
  ];

  // G1 협업: 12,500회, 1,000회당 2,000원이면 25,000원 지급, 상한 60,000원에서 35,000원 환불.
  // 계산은 서버와 같은 함수를 쓰고, 장부는 결제 승인 묶음과 정산 묶음이다(에스크로 잔액 0).
  const result = flow.result;
  const reward = {
    fixedCash: terms.fixedCash,
    viewRatePerThousand: terms.viewRatePerThousand as number,
    perViewCap: terms.perViewCap as number,
  };
  const settled = settleReward({
    views: result.views,
    ratePerThousand: reward.viewRatePerThousand,
    cap: reward.perViewCap,
    fixedCash: reward.fixedCash,
  });
  const escrow = maxCashBurden(reward);
  const submittedAt = at(COLLAB_TIMELINE.submittedDaysAgo);
  const fundedAt = at(COLLAB_TIMELINE.fundedDaysAgo);
  const collaboration = {
    offerKey: 'agreed',
    creatorId: creatorOf(result.creator).userId,
    terms: copyOfTerms(terms, 1),
    settlementMethod: settlementMethodOfReward(terms),
    fundedAt,
    submitDueAt: new Date(fundedAt.getTime() + 14 * DAY_MS),
    submittedUrl: result.postUrl,
    submittedAt,
    countingEndsAt: settledAt,
    payment: {
      amountEscrow: escrow,
      amountFee: feeFor(escrow, FEE_RATE_PERCENT),
      feeRate: FEE_RATE_PERCENT,
      pgTransactionId: 'seed-payment-hangeureut',
    },
    snapshots: [...SNAPSHOT_VIEWS_BEFORE_FINAL, result.views].map(
      (views, dayIndex) => ({
        dayIndex,
        views,
        takenAt: new Date(submittedAt.getTime() + dayIndex * DAY_MS),
      }),
    ),
    settlement: {
      finalViews: result.views,
      payoutAmount: settled.payout,
      refundAmount: settled.refund,
      fixedCashAmount: 0,
      viewPayAmount: settled.payout,
      status: 'CONFIRMED' as const,
      calculatedAt: settledAt,
      confirmedAt: settledAt,
      confirmedBy: 'AUTO' as const,
      settledAt,
      usualViews: result.usualViews,
      multiplierTenths: multiplierTenthsOf(
        result.views,
        result.usualViews,
      ) as number,
      usualReadAt: settledAt,
    },
    payout: { amount: settled.payout, scheduledFor: nextPayday(settledAt) },
    refund: { amount: settled.refund },
    fundingPostings: postingsForPaymentApproved({
      escrow,
      fee: feeFor(escrow, FEE_RATE_PERCENT),
    }),
    settlementPostings: postingsForSettlement({
      payout: settled.payout,
      refund: settled.refund,
    }),
  };

  await db.resetStoreFlow({
    storeId,
    ownerId,
    mockCreatorIds: CREATORS.map((c) => idOf(c.phone)),
    applications,
    offers,
    collaboration,
    // 시리즈는 0003 서윤의 것이다(F6의 "내 시리즈로 만들기").
    series: flow.series.map((x) => ({
      creatorId: creatorOf('seoyun').userId,
      name: x.name,
      format: x.format,
      note: x.note,
    })),
  });
  log(
    `지원 ${applications.length}건, 제안 ${offers.length}건, 정산이 끝난 협업 1건, 시리즈 ${flow.series.length}개 맞춤(…${STORE_OWNER_PHONE.slice(-4)} 가게)`,
  );
}
