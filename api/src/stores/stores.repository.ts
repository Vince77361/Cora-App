import { Injectable } from '@nestjs/common';
import {
  ApplicationStatus,
  ContentFormat,
  IndustryCategory,
  SourceLinkKind,
  Store,
  StoreOnboardingStep,
  StoreSourceLink,
  UsageRights,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type StoreWithLinks = Store & { sourceLinks: StoreSourceLink[] };

// 공개 상세: 요청자의 살아 있는 지원(지원 중, 오퍼 받음)이 있으면 한 건 함께 읽는다.
export type PublishedStoreDetail = Store & {
  applications: { status: ApplicationStatus }[];
};

// 가게의 글자 항목. 비어 있으면 null이다(업종 분류는 항상 값이 있다).
export interface StoreFields {
  name: string | null;
  category: string | null;
  industry: IndustryCategory;
  neighborhood: string | null;
  regionSido: string | null;
  regionSigungu: string | null;
  coverPhotoPath: string | null;
  signatureMenu: string | null;
  hours: string | null;
  seats: string | null;
  bestShootingTime: string | null;
  intro: string | null;
}

export interface DefaultTermsData {
  format: ContentFormat;
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
  usageRights: UsageRights;
}

export interface SourceLinkData {
  kind: SourceLinkKind;
  url: string;
  summary: string | null;
}

// 링크는 지워진 행을 빼고, 종류 순서(네이버 지도, 캐치테이블, 인스타그램)로 읽는다.
const WITH_LINKS = {
  sourceLinks: { where: { deletedAt: null }, orderBy: { kind: 'asc' } },
} as const;

// 공개 조건: 공개 상태이고, 지워지지 않았고, 기본 오퍼 조건이 있다.
// 목록과 상세가 같은 조건을 쓰도록 한 곳에 둔다. 4번 계획이 업종 필터를 여기에 끼운다.
const PUBLISHED = {
  status: 'PUBLISHED',
  deletedAt: null,
  defaultFormat: { not: null },
} as const;

// 가게 조회는 모두 여기를 거친다.
@Injectable()
export class StoresRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 지워진(deleted_at) 가게는 없는 것으로 본다.
  findActiveByOwnerId(ownerId: string): Promise<StoreWithLinks | null> {
    return this.prisma.store.findFirst({
      where: { ownerId, deletedAt: null },
      include: WITH_LINKS,
    });
  }

  findPublishedById(storeId: string): Promise<Store | null> {
    return this.prisma.store.findFirst({
      where: { id: storeId, ...PUBLISHED },
    });
  }

  // 지원 모듈을 import하면 모듈이 순환하므로, 내 지원 상태는 관계로 함께 읽는다.
  findPublishedDetail(
    storeId: string,
    viewerId: string,
  ): Promise<PublishedStoreDetail | null> {
    return this.prisma.store.findFirst({
      where: { id: storeId, ...PUBLISHED },
      include: {
        applications: {
          where: {
            creatorId: viewerId,
            status: { in: ['APPLIED', 'OFFERED'] },
            deletedAt: null,
          },
          select: { status: true },
          take: 1,
        },
      },
    });
  }

  // 최근 공개 순. 지역 순서는 서비스가 이 순서를 지키며 묶는다.
  listPublished(excludeOwnerId: string): Promise<Store[]> {
    return this.prisma.store.findMany({
      where: { ...PUBLISHED, ownerId: { not: excludeOwnerId } },
      orderBy: [
        { publishedAt: { sort: 'desc', nulls: 'last' } },
        { id: 'asc' },
      ],
    });
  }

  // 등록 중인 가게를 분석 결과로 덮어쓰거나, 없으면 만든다. 이미 공개된 가게면 아무것도 바꾸지 않고 null.
  // 같은 사용자의 요청이 동시에 와도 owner_id 유니크 때문에 가게는 하나이고, 갱신 조건(DRAFT)이
  // 갱신 문장 안에 있어서 확인한 뒤 공개되어도 공개된 가게를 덮어쓰지 않는다.
  replaceDraft(
    ownerId: string,
    fields: StoreFields,
    links: SourceLinkData[],
    now: Date,
  ): Promise<StoreWithLinks | null> {
    return this.prisma.$transaction(async (tx) => {
      const store = await tx.store.upsert({
        where: { ownerId },
        create: { ownerId },
        update: {},
      });
      const { count } = await tx.store.updateMany({
        where: { id: store.id, status: 'DRAFT' },
        data: { ...fields, onboardingStep: 'PAGE', deletedAt: null },
      });
      if (count === 0) return null;
      // 출처 링크는 이번 링크로 통째로 바꾼다. 이전 것은 지운 표시만 한다.
      await tx.storeSourceLink.updateMany({
        where: { storeId: store.id, deletedAt: null },
        data: { deletedAt: now },
      });
      await tx.storeSourceLink.createMany({
        data: links.map((link) => ({ storeId: store.id, ...link })),
      });
      return tx.store.findUniqueOrThrow({
        where: { id: store.id },
        include: WITH_LINKS,
      });
    });
  }

  update(storeId: string, data: Partial<StoreFields>): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      data,
      include: WITH_LINKS,
    });
  }

  setOnboardingStep(
    storeId: string,
    step: StoreOnboardingStep,
  ): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      data: { onboardingStep: step },
      include: WITH_LINKS,
    });
  }

  setDefaultTerms(
    storeId: string,
    terms: DefaultTermsData,
  ): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      data: {
        defaultFormat: terms.format,
        defaultVoucherName: terms.voucherName,
        defaultVoucherValue: terms.voucherValue,
        defaultVoucherPeople: terms.voucherPeople,
        defaultFixedCash: terms.fixedCash,
        defaultViewRatePerThousand: terms.viewRatePerThousand,
        defaultPerViewCap: terms.perViewCap,
        defaultUsageRights: terms.usageRights,
      },
      include: WITH_LINKS,
    });
  }

  // DRAFT일 때만 공개로 바꾼다. 이미 공개된 가게는 공개 시각을 그대로 둔다.
  async publish(storeId: string, now: Date): Promise<StoreWithLinks> {
    await this.prisma.store.updateMany({
      where: { id: storeId, status: 'DRAFT' },
      data: { status: 'PUBLISHED', onboardingStep: 'DONE', publishedAt: now },
    });
    return this.prisma.store.findUniqueOrThrow({
      where: { id: storeId },
      include: WITH_LINKS,
    });
  }
}
