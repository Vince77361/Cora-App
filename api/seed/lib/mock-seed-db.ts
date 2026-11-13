import { randomUUID } from 'node:crypto';
import type {
  ContentFormat,
  OfferEndReason,
  OfferParty,
  Prisma,
  PrismaClient,
  SettlementMethod,
  SourceLinkKind,
  UsageRights,
} from '@prisma/client';
import type { Posting } from '../../src/ledger/ledger-postings';
import {
  settlePayoutKey,
  settleRefundKey,
} from '../../src/settlements/job-keys';

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
  slug: string;
  tags: string[];
  customerPhrases: string[];
  recruitLine: string;
  trialMonthlyFee: number;
  trialEndsOn: Date;
  trialPostCount: number;
  // 다시 돌릴 때마다 비교 줄이 보이도록 "나중에"와 안내 확인 기록을 비운다.
  trialSnoozedUntil: Date | null;
  trialHintSeenAt: Date | null;
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
  summary: string | null;
}

export interface MockApplicationData {
  creatorId: string;
  pitch: string | null;
  createdAt: Date;
}

export interface MockVersionData {
  number: number;
  authorParty: OfferParty;
  format: ContentFormat;
  pieces: number;
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
  usageRights: UsageRights;
  idea: string | null;
  principles: string[];
  series: {
    name: string;
    format: ContentFormat;
    note: string | null;
  } | null;
  createdAt: Date;
}

// 제안(오퍼) 하나와 그 판본들. 만든 뒤의 상태를 그대로 적는다(수락·거절·기한 같은 흐름은 시드가 거치지 않는다).
export interface MockOfferData {
  // 협업이 어느 오퍼에 붙는지 가리키는 이름표(저장하지 않는다).
  key: string;
  creatorId: string;
  status: 'SENT' | 'ACCEPTED' | 'DECLINED';
  turn: OfferParty;
  initiatedBy: OfferParty;
  endReason: OfferEndReason | null;
  endedBy: OfferParty | null;
  createdAt: Date;
  expiresAt: Date;
  acceptedAt: Date | null;
  declinedAt: Date | null;
  // 협업이 끝난 시각. 차면 ACCEPTED여도 열린 오퍼로 세지 않는다.
  closedAt: Date | null;
  versions: MockVersionData[];
}

// 정산까지 끝난 협업 한 건(돈, 조회수, 지급·환급 행, 장부 줄)을 통째로 적는다.
export interface MockCollaborationData {
  offerKey: string;
  creatorId: string;
  terms: Prisma.InputJsonObject;
  settlementMethod: SettlementMethod;
  fundedAt: Date;
  submitDueAt: Date;
  submittedUrl: string;
  submittedAt: Date;
  countingEndsAt: Date;
  payment: {
    amountEscrow: number;
    amountFee: number;
    feeRate: number;
    pgTransactionId: string;
  };
  snapshots: { dayIndex: number; views: number; takenAt: Date }[];
  settlement: {
    finalViews: number;
    payoutAmount: number;
    refundAmount: number;
    settledAt: Date;
    usualViews: number;
    multiplierTenths: number;
    usualReadAt: Date;
  };
  payout: { amount: number; scheduledFor: Date };
  refund: { amount: number };
  // 장부 줄. 결제 승인 묶음과 정산 묶음이고, 실제 서비스와 같은 계산 함수로 만든 값이다.
  fundingPostings: Posting[];
  settlementPostings: Posting[];
}

export interface MockSeriesData {
  creatorId: string;
  name: string;
  format: ContentFormat;
  note: string | null;
}

export interface MockStoreFlowInput {
  storeId: string;
  // 협업을 맡긴 쪽(commissioner)인 가게 사장님.
  ownerId: string;
  mockCreatorIds: string[];
  applications: MockApplicationData[];
  offers: MockOfferData[];
  collaboration: MockCollaborationData;
  series: MockSeriesData[];
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
  // 이 가게와 목업 크리에이터들의 지원·제안(과 그 협업·돈 행)·시리즈만 지우고 다시 만든다. 그 밖의 행은 건드리지 않는다.
  resetStoreFlow(input: MockStoreFlowInput): Promise<void>;
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

