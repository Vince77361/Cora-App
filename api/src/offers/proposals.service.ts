import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OfferParty } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { InstagramService } from '../instagram/instagram.service';
import { StoresService } from '../stores/stores.service';
import { UsersService } from '../users/users.service';
import { ProposalDetailModel } from './dto/proposal-detail.model';
import { ProposalRowModel } from './dto/proposal-row.model';
import { ProposalTab } from './dto/proposals-query.dto';
import { needsInstagram, viewForCreator, viewForStore } from './offer-rules';
import {
  latestVersionOf,
  OfferRow,
  OffersRepository,
} from './offers.repository';
import { OffersService } from './offers.service';
import {
  changedFields,
  daysLeftToAnswer,
  endKind,
  isCounter,
  partyOf,
  proposalGroup,
  termsOfVersion,
  versionModelOf,
} from './proposal-rules';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 보이는 쪽의 순서: 내가 응답할 차례 → 상대 대기 → 끝남.
const GROUP_ORDER = { MY_TURN: 0, WAITING: 1, ENDED: 2 } as const;

// 제안함(F3)과 제안 상세. 오퍼를 읽기만 한다: 판본을 내고 수락·종료하는 일은 OffersService가 한다.
@Injectable()
export class ProposalsService {
  constructor(
    private readonly offers: OffersRepository,
    private readonly offersService: OffersService,
    private readonly stores: StoresService,
    private readonly creators: CreatorsService,
    private readonly users: UsersService,
    private readonly collaborations: CollaborationsRepository,
    private readonly instagram: InstagramService,
    private readonly config: ConfigService,
    private readonly clock: Clock,
  ) {}

  // 사장님은 내 가게의 오퍼, 크리에이터는 내가 받은·보낸 오퍼. 기한이 지난 오퍼는 목록에 올리기 전에 만료로 저장한다.
  async list(userId: string, tab: ProposalTab): Promise<ProposalRowModel[]> {
    const party = await this.partyOfRole(userId);
    const now = this.clock.now();
    const ownerKey =
      party === 'STORE'
        ? (await this.stores.requireMyStore(userId)).id
        : userId;
    const rows = await this.offersService.settleAll(
      await this.offers.listForProposals(party, ownerKey),
      now,
    );
    const collaborationIds = await this.collaborationIds(rows);
    const cards = new Map<
      string,
      Awaited<ReturnType<StoresService['getOfferCard']>>
    >();
    const items: { row: ProposalRowModel; at: number }[] = [];
    for (const offer of rows) {
      const group = proposalGroup(offer, party, now);
      if ((tab === 'ended') !== (group === 'ENDED')) continue;
      const counterpart = await this.counterpartOf(offer, party, cards);
      // 프로필이 지워진 크리에이터나 공개되지 않은 가게는 보여 줄 것이 없어 뺀다(받은 오퍼 목록과 같다).
      if (!counterpart) continue;
      const latest = latestVersionOf(offer);
      items.push({
        at: latest.createdAt.getTime(),
        row: {
          offerId: offer.id,
          counterpart,
          group,
          version: latest.number,
          counter: isCounter(latest, party),
          format: latest.format,
          pieces: latest.pieces,
          daysLeft:
            group === 'WAITING' ? daysLeftToAnswer(offer.expiresAt, now) : null,
          endKind: group === 'ENDED' ? endKind(offer, now) : null,
          endReason: group === 'ENDED' ? offer.endReason : null,
          collaborationId: collaborationIds.get(offer.id) ?? null,
        },
      });
    }
    // 같은 묶음에서는 최근 판본이 위로 온다.
    items.sort(
      (a, b) =>
        GROUP_ORDER[a.row.group] - GROUP_ORDER[b.row.group] || b.at - a.at,
    );
    return items.map((item) => item.row);
  }

