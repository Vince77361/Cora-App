import { Injectable } from '@nestjs/common';
import { Offer, OfferStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DECLINE_UNDO_SECONDS } from './offer-rules';

// 연결된 지원의 상태를 함께 읽어, 이미 닫힌 지원에 닫기를 다시 부르지 않게 한다.
const WITH_APPLICATION = {
  application: { select: { status: true } },
} satisfies Prisma.OfferInclude;

export type OfferRow = Prisma.OfferGetPayload<{
  include: typeof WITH_APPLICATION;
}>;

export interface NewOffer {
  storeId: string;
  creatorId: string;
  applicationId: string | null;
  format: Offer['format'];
  rewardType: Offer['rewardType'];
  voucherName: string | null;
  voucherValue: number | null;
  perViewAmount: number | null;
  perViewCap: number | null;
  createdAt: Date;
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
  constructor(private readonly prisma: PrismaService) {}

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
  findOpen(storeId: string, creatorId: string, now: Date): Promise<OfferRow[]> {
    const undoSince = new Date(now.getTime() - DECLINE_UNDO_SECONDS * 1000);
    return this.prisma.offer.findMany({
      where: {
        storeId,
        creatorId,
        deletedAt: null,
        OR: [
          { status: { in: ['SENT', 'ACCEPTED'] } },
          { status: 'DECLINED', declinedAt: { gt: undoSince } },
        ],
      },
      include: WITH_APPLICATION,
    });
  }

  // 열린 오퍼는 부분 유니크 인덱스가 하나로 막는다. 읽은 뒤 동시에 만들어 위반(P2002)이 나면 null.
  async create(data: NewOffer): Promise<OfferRow | null> {
    try {
      return await this.prisma.offer.create({
        data: { ...data, status: 'SENT' },
        include: WITH_APPLICATION,
      });
    } catch (error) {
      if (isUniqueViolation(error)) return null;
      throw error;
    }
  }

  // 수락은 기한 전(expiresAt > now)일 때만. 기한과 갱신 사이에 시간이 지나도 늦게 수락되지 않는다.
  // paymentDueAt이 null이면 낼 돈이 없는 오퍼다. 협업 만들기는 같은 트랜잭션에서 한다.
  accept(
    id: string,
    creatorId: string,
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
        expiresAt: { gt: now },
        deletedAt: null,
      },
      data: { status: 'DECLINED', declinedAt: now, respondedAt: now },
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
        data: { status: 'SENT', declinedAt: null, respondedAt: null },
      });
      return count === 1;
    } catch (error) {
      if (isUniqueViolation(error)) return false;
      throw error;
    }
  }

  // 취소는 읽은 상태(SENT 또는 ACCEPTED)에서만, 그 상태의 기한 전일 때만.
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
        ? { expiresAt: { gt: now } }
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

  // 오퍼 갱신(조건부)과 alongWith를 한 트랜잭션으로 묶는다. 갱신이 0행이면 alongWith는 부르지 않는다.
  private async updateWith(
    update: (tx: Prisma.TransactionClient) => Promise<{ count: number }>,
    alongWith?: InSameTransaction,
  ): Promise<boolean> {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const { count } = await update(tx);
        if (count !== 1) return false;
        if (alongWith && (await alongWith(tx)) === false) throw new Rollback();
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