  async resetStoreFlow(input: MockStoreFlowInput): Promise<void> {
    const { storeId, ownerId, mockCreatorIds, collaboration: c } = input;
    // 이 시드가 전에 만든 협업만 지운다: 시드가 고정한 결제 표지(pgTransactionId)로 찾는다.
    // 시연 중 앱으로 만든 협업이나 시험 계정의 협업은 이 범위가 아니라서, 그 돈 행(장부는 만들기만 하는 표)과 함께 남는다.
    const previousSeedCollaborations = await this.prisma.payment.findMany({
      where: { pgTransactionId: c.payment.pgTransactionId },
      select: { collaborationId: true },
    });
    const seedCollaborationIds = previousSeedCollaborations.map(
      (p) => p.collaborationId,
    );
    const ofSeed = { collaborationId: { in: seedCollaborationIds } };

    // 오퍼가 지원을 가리키므로 오퍼를 먼저 지운다. 부분 유니크 인덱스(살아 있는 지원·열린 오퍼는 하나)
    // 때문에 논리 삭제가 아니라 실제로 지운다. 목업 계정의 행만 지우는 시드라서 허용한다.
    const scope = {
      OR: [{ storeId }, { creatorId: { in: mockCreatorIds } }],
    };
    // 지우는 오퍼는 협업이 안 붙은 것과 시드 협업의 오퍼뿐이다(남의 협업이 붙은 오퍼는 지울 수 없어 남긴다).
    // 남은 오퍼가 열린 오퍼(수락됐고 협업이 안 끝남)라 새 제안과 부분 유니크 인덱스에 걸리면 시드는 실패한다(지우지 않는다).
    const offerScope = {
      AND: [
        scope,
        {
          OR: [
            { collaboration: { is: null } },
            { collaboration: { is: { id: { in: seedCollaborationIds } } } },
          ],
        },
      ],
    };

    // 새 행의 id를 먼저 정해, 서로 가리키는 행을 한 번의 배치 트랜잭션으로 만든다(원격 DB라 왕복을 줄인다).
    const offerIds = new Map(input.offers.map((o) => [o.key, randomUUID()]));
    const offerId = offerIds.get(c.offerKey);
    if (!offerId) throw new Error('협업이 붙을 오퍼를 찾지 못했어요.');
    const collaborationId = randomUUID();
    const paymentId = randomUUID();

    const ledgerRows = (
      key: string,
      postings: Posting[],
    ): Prisma.LedgerEntryCreateManyInput[] => {
      const batchId = randomUUID();
      return postings
        .filter((p) => p.amount !== 0)
        .map((p) => ({
          collaborationId,
          batchId,
          debitAccount: p.debit,
          creditAccount: p.credit,
          amount: p.amount,
          reason: p.reason,
          idempotencyKey: key,
        }));
    };

    await this.prisma.$transaction([
      this.prisma.ledgerEntry.deleteMany({ where: ofSeed }),
      this.prisma.viewSnapshot.deleteMany({ where: ofSeed }),
      this.prisma.payout.deleteMany({ where: ofSeed }),
      this.prisma.refund.deleteMany({ where: ofSeed }),
      this.prisma.settlement.deleteMany({ where: ofSeed }),
      this.prisma.payment.deleteMany({ where: ofSeed }),
      this.prisma.cancelRequest.deleteMany({ where: ofSeed }),
      this.prisma.opsAuditLog.deleteMany({ where: ofSeed }),
      this.prisma.collaboration.deleteMany({
        where: { id: { in: seedCollaborationIds } },
      }),
      // 판본이 오퍼를 가리키므로 판본, 오퍼, 지원 순서로 지운다.
      this.prisma.offerVersion.deleteMany({ where: { offer: offerScope } }),
      this.prisma.offer.deleteMany({ where: offerScope }),
      this.prisma.application.deleteMany({ where: scope }),
      this.prisma.creatorSeries.deleteMany({
        where: { creatorId: { in: mockCreatorIds } },
      }),
      this.prisma.application.createMany({
        data: input.applications.map((a) => ({
          storeId,
          creatorId: a.creatorId,
          status: 'APPLIED' as const,
          pitch: a.pitch,
          createdAt: a.createdAt,
        })),
      }),
      this.prisma.creatorSeries.createMany({ data: input.series }),
      // createMany는 판본을 함께 만들 수 없어 오퍼마다 만든다. 오퍼의 조건은 판본에 있다.
      ...input.offers.map((o) =>
        this.prisma.offer.create({
          data: {
            id: offerIds.get(o.key),
            storeId,
            creatorId: o.creatorId,
            status: o.status,
            latestVersion: o.versions.length,
            turn: o.turn,
            initiatedBy: o.initiatedBy,
            endReason: o.endReason,
            endedBy: o.endedBy,
            createdAt: o.createdAt,
            expiresAt: o.expiresAt,
            acceptedAt: o.acceptedAt,
            declinedAt: o.declinedAt,
            respondedAt: o.acceptedAt ?? o.declinedAt,
            closedAt: o.closedAt,
            versions: {
              create: o.versions.map((v) => ({
                number: v.number,
                authorParty: v.authorParty,
                format: v.format,
                pieces: v.pieces,
                voucherName: v.voucherName,
                voucherValue: v.voucherValue,
                voucherPeople: v.voucherPeople,
                fixedCash: v.fixedCash,
                viewRatePerThousand: v.viewRatePerThousand,
                perViewCap: v.perViewCap,
                usageRights: v.usageRights,
                idea: v.idea,
                principles: v.principles,
                seriesName: v.series?.name ?? null,
                seriesFormat: v.series?.format ?? null,
                seriesNote: v.series?.note ?? null,
                createdAt: v.createdAt,
              })),
            },
          },
        }),
      ),
      this.prisma.collaboration.create({
        data: {
          id: collaborationId,
          kind: 'STORE_OFFER',
          stage: 'SETTLED',
          commissionerId: ownerId,
          creatorId: c.creatorId,
          offerId,
          storeId,
          terms: c.terms,
          settlementMethod: c.settlementMethod,
          fundedAt: c.fundedAt,
          submitDueAt: c.submitDueAt,
          submittedUrl: c.submittedUrl,
          submittedAt: c.submittedAt,
          countingEndsAt: c.countingEndsAt,
        },
      }),
      // 결제 승인 시각은 협업이 보관을 시작한 시각(fundedAt)과 같다(3번 R35).
      this.prisma.payment.create({
        data: {
          id: paymentId,
          collaborationId,
          amountEscrow: c.payment.amountEscrow,
          amountFee: c.payment.amountFee,
          feeRate: c.payment.feeRate,
          method: 'CARD',
          status: 'APPROVED',
          pgTransactionId: c.payment.pgTransactionId,
          requestedAt: c.fundedAt,
          approvedAt: c.fundedAt,
        },
      }),
      this.prisma.ledgerEntry.createMany({
        data: [
          ...ledgerRows(`payment:${paymentId}`, c.fundingPostings),
          ...ledgerRows(`settle:${collaborationId}`, c.settlementPostings),
        ],
      }),
      this.prisma.viewSnapshot.createMany({
        data: c.snapshots.map((snap) => ({ ...snap, collaborationId })),
      }),
      this.prisma.settlement.create({
        data: { collaborationId, ...c.settlement },
      }),
      // 지급일이 이미 지난 협업이라 지급·환급 행은 끝난(DONE) 상태다. 대기 행은 큐의 작업이 있어야 처리되는데 시드는 큐를 쓰지 않는다.
      this.prisma.payout.create({
        data: {
          collaborationId,
          amount: c.payout.amount,
          status: 'DONE',
          externalId: 'seed-payout',
          idempotencyKey: settlePayoutKey(collaborationId),
          scheduledFor: c.payout.scheduledFor,
        },
      }),
      this.prisma.refund.create({
        data: {
          collaborationId,
          amount: c.refund.amount,
          status: 'DONE',
          externalId: 'seed-refund',
          idempotencyKey: settleRefundKey(collaborationId),
        },
      }),
    ]);
  }
}
