import { Injectable } from '@nestjs/common';
import {
  ContentFormat,
  OfferParty,
  OfferVersion,
  Prisma,
} from '@prisma/client';
import { OfferTermsModel } from '../stores/dto/offer-terms.model';

export interface NewOfferVersion {
  offerId: string;
  number: number;
  authorParty: OfferParty;
  terms: OfferTermsModel;
  idea?: string | null;
  principles?: string[];
  series?: {
    name: string | null;
    format: ContentFormat | null;
    note: string | null;
  } | null;
  // 만든 시각을 DB 기본값이 아니라 Clock으로 정한다. 오퍼의 보낸 시각과 같은 기준이다.
  createdAt: Date;
}

// 판본은 만들기만 한다. 고치거나 지우는 함수는 일부러 없다.
// 오퍼의 latestVersion을 올리는 일과 한 트랜잭션이어야 해서 tx를 반드시 받는다(오퍼 저장소가 연다).
@Injectable()
export class OfferVersionsRepository {
  insert(
    tx: Prisma.TransactionClient,
    data: NewOfferVersion,
  ): Promise<OfferVersion> {
    const { terms } = data;
    return tx.offerVersion.create({
      data: {
        offerId: data.offerId,
        number: data.number,
        authorParty: data.authorParty,
        format: terms.format,
        pieces: terms.pieces,
        voucherName: terms.voucherName,
        voucherValue: terms.voucherValue,
        voucherPeople: terms.voucherPeople,
        fixedCash: terms.fixedCash,
        viewRatePerThousand: terms.viewRatePerThousand,
        perViewCap: terms.perViewCap,
        usageRights: terms.usageRights,
        idea: data.idea ?? null,
        principles: data.principles ?? [],
        seriesName: data.series?.name ?? null,
        seriesFormat: data.series?.format ?? null,
        seriesNote: data.series?.note ?? null,
        createdAt: data.createdAt,
      },
    });
  }
}
