import { Injectable } from '@nestjs/common';
import {
  OfferEndReason,
  OfferParty,
  OfferStatus,
  OfferVersion,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { OfferTermsModel } from '../stores/dto/offer-terms.model';
import { DECLINE_UNDO_SECONDS } from './offer-rules';
import { OfferVersionsRepository } from './offer-versions.repository';
import { turnAfter } from './proposal-rules';

// 연결된 지원의 상태를 함께 읽어, 이미 닫힌 지원에 닫기를 다시 부르지 않게 한다.
// 조건은 판본에 있어서 가장 새 판본 하나를 함께 읽는다(오퍼를 만드는 트랜잭션이 번호와 판본을 같이 올린다).
const WITH_APPLICATION = {
  application: { select: { status: true } },
  versions: { orderBy: { number: 'desc' }, take: 1 },
} satisfies Prisma.OfferInclude;

export type OfferRow = Prisma.OfferGetPayload<{
  include: typeof WITH_APPLICATION;
}>;

// 오퍼의 가장 새 판본. 판본 없는 오퍼는 마이그레이션이 지켜 주는 불변식을 깬 것이라 던진다.
export function latestVersionOf(row: OfferRow): OfferVersion {
  const latest = row.versions[0];
  if (!latest) throw new Error('오퍼에 판본이 없어요.');
  return latest;
}

// 오퍼와 판본 1을 한 번에 만든다. 처음 보내는 쪽은 사장님이다.
export interface NewOffer {
  storeId: string;
  creatorId: string;
  applicationId: string | null;
  terms: OfferTermsModel;
  createdAt: Date;
  expiresAt: Date;
}

// 새 판본 하나. readVersion은 서비스가 읽은 최신 번호다(갱신 조건에 걸어 읽은 뒤 바뀌었으면 0행이 되게 한다).
export interface NewProposal {
  offerId: string;
  author: OfferParty;
  readVersion: number;
  terms: OfferTermsModel;
  idea: string | null;
  principles: string[];
  now: Date;
  // 새 판본이 나올 때마다 응답 기한을 다시 센다.
  expiresAt: Date;
}

// 오퍼 갱신과 같은 트랜잭션에서 할 일(연결된 협업 만들기·옮기기). false를 돌려주면 오퍼 갱신까지 되돌린다.
export type InSameTransaction = (
  tx: Prisma.TransactionClient,
) => Promise<boolean | void>;

class Rollback extends Error {}

// 오퍼 조회와 상태 변경은 모두 여기를 거친다. 상태 변경은 모두 조건부 갱신(UPDATE ... WHERE status = 기대 상태)이라
// 동시에 와도 한 번만 바뀌고, 바뀐 행이 0이면 false를 돌려 서비스가 409로 바꾸게 한다.
@Injectable()
export class OffersRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly versions: OfferVersionsRepository,
  ) {}

  findById(id: string): Promise<OfferRow | null> {
    return this.prisma.offer.findFirst({
      where: { id, deletedAt: null },
      include: WITH_APPLICATION,
    });
  }

  // 소유 조건을 id와 함께 걸어, 남의 오퍼는 없는 오퍼와 같게 보이게 한다.
  findForStore(id: string, storeId: string): Promise<OfferRow | null> {
    return this.prisma.offer.findFirst({
      where: { id, storeId, deletedAt: null },
      include: WITH_APPLICATION,
    });
  }

  findForCreator(id: string, creatorId: string): Promise<OfferRow | null> {
    return this.prisma.offer.findFirst({
      where: { id, creatorId, deletedAt: null },
      include: WITH_APPLICATION,
    });
  }

  // 최근 순.
  listForStore(storeId: string): Promise<OfferRow[]> {
    return this.prisma.offer.findMany({
      where: { storeId, deletedAt: null },
      include: WITH_APPLICATION,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    });
  }

  // 도착 순. 받은 오퍼 화면은 보여 줄 수 있는 상태만 읽는다(만료·취소는 저장 뒤 목록에서 빠진다).
  listForCreator(creatorId: string): Promise<OfferRow[]> {
    return this.prisma.offer.findMany({
      where: {
        creatorId,
        deletedAt: null,
        status: { in: ['SENT', 'ACCEPTED', 'DECLINED'] },
      },
      include: WITH_APPLICATION,
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
  }

  // 같은 가게·크리에이터의 열린 오퍼. 방금 거절해 아직 되돌릴 수 있는 것도 사장님에게는 "답을 기다려요"라 함께 본다.
  // 협업이 끝나 닫힌(closedAt) 오퍼는 열린 것이 아니다. 부분 유니크 인덱스도 같은 기준이다.
  findOpen(storeId: string, creatorId: string, now: Date): Promise<OfferRow[]> {
    const undoSince = new Date(now.getTime() - DECLINE_UNDO_SECONDS * 1000);
    return this.prisma.offer.findMany({
      where: {
        storeId,
        creatorId,
        deletedAt: null,
        OR: [
          { status: { in: ['SENT', 'ACCEPTED'] }, closedAt: null },
          { status: 'DECLINED', declinedAt: { gt: undoSince } },
        ],
      },
      include: WITH_APPLICATION,
    });
  }

  // 열린 오퍼는 부분 유니크 인덱스가 하나로 막는다. 읽은 뒤 동시에 만들어 위반(P2002)이 나면 null.
  // 오퍼와 판본 1은 한 트랜잭션이다: 판본 없는 오퍼가 남으면 읽는 곳이 모두 깨진다.
  async create(data: NewOffer): Promise<OfferRow | null> {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const offer = await tx.offer.create({
          data: {
            storeId: data.storeId,
            creatorId: data.creatorId,
            applicationId: data.applicationId,
            status: 'SENT',
            latestVersion: 1,
            // 처음 보낸 쪽은 사장님이고 크리에이터가 답할 차례다.
            turn: 'CREATOR',
            initiatedBy: 'STORE',
            createdAt: data.createdAt,
            expiresAt: data.expiresAt,
          },
        });
        await this.versions.insert(tx, {
          offerId: offer.id,
          number: 1,
          authorParty: 'STORE',
          terms: data.terms,
          createdAt: data.createdAt,
        });
        return tx.offer.findUniqueOrThrow({
          where: { id: offer.id },
          include: WITH_APPLICATION,
        });
      });
    } catch (error) {
      if (isUniqueViolation(error)) return null;
      throw error;
    }
  }

  // 새 판본: 오퍼를 읽은 번호·차례·기한 전일 때만 갱신(번호 +1, 차례를 상대에게, 응답 기한을 다시 셈)하고 판본을 넣는다.
  // 수락과 같은 번호 조건을 쓰므로 동시에 오면 하나만 이긴다(수락이 이기면 0행, 새 판본이 이기면 수락이 0행).
  // 0행이면 null이다.
  propose(data: NewProposal): Promise<OfferVersion | null> {
    const number = data.readVersion + 1;
    return this.prisma.$transaction(async (tx) => {
      const { count } = await tx.offer.updateMany({
        where: {
          id: data.offerId,
          status: 'SENT',
          latestVersion: data.readVersion,
          turn: data.author,
          expiresAt: { gt: data.now },
          deletedAt: null,
        },
        data: {
          latestVersion: number,
          turn: turnAfter(data.author),
          expiresAt: data.expiresAt,
        },
      });
      if (count !== 1) return null;
      return this.versions.insert(tx, {
        offerId: data.offerId,
        number,
        authorParty: data.author,
        terms: data.terms,
        idea: data.idea,
        principles: data.principles,
        createdAt: data.now,
      });
    });
  }

  // 사유를 골라 제안을 끝낸다. 읽은 판본 번호가 그대로일 때만이라, 그사이 새 판본이 나왔으면 0행이다.
  // 거절 후 30초 되돌리기(declinedAt)는 쓰지 않는다: 종료는 되돌릴 수 없다.
  async end(
    id: string,
    endedBy: OfferParty,
    status: 'CANCELLED' | 'DECLINED',
    reason: OfferEndReason,
    version: number,
    now: Date,
  ): Promise<boolean> {
    const { count } = await this.prisma.offer.updateMany({
      where: {
        id,
        status: 'SENT',
        latestVersion: version,
        expiresAt: { gt: now },
        deletedAt: null,
      },
      data: { status, endReason: reason, endedBy, respondedAt: now },
    });
    return count === 1;
  }

  // 수락은 기한 전(expiresAt > now)일 때만. 기한과 갱신 사이에 시간이 지나도 늦게 수락되지 않는다.
  // 본 판본 번호(version)가 latest_version과 같을 때만이라, 읽은 뒤 새 판본이 나왔으면 0행이 된다.
  // paymentDueAt이 null이면 낼 돈이 없는 오퍼다. 협업 만들기는 같은 트랜잭션에서 한다.
  accept(
    id: string,
    creatorId: string,
    version: number,
    now: Date,
    paymentDueAt: Date | null,
    alongWith?: InSameTransaction,
  ): Promise<boolean> {
    return this.updateWith(
      (tx) =>
        tx.offer.updateMany({
          where: {
            id,
            creatorId,
            status: 'SENT',
            latestVersion: version,
            expiresAt: { gt: now },
            deletedAt: null,
          },
          data: {
            status: 'ACCEPTED',
            acceptedAt: now,
            respondedAt: now,
            paymentDueAt,
          },
        }),
      alongWith,
    );
  }

  async decline(id: string, creatorId: string, now: Date): Promise<boolean> {
    const { count } = await this.prisma.offer.updateMany({
      where: {
        id,
        creatorId,
        status: 'SENT',
        // 받은 쪽(차례인 쪽)만 거절한다. 내가 쓴 판본의 제안은 종료로 끝낸다.
        turn: 'CREATOR',
        expiresAt: { gt: now },
        deletedAt: null,
      },
      data: {
        status: 'DECLINED',
        declinedAt: now,
        respondedAt: now,
        endReason: 'NO_REASON',
        endedBy: 'CREATOR',
      },
    });
    return count === 1;
  }

  // 되돌리기 시간(30초) 안의 거절만. 그사이 같은 쌍에 새 오퍼가 열렸으면 부분 유니크 위반이라 false.
  async undoDecline(
    id: string,
    creatorId: string,
    now: Date,
  ): Promise<boolean> {
    const undoSince = new Date(now.getTime() - DECLINE_UNDO_SECONDS * 1000);
    try {
      const { count } = await this.prisma.offer.updateMany({
        where: {
          id,
          creatorId,
          status: 'DECLINED',
          declinedAt: { gt: undoSince },
          deletedAt: null,
        },
        data: {
          status: 'SENT',
          declinedAt: null,
          respondedAt: null,
          endReason: null,
          endedBy: null,
        },
      });
      return count === 1;
    } catch (error) {
      if (isUniqueViolation(error)) return false;
      throw error;
    }
  }

  // 취소는 읽은 상태(SENT 또는 ACCEPTED)에서만, 그 상태의 기한 전일 때만.
  // SENT는 가게가 쓴 판본이 최신(차례가 크리에이터)일 때만이다: 읽은 뒤 크리에이터가 새 판본을 내 차례가 가게로 넘어왔으면 0행이다.
  // 낼 돈이 없는 ACCEPTED(paymentDueAt null)는 서비스가 먼저 거르므로 여기까지 오지 않는다.
  cancel(
    id: string,
    storeId: string,
    from: 'SENT' | 'ACCEPTED',
    now: Date,
    alongWith?: InSameTransaction,
  ): Promise<boolean> {
    const alive =
      from === 'SENT'
        ? { expiresAt: { gt: now }, turn: 'CREATOR' as const }
        : { paymentDueAt: { gt: now } };
    return this.updateWith(
      (tx) =>
        tx.offer.updateMany({
          where: { id, storeId, status: from, deletedAt: null, ...alive },
          data: { status: 'CANCELLED' },
        }),
      alongWith,
    );
  }

  // 기한이 지나 만료로 저장한다. 읽은 상태가 그대로일 때만.
  expire(
    id: string,
    from: OfferStatus,
    alongWith?: InSameTransaction,
  ): Promise<boolean> {
    return this.updateWith(
      (tx) =>
        tx.offer.updateMany({
          where: { id, status: from, deletedAt: null },
          data: { status: 'EXPIRED' },
        }),
      alongWith,
    );
  }

  // 결제가 승인돼 결제 기한을 지운다. 오퍼는 ACCEPTED 그대로다. 이 갱신이 오퍼 행을 잠그므로,
  // 취소·만료(오퍼 → 협업 순)와 같은 순서로 잠가 교착을 피하려면 결제 승인 트랜잭션은 이것을 먼저 부른다.
  // ACCEPTED가 아니면(이미 만료·취소) 0행이라 false다.
  async clearPaymentDue(
    id: string,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const { count } = await tx.offer.updateMany({
      where: { id, status: 'ACCEPTED', deletedAt: null },
      data: { paymentDueAt: null },
    });
    return count === 1;
  }

  // 오퍼 행을 잠그고 아직 ACCEPTED인지 본다. 결제를 만드는 트랜잭션이 단계를 확인하고 쓰는 사이에
  // 취소·만료·승인이 끼어들지 못하게 하려고, 승인과 같은 순서(오퍼 → 결제)로 가장 먼저 잡는다.
  async lockAccepted(
    id: string,
    tx: Prisma.TransactionClient,
  ): Promise<boolean> {
    const rows = await tx.$queryRaw<{ id: string }[]>`
      SELECT id FROM offers
      WHERE id = ${id}::uuid AND status = 'ACCEPTED' AND deleted_at IS NULL
      FOR UPDATE`;
    return rows.length === 1;
  }

  // 오퍼 갱신(조건부)과 alongWith를 한 트랜잭션으로 묶는다. 갱신이 0행이면 alongWith는 부르지 않는다.
  // alongWith가 없으면 문장 하나짜리 갱신이라 트랜잭션을 열지 않는다: 목록을 읽을 때 여러 오퍼를
  // 동시에 정리하므로, 불필요한 대화형 트랜잭션이 연결을 붙잡아 풀이 마르는 것을 막는다.
  private async updateWith(
    update: (client: Pick<Prisma.TransactionClient, 'offer'>) => Promise<{
      count: number;
    }>,
    alongWith?: InSameTransaction,
  ): Promise<boolean> {
    if (!alongWith) return (await update(this.prisma)).count === 1;
    try {
      return await this.prisma.$transaction(async (tx) => {
        const { count } = await update(tx);
        if (count !== 1) return false;
        if ((await alongWith(tx)) === false) throw new Rollback();
        return true;
      });
    } catch (error) {
      if (error instanceof Rollback) return false;
      throw error;
    }
  }
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}