  // 당사자만 본다. 남의 제안은 없는 제안과 같게 404다.
  async get(userId: string, id: string): Promise<ProposalDetailModel> {
    const found = UUID.test(id) ? await this.offers.findById(id) : null;
    // 당사자는 가게가 공개 상태인지와 관계없이 자기 제안을 읽는다.
    const card = found ? await this.stores.getPartyCard(found.storeId) : null;
    const party = found && card ? partyOf(found, userId, card.ownerId) : null;
    if (!found || !card || !party) throw this.notFound();

    const now = this.clock.now();
    const [row] = await this.offersService.settleAll([found], now);
    if (!row) throw this.notFound();

    const latest = latestVersionOf(row);
    const previousRow =
      row.latestVersion > 1
        ? await this.offers.findVersion(row.id, row.latestVersion - 1)
        : null;
    const latestModel = versionModelOf(latest);
    const previous = previousRow ? versionModelOf(previousRow) : null;
    const group = proposalGroup(row, party, now);
    const status =
      party === 'STORE' ? viewForStore(row, now) : viewForCreator(row, now);
    const connected =
      (await this.instagram.getConnection(row.creatorId)) !== null;
    const collaboration = await this.collaborations.findByOfferId(row.id);

    let counterpart: ProposalDetailModel['counterpart'];
    if (party === 'STORE') {
      const creator = await this.creators.getSummary(row.creatorId);
      counterpart = {
        userId: row.creatorId,
        name: creator?.displayName ?? '크리에이터',
        photoUrl: creator?.photoUrl ?? null,
      };
    } else {
      counterpart = {
        userId: card.ownerId,
        name: card.name,
        photoUrl: card.coverPhotoUrl,
      };
    }
    return {
      offerId: row.id,
      status,
      myParty: party,
      group,
      latest: latestModel,
      previous,
      changed: changedFields(previous, latestModel),
      store: {
        id: card.id,
        name: card.name,
        recruitLine: card.recruitLine,
      },
      counterpart,
      feeRate: this.feeRate(),
      // 답을 기다리는 제안에만 알린다. 끝난 제안에는 해당이 없다.
      needsInstagram:
        status === 'WAITING' &&
        needsInstagram(termsOfVersion(latest), connected),
      expiresAt: row.expiresAt,
      endKind: group === 'ENDED' ? endKind(row, now) : null,
      endReason: group === 'ENDED' ? row.endReason : null,
      collaborationId: collaboration?.id ?? null,
    };
  }

  // 사장님과 크리에이터만 제안함을 쓴다(브랜드는 5번 설계가 같은 화면을 채운다).
  private async partyOfRole(userId: string): Promise<OfferParty> {
    const role = await this.users.getRole(userId);
    if (role === 'STORE' || role === 'CREATOR') return role;
    throw new AppError('FORBIDDEN', '가게나 크리에이터 계정만 쓸 수 있어요.');
  }

  private async counterpartOf(
    offer: OfferRow,
    party: OfferParty,
    cards: Map<string, Awaited<ReturnType<StoresService['getOfferCard']>>>,
  ): Promise<{ name: string; photoUrl: string | null } | null> {
    if (party === 'STORE') {
      const creator = await this.creators.getSummary(offer.creatorId);
      return creator
        ? { name: creator.displayName, photoUrl: creator.photoUrl }
        : null;
    }
    if (!cards.has(offer.storeId)) {
      cards.set(offer.storeId, await this.stores.getOfferCard(offer.storeId));
    }
    const card = cards.get(offer.storeId);
    return card
      ? { name: card.summary.name, photoUrl: card.summary.coverPhotoUrl }
      : null;
  }

  private async collaborationIds(
    rows: OfferRow[],
  ): Promise<Map<string, string>> {
    const found = await this.collaborations.mapByOfferIds(
      rows.map((row) => row.id),
    );
    return new Map([...found].map(([offerId, c]) => [offerId, c.id]));
  }

  private feeRate(): number {
    const rate = Number(this.config.getOrThrow('FEE_RATE_STORE_OFFER'));
    if (!Number.isInteger(rate) || rate < 0 || rate > 100) {
      throw new Error(`수수료율이 올바르지 않아요: ${rate}`);
    }
    return rate;
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '제안을 찾을 수 없어요.');
  }
}
