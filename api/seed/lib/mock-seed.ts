import { readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { Clock } from '../../src/common/clock';
import { SIDO_LIST } from '../../src/common/regions';
import { StoragePort } from '../../src/integrations/storage/storage.port';
import { buildTerms } from '../../src/stores/reward-terms';
import { MockSeedDb } from './mock-seed-db';

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

// A9 캔버스 첫 탭의 지원 순서와 지원한 날(며칠 전). 0은 오늘.
const APPLICANTS: readonly { key: string; daysAgo: number }[] = [
  { key: 'onecup', daysAgo: 0 },
  { key: 'seongsuMeal', daysAgo: 1 },
  { key: 'noodleDiary', daysAgo: 2 },
];
// 보낸 오퍼 탭의 `거절함` 줄. 거절한 지 30초가 넘어 사장님에게 거절이 보이는 상태다.
const DECLINED_OFFER = { key: 'min', createdDaysAgo: 2, declinedDaysAgo: 1 };
const OFFER_RESPONSE_DAYS = 7;

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

// 목업 크리에이터 프로필, 0001의 가게, 지원, 보낸 오퍼를 항상 같은 상태로 맞춘다.
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
    ],
  );
  log(`…${STORE_OWNER_PHONE.slice(-4)} STORE: 가게 맞춤(${mockStore.name})`);

  // "어제·2일 전 지원"이 보이도록 createdAt을 앞당겨 저장한다. 앱 API는 만들 수 없는 값이라 시드에서만 쓴다.
  const applications = APPLICANTS.map((a) => ({
    creatorId: creatorOf(a.key).userId,
    createdAt: new Date(now.getTime() - a.daysAgo * DAY_MS),
  }));
  const offerCreatedAt = new Date(
    now.getTime() - DECLINED_OFFER.createdDaysAgo * DAY_MS,
  );
  const offerTerms = buildTerms({
    format: 'REELS',
    reward: { voucher: {}, perView: {} },
  });
  await db.resetCollaboration({
    storeId,
    mockCreatorIds: CREATORS.map((c) => idOf(c.phone)),
    applications,
    offers: [
      {
        creatorId: creatorOf(DECLINED_OFFER.key).userId,
        format: offerTerms.format,
        voucherName: offerTerms.voucherName,
        voucherValue: offerTerms.voucherValue,
        voucherPeople: offerTerms.voucherPeople,
        fixedCash: offerTerms.fixedCash,
        viewRatePerThousand: offerTerms.viewRatePerThousand,
        perViewCap: offerTerms.perViewCap,
        usageRights: offerTerms.usageRights,
        createdAt: offerCreatedAt,
        expiresAt: new Date(
          offerCreatedAt.getTime() + OFFER_RESPONSE_DAYS * DAY_MS,
        ),
        declinedAt: new Date(
          now.getTime() - DECLINED_OFFER.declinedDaysAgo * DAY_MS,
        ),
      },
    ],
  });
  log(
    `지원 ${applications.length}건, 거절된 오퍼 1건 맞춤(…${STORE_OWNER_PHONE.slice(-4)} 가게)`,
  );
}
