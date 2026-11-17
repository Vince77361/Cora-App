import { Injectable } from '@nestjs/common';
import { Collaboration, TermsVersion } from '@prisma/client';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { BrandsService } from '../brands/brands.service';
import { CreatorsService } from '../creators/creators.service';
import { ProposalInboxRowModel } from './dto/proposal-inbox-row.model';
import {
  CHOSEN_DROP_REASONS,
  inboxEndKind,
  inboxGroup,
  INBOX_STAGES,
  isCounterVersion,
  myDropReasonOf,
} from './proposal-inbox';
import { TermsService } from './terms.service';

// 보이는 순서: 내가 응답할 차례 → 상대 대기 → 끝남(가게 오퍼 줄과 같다).
const GROUP_ORDER = { MY_TURN: 0, WAITING: 1, ENDED: 2 } as const;

interface Counterpart {
  name: string;
  photoUrl: string | null;
}

// 제안함(F3)의 브랜드 계약 줄. 협업과 조건 판본을 읽기만 한다: 확인하고 새 판본을 내고 그만두는 일은 NegotiationService와
// CollaborationsService가 한다. 브랜드와 크리에이터 모두 부른다(가게 사장님은 당사자인 브랜드 협업이 없어 빈 목록이다).
@Injectable()
export class ProposalInboxService {
  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly terms: TermsService,
    private readonly brands: BrandsService,
    private readonly creators: CreatorsService,
  ) {}

  async list(userId: string): Promise<ProposalInboxRowModel[]> {
    const found = await this.collaborations.listBrandContractsForInbox(
      userId,
      INBOX_STAGES,
      CHOSEN_DROP_REASONS,
    );
    const latestById = await this.terms.latestMany(found.map((c) => c.id));
    const counterparts = await this.counterpartsOf(userId, found);

    const items: { row: ProposalInboxRowModel; at: number }[] = [];
    for (const collaboration of found) {
      const latest = latestById.get(collaboration.id);
      // 조건이 만들어지기 전에 끝난 협업은 보여 줄 판본이 없어 올리지 않는다.
      if (!latest) continue;
      const mine = collaboration.creatorId === userId;
      const group = inboxGroup({
        stage: collaboration.stage,
        myConfirmed: confirmedBy(latest, mine),
        otherConfirmed: confirmedBy(latest, !mine),
      });
      if (!group) continue;
      const counterpartId = mine
        ? collaboration.commissionerId
        : collaboration.creatorId;
      const updatedAt = new Date(
        Math.max(latest.updatedAt.getTime(), collaboration.updatedAt.getTime()),
      );
      items.push({
        at: updatedAt.getTime(),
        row: {
          kind: 'BRAND_CONTRACT',
          collaborationId: collaboration.id,
          counterpart: counterparts.get(counterpartId) ?? {
            name: mine ? '브랜드' : '크리에이터',
            photoUrl: null,
          },
          group,
          version: latest.version,
          counter: isCounterVersion(latest, userId),
          format: latest.format,
          pieces: latest.pieces,
          endKind: inboxEndKind(collaboration.stage),
          myDropReason: myDropReasonOf(collaboration, userId),
          updatedAt: updatedAt.toISOString(),
        },
      });
    }
    // 같은 묶음에서는 최근 것이 위로 온다.
    items.sort(
      (a, b) =>
        GROUP_ORDER[a.row.group] - GROUP_ORDER[b.row.group] ||
        b.at - a.at ||
        a.row.collaborationId.localeCompare(b.row.collaborationId),
    );
    return items.map((item) => item.row);
  }

  // 상대의 이름과 사진. 내가 크리에이터면 브랜드, 브랜드면 크리에이터다. 프로필이 지워졌으면 맵에 없다.
  private async counterpartsOf(
    userId: string,
    found: Collaboration[],
  ): Promise<Map<string, Counterpart>> {
    const result = new Map<string, Counterpart>();
    const brandIds = new Set<string>();
    const creatorIds = new Set<string>();
    for (const c of found) {
      if (c.creatorId === userId) brandIds.add(c.commissionerId);
      else creatorIds.add(c.creatorId);
    }
    if (brandIds.size > 0) {
      const profiles = await this.brands.findProfiles([...brandIds]);
      for (const [id, profile] of profiles) {
        result.set(id, { name: profile.name, photoUrl: profile.photoUrl });
      }
    }
    await Promise.all(
      [...creatorIds].map(async (id) => {
        const summary = await this.creators.getSummary(id);
        if (summary) {
          result.set(id, {
            name: summary.displayName,
            photoUrl: summary.photoUrl,
          });
        }
      }),
    );
    return result;
  }
}

// 최신 판본을 그쪽이 확인했는가(크리에이터 쪽이면 creator, 아니면 brand).
function confirmedBy(
  latest: Pick<TermsVersion, 'brandConfirmedAt' | 'creatorConfirmedAt'>,
  creatorSide: boolean,
): boolean {
  return (
    (creatorSide ? latest.creatorConfirmedAt : latest.brandConfirmedAt) !== null
  );
}
