import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  CollaborationStage,
  TermsVersion,
} from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { needsInstagram } from '../offers/offer-rules';
import { PrinciplesService } from '../principles/principles.service';
import { matchScore } from '../recommendations/match-score';
import { TermsLatestModel, TermsVersionModel } from './dto/terms-version.model';
import { termsNotice, toTermsVersionModel } from './terms-rules';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 판본을 확인할 수 있는 단계. AGREED는 이미 한 확인을 다시 눌렀을 때 같은 결과를 돌려주기 위한 것이다.
const CONFIRMABLE: CollaborationStage[] = ['MATCHED', 'NEGOTIATING', 'AGREED'];

// 브랜드 계약의 조건 판본을 당사자에게 보여 주고 확인받는 서비스(06 화면).
// 확인은 협업 행을 잠근 트랜잭션 안에서 조건부로 한 번만 반영한다: 같은 판본을 양쪽이 동시에 눌러도,
// 확인과 새 판본이 동시에 와도 "서로 다른 판본에 합의한" 상태가 생기지 않는다.
@Injectable()
export class NegotiationService {
  private readonly logger = new Logger(NegotiationService.name);

  constructor(
    private readonly collaborations: CollaborationsRepository,
    private readonly repository: TermsRepository,
    private readonly terms: TermsService,
    private readonly campaigns: CampaignsService,
    private readonly brands: BrandsService,
    private readonly creators: CreatorsService,
    private readonly principles: PrinciplesService,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
  ) {}

  async getLatest(
    userId: string,
    collaborationId: string,
  ): Promise<TermsLatestModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const latest = await this.terms.latest(collaboration.id);
    const campaign = collaboration.campaignId
      ? await this.campaigns.getById(collaboration.campaignId)
      : null;
    if (!latest || !campaign) throw this.notFound();

    const isCreator = collaboration.creatorId === userId;
    const [principles, creator, brands] = await Promise.all([
      this.principles.find(collaboration.creatorId),
      this.creators.getSummary(collaboration.creatorId),
      this.brands.findProfiles([collaboration.commissionerId]),
    ]);
    const brand = brands.get(collaboration.commissionerId);
    return {
      terms: toTermsVersionModel(latest, collaboration.commissionerId),
      notice: termsNotice(principles),
      reasons:
        principles && brand
          ? matchScore(principles, {
              industry: brand.industry,
              fee: campaign.fee,
              notRequired: campaign.notRequired,
              trialDays: campaign.trialDays,
            }).reasons
          : [],
      trialDays: campaign.trialDays,
      followers: creator?.followers ?? null,
      myTurn:
        (isCreator ? latest.creatorConfirmedAt : latest.brandConfirmedAt) ===
        null,
      mine: latest.proposedById === userId,
      needsInstagram:
        isCreator &&
        needsInstagram(
          { format: latest.format, perViewCap: latest.perfCap },
          creator?.instagramConnected ?? false,
        ),
    };
  }

  // 내 쪽 확인 시각을 조건부로 채운다. 협업이 MATCHED면 NEGOTIATING으로, 양쪽이 다 확인했으면 AGREED로 옮긴다.
  // 이미 확인한 판본을 다시 누르면 아무것도 바꾸지 않고 같은 판본을 돌려준다(알림도 다시 보내지 않는다).
  async confirm(
    userId: string,
    collaborationId: string,
    version: number,
  ): Promise<TermsVersionModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const isCreator = collaboration.creatorId === userId;
    // 연동 여부는 트랜잭션 밖에서 읽는다(판본을 읽은 뒤 연동이 바뀌어도 그 순간의 사실로 충분하다).
    const connected = isCreator
      ? ((await this.creators.getSummary(userId))?.instagramConnected ?? false)
      : true;
    const now = this.clock.now();

    const { row, applied } = await this.repository.transaction(async (tx) => {
      await this.repository.lockCollaboration(collaboration.id, tx);
      const fresh = await this.collaborations.findById(collaboration.id, tx);
      const latest = await this.terms.latest(collaboration.id, tx);
      if (!fresh || !latest || !CONFIRMABLE.includes(fresh.stage)) {
        throw new AppError('CONFLICT', '지금은 조건을 확인할 수 없어요.');
      }
      if (latest.version !== version) {
        throw new AppError('STALE_VERSION', '이전 판본이라 수락할 수 없어요.', {
          latestVersion: latest.version,
        });
      }
      if (
        isCreator &&
        needsInstagram(
          { format: latest.format, perViewCap: latest.perfCap },
          connected,
        )
      ) {
        throw new AppError(
          'CONFLICT',
          '인스타그램을 연동하면 수락할 수 있어요.',
        );
      }
      const applied = await this.repository.markConfirmed(
        collaboration.id,
        version,
        isCreator ? 'CREATOR' : 'BRAND',
        now,
        tx,
      );
      if (!applied) return { row: latest, applied };
      if (fresh.stage === 'MATCHED') {
        await this.collaborations.advance(
          collaboration.id,
          'MATCHED',
          'NEGOTIATING',
          {},
          tx,
        );
      }
      const after = (await this.terms.latest(collaboration.id, tx)) ?? latest;
      if (after.brandConfirmedAt && after.creatorConfirmedAt) {
        await this.collaborations.advance(
          collaboration.id,
          'NEGOTIATING',
          'AGREED',
          {},
          tx,
        );
      }
      return { row: after, applied };
    });

    if (applied) await this.notifyConfirmed(collaboration, userId, row);
    return toTermsVersionModel(row, collaboration.commissionerId);
  }

  // 커밋 뒤에 상대에게 알린다. 실패해도 이미 저장된 확인은 유효하다(원장 판단 R22).
  private async notifyConfirmed(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
  ): Promise<void> {
    const byCreator = collaboration.creatorId === userId;
    try {
      const actor = (byCreator
        ? await this.creators.getActor(userId)
        : await this.brands.getActor(userId)) ?? {
        userId,
        name: byCreator ? '크리에이터' : '브랜드',
        photoPath: null,
      };
      await this.notifications.notify({
        userId: byCreator
          ? collaboration.commissionerId
          : collaboration.creatorId,
        role: byCreator ? 'BRAND' : 'CREATOR',
        kind: 'TERMS_CONFIRMED',
        actor,
        params: { version: row.version },
        target: { kind: 'TERMS', id: collaboration.id },
        dedupeKey: `terms-confirmed:${collaboration.id}:${row.version}:${userId}`,
      });
    } catch (error) {
      this.logger.warn(
        `조건 확인 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 당사자가 아니거나 브랜드 계약이 아니면 없는 협업과 같게 404다.
  private async requireParty(
    userId: string,
    collaborationId: string,
  ): Promise<Collaboration> {
    const row = UUID.test(collaborationId)
      ? await this.collaborations.findById(collaborationId)
      : null;
    if (
      !row ||
      row.kind !== 'BRAND_CONTRACT' ||
      (row.commissionerId !== userId && row.creatorId !== userId)
    ) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    return row;
  }

  private notFound(): AppError {
    return new AppError('NOT_FOUND', '조건을 찾을 수 없어요.');
  }
}
