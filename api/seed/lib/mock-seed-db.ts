import type {
  ContentFormat,
  PrismaClient,
  SourceLinkKind,
  UsageRights,
} from '@prisma/client';

export interface MockCreatorProfileData {
  displayName: string;
  contentFocus: string | null;
  instagramHandle: string | null;
  photoPath: string | null;
  regionSido: string;
  regionSigungu: string | null;
}

export interface MockStoreData {
  name: string;
  category: string;
  neighborhood: string;
  regionSido: string;
  regionSigungu: string;
  coverPhotoPath: string;
  signatureMenu: string;
  hours: string;
  seats: string;
  bestShootingTime: string;
  intro: string;
  defaultFormat: ContentFormat;
  defaultVoucherName: string | null;
  defaultVoucherValue: number | null;
  defaultVoucherPeople: number | null;
  defaultFixedCash: number;
  defaultViewRatePerThousand: number | null;
  defaultPerViewCap: number | null;
  defaultUsageRights: UsageRights;
  publishedAt: Date;
}

export interface MockSourceLinkData {
  kind: SourceLinkKind;
  url: string;
  summary: string;
}

export interface MockApplicationData {
  creatorId: string;
  createdAt: Date;
}

export interface MockOfferData {
  creatorId: string;
  format: ContentFormat;
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
  usageRights: UsageRights;
  createdAt: Date;
  expiresAt: Date;
  declinedAt: Date;
}

// 목업 가게·크리에이터 행을 맞추는 포트. 테스트에서는 손으로 쓴 가짜를, 실행에서는 Prisma 구현을 쓴다.
export interface MockSeedDb {
  upsertCreatorProfile(
    userId: string,
    data: MockCreatorProfileData,
  ): Promise<void>;
  // 가게는 한 계정에 하나라 ownerId로 맞춘다. 출처 링크는 목업 목록으로 통째로 바꾼다.
  upsertStore(
    ownerId: string,
    data: MockStoreData,
    links: MockSourceLinkData[],
  ): Promise<{ storeId: string }>;
  // 이 가게와 목업 크리에이터들의 지원·오퍼만 지우고 다시 만든다. 그 밖의 행은 건드리지 않는다.
  resetCollaboration(input: {
    storeId: string;
    mockCreatorIds: string[];
    applications: MockApplicationData[];
    offers: MockOfferData[];
  }): Promise<void>;
}

// 한 번 돌고 끝나는 시드라서 repository를 거치지 않고 Prisma를 직접 쓴다.
export class PrismaMockSeedDb implements MockSeedDb {
  constructor(private readonly prisma: PrismaClient) {}

  async upsertCreatorProfile(
    userId: string,
    data: MockCreatorProfileData,
  ): Promise<void> {
    await this.prisma.creatorProfile.upsert({
      where: { userId },
      create: { userId, ...data },
      // deletedAt을 비우는 건, 지워진 채 남은 목업 프로필이 시드 뒤에도 안 보이는 것을 막기 위해서다.
      update: { ...data, deletedAt: null },
    });
  }

  async upsertStore(
    ownerId: string,
    data: MockStoreData,
    links: MockSourceLinkData[],
  ): Promise<{ storeId: string }> {
    const fields = {
      ...data,
      status: 'PUBLISHED' as const,
      onboardingStep: 'DONE' as const,
      industry: 'FOOD_CAFE' as const,
    };
    const store = await this.prisma.store.upsert({
      where: { ownerId },
      create: { ownerId, ...fields },
      update: { ...fields, deletedAt: null },
    });
    // 링크는 id를 기억할 필요가 없어서 지우고 다시 만든다. 이 가게의 행만 대상이다.
    await this.prisma.$transaction([
      this.prisma.storeSourceLink.deleteMany({ where: { storeId: store.id } }),
      this.prisma.storeSourceLink.createMany({
        data: links.map((l) => ({ ...l, storeId: store.id })),
      }),
    ]);
    return { storeId: store.id };
  }

  async resetCollaboration(input: {
    storeId: string;
    mockCreatorIds: string[];
    applications: MockApplicationData[];
    offers: MockOfferData[];
  }): Promise<void> {
    const { storeId, mockCreatorIds } = input;
    // 오퍼가 지원을 가리키므로 오퍼를 먼저 지운다. 부분 유니크 인덱스(살아 있는 지원·열린 오퍼는 하나)
    // 때문에 논리 삭제가 아니라 실제로 지운다. 목업 계정의 행만 지우는 시드라서 허용한다.
    const scope = {
      OR: [{ storeId }, { creatorId: { in: mockCreatorIds } }],
    };
    await this.prisma.$transaction([
      this.prisma.offer.deleteMany({ where: scope }),
      this.prisma.application.deleteMany({ where: scope }),
      this.prisma.application.createMany({
        data: input.applications.map((a) => ({
          storeId,
          creatorId: a.creatorId,
          status: 'APPLIED' as const,
          createdAt: a.createdAt,
        })),
      }),
      this.prisma.offer.createMany({
        data: input.offers.map((o) => ({
          ...o,
          storeId,
          status: 'DECLINED' as const,
          respondedAt: o.declinedAt,
        })),
      }),
    ]);
  }
}
