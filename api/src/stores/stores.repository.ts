import { Injectable } from '@nestjs/common';
import {
  Prisma,
  ApplicationStatus,
  ContentFormat,
  OfferParty,
  OfferStatus,
  IndustryCategory,
  SourceLinkKind,
  Store,
  StoreOnboardingStep,
  StoreSourceLink,
  UsageRights,
} from '@prisma/client';
import { PROPOSAL_POLICY } from '../common/collaboration-policy';
import { PrismaService } from '../prisma/prisma.service';
import { numberedSlug, SLUG_MAX_LENGTH } from './slugify';

export type StoreWithLinks = Store & { sourceLinks: StoreSourceLink[] };

// 공개 상세: 요청자의 살아 있는 지원(지원 중, 오퍼 받음)과 열린 오퍼가 있으면 한 건씩 함께 읽는다.
export type PublishedStoreDetail = Store & {
  applications: { status: ApplicationStatus }[];
  offers: {
    id: string;
    latestVersion: number;
    status: OfferStatus;
    turn: OfferParty;
  }[];
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
  tags: string[];
  customerPhrases: string[];
}

// 고칠 때 쓰는 항목: 모양 항목 일부와 모집 한 줄. 분석이 덮어쓰는 StoreFields에는 모집 한 줄이 없다.
export type StoreUpdateData = Partial<StoreFields> & {
  recruitLine?: string | null;
};

// 주소 이름이 겹쳐 다시 시도하는 최대 횟수. 같은 이름의 가게가 동시에 만들어질 때만 반복된다.
const SLUG_ATTEMPTS = 5;

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

  // 공개 여부와 관계없이 읽는다(지워진 가게는 없는 것). 제안 상세처럼 당사자가 읽는 곳이 쓴다.
  findById(storeId: string): Promise<Store | null> {
    return this.prisma.store.findFirst({
      where: { id: storeId, deletedAt: null },
    });
  }

  findPublishedById(storeId: string): Promise<Store | null> {
    return this.prisma.store.findFirst({
      where: { id: storeId, ...PUBLISHED },
    });
  }

  // 지원 모듈을 import하면 모듈이 순환하므로, 내 지원 상태는 관계로 함께 읽는다.
  // 열린 오퍼: 기한 전의 SENT, 협업이 끝나지 않은(closedAt 없는) ACCEPTED, 방금 거절해 아직 되돌릴 수 있는 DECLINED.
  // 결제 기한이 지난 ACCEPTED는 곧 만료로 저장되므로 뺀다. 마지막 것은 제안(proposeToStore)이 열린 오퍼로 보아 409를 내는 것과 같은 기준이다.
  findPublishedDetail(
    storeId: string,
    viewerId: string,
    now: Date,
  ): Promise<PublishedStoreDetail | null> {
    const undoSince = new Date(
      now.getTime() - PROPOSAL_POLICY.declineUndoSeconds * 1000,
    );
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
        offers: {
          where: {
            creatorId: viewerId,
            deletedAt: null,
            closedAt: null,
            OR: [
              { status: 'SENT', expiresAt: { gt: now } },
              {
                status: 'ACCEPTED',
                OR: [{ paymentDueAt: null }, { paymentDueAt: { gt: now } }],
              },
              { status: 'DECLINED', declinedAt: { gt: undoSince } },
            ],
          },
          select: { id: true, latestVersion: true, status: true, turn: true },
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

  setTrialInfo(
    storeId: string,
    info: { monthlyFee: number; endsOn: Date; postCount: number },
  ): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      // 정보가 바뀌면 "나중에"로 숨긴 것도 풀어, 새 종료일 기준으로 다시 보여 준다.
      data: {
        trialMonthlyFee: info.monthlyFee,
        trialEndsOn: info.endsOn,
        trialPostCount: info.postCount,
        trialSnoozedUntil: null,
      },
      include: WITH_LINKS,
    });
  }

  clearTrialInfo(storeId: string): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      data: {
        trialMonthlyFee: null,
        trialEndsOn: null,
        trialPostCount: null,
        trialSnoozedUntil: null,
      },
      include: WITH_LINKS,
    });
  }

  snoozeTrialCompare(storeId: string, until: Date): Promise<StoreWithLinks> {
    return this.prisma.store.update({
      where: { id: storeId },
      data: { trialSnoozedUntil: until },
      include: WITH_LINKS,
    });
  }

  // 처음 본 시각만 남긴다.
  async markTrialHintSeen(storeId: string, now: Date): Promise<void> {
    await this.prisma.store.updateMany({
      where: { id: storeId, trialHintSeenAt: null },
      data: { trialHintSeenAt: now },
    });
  }

  // 직접 입력으로 등록 중인 가게를 만들거나 덮어쓴다. 이미 저장된 링크는 건드리지 않는다.
  // 공개된 가게면 아무것도 바꾸지 않고 null이다(replaceDraft와 같은 조건부 갱신).
  async saveManualDraft(
    ownerId: string,
    fields: StoreFields,
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
      return tx.store.findUniqueOrThrow({
        where: { id: store.id },
        include: WITH_LINKS,
      });
    });
  }

  // 주소 이름이 아직 없는 가게에만 만든다(WHERE slug IS NULL). 이미 있으면 바꾸지 않는다.
  // base가 쓰였으면 -2, -3…을 붙이고, 확인과 저장 사이에 다른 가게가 가져가 유일 제약에 걸리면 다시 고른다.
  async assignSlug(storeId: string, base: string): Promise<StoreWithLinks> {
    for (let attempt = 1; attempt <= SLUG_ATTEMPTS; attempt += 1) {
      const taken = new Set(
        (
          await this.prisma.store.findMany({
            // 번호를 붙이려고 잘린 이름도 찾도록 번호 자리(최대 5자)를 비운 앞부분으로 찾는다.
            where: {
              slug: { startsWith: base.slice(0, SLUG_MAX_LENGTH - 6) },
            },
            select: { slug: true },
          })
        ).map((row) => row.slug),
      );
      let slug = base;
      for (let n = 2; taken.has(slug); n += 1) slug = numberedSlug(base, n);
      try {
        await this.prisma.store.updateMany({
          where: { id: storeId, slug: null },
          data: { slug },
        });
        break;
      } catch (error) {
        const clash =
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002';
        if (!clash || attempt === SLUG_ATTEMPTS) throw error;
      }
    }
    return this.prisma.store.findUniqueOrThrow({
      where: { id: storeId },
      include: WITH_LINKS,
    });
  }

  update(storeId: string, data: StoreUpdateData): Promise<StoreWithLinks> {
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
