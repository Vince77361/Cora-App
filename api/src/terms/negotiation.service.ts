import { Injectable, Logger } from '@nestjs/common';
import {
  Collaboration,
  CollaborationStage,
  Prisma,
  TermsVersion,
} from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import {
  BRAND_PAYMENT_LOCK_MINUTES,
  canTransition,
  negotiableStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { kstDateString } from '../common/kst';
import { AppError } from '../common/errors/app-error';
import { ConversationsService } from '../conversations/conversations.service';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { needsInstagram } from '../offers/offer-rules';
import { PrinciplesService } from '../principles/principles.service';
import { matchScore } from '../recommendations/match-score';
import { ProposeRewardDto } from './dto/propose-reward.dto';
import { TermsHistoryModel } from './dto/terms-history.model';
import { TermsLatestModel, TermsVersionModel } from './dto/terms-version.model';
import { nextTermsValues, termsProblem, TermsEdit } from './proposal-rules';
import { diffTerms } from './terms-diff';
import {
  agreementOf,
  isMyTurn,
  principleFieldLabels,
  termsNotice,
  toTermsVersionModel,
} from './terms-rules';
import { TermsRepository } from './terms.repository';
import { TermsService } from './terms.service';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const INSTAGRAM_REQUIRED_MESSAGE = '인스타그램을 연동하면 수락할 수 있어요.';
const PAYMENT_IN_PROGRESS_MESSAGE =
  '브랜드가 결제를 진행하고 있어요. 잠시 뒤 다시 시도해 주세요.';
const MINUTE_MS = 60 * 1000;

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
    private readonly conversations: ConversationsService,
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
    const [previous, principles, creator, brands] = await Promise.all([
      this.terms.versionBefore(collaboration.id, latest.version),
      this.principles.find(collaboration.creatorId),
      this.creators.getSummary(collaboration.creatorId),
      this.brands.findProfiles([collaboration.commissionerId]),
    ]);
    const brand = brands.get(collaboration.commissionerId);
    return {
      terms: toTermsVersionModel(
        latest,
        collaboration.commissionerId,
        previous,
      ),
      notice: termsNotice(principles),
      fields: principleFieldLabels(principles),
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
      myTurn: isMyTurn(latest, isCreator),
      mine: latest.proposedById === userId,
      needsInstagram:
        isCreator &&
        needsInstagram(
          { format: latest.format, perViewCap: latest.perfCap },
          creator?.instagramConnected ?? false,
        ),
    };
  }

  // 판본 이력(12 화면). 최신이 먼저이고, 판본마다 바로 앞 판본과 비교한 바뀐 항목을 담는다.
  // editable은 지금 조건 수정 제안을 낼 수 있는가: 협의할 수 있는 단계이고 브랜드 결제가 진행 중이 아니다.
  async list(
    userId: string,
    collaborationId: string,
  ): Promise<TermsHistoryModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const rows = await this.terms.list(collaboration.id);
    const latest = rows[0];
    if (!latest) throw this.notFound();
    const paymentOpen = await this.collaborations.hasOpenBrandPayment(
      collaboration.id,
      this.paymentLockSince(this.clock.now()),
    );
    return {
      versions: rows.map((row, index) =>
        toTermsVersionModel(
          row,
          collaboration.commissionerId,
          rows[index + 1] ?? null,
        ),
      ),
      agreement: agreementOf(latest),
      editable: negotiableStages.includes(collaboration.stage) && !paymentOpen,
    };
  }

  // 내 쪽 확인 시각을 조건부로 채운다. 협업이 MATCHED면 NEGOTIATING으로, 양쪽이 다 확인했으면 AGREED로 옮긴다.
  // 이미 확인한 판본을 다시 누르면 아무것도 바꾸지 않고 같은 판본을 돌려준다(안내 줄도 알림도 다시 남기지 않는다).
  // 확인이 반영되면 같은 트랜잭션에서 대화방에 안내 줄을 남기고(한쪽 TERMS_CONFIRMED, 양쪽 TERMS_AGREED) 커밋 뒤에 내보낸다.
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
    const actor = await this.actorOf(collaboration, userId);
    const now = this.clock.now();

    const { row, applied, roomId, lineId } = await this.repository.transaction(
      async (tx) => {
        await this.repository.lockCollaboration(collaboration.id, tx);
        const fresh = await this.collaborations.findById(collaboration.id, tx);
        const latest = await this.terms.latest(collaboration.id, tx);
        if (!fresh || !latest || !negotiableStages.includes(fresh.stage)) {
          throw new AppError('CONFLICT', '지금은 조건을 확인할 수 없어요.');
        }
        if (latest.version !== version) {
          throw new AppError(
            'STALE_VERSION',
            '이전 판본이라 수락할 수 없어요.',
            { latestVersion: latest.version },
          );
        }
        if (
          isCreator &&
          needsInstagram(
            { format: latest.format, perViewCap: latest.perfCap },
            connected,
          )
        ) {
          throw new AppError('CONFLICT', INSTAGRAM_REQUIRED_MESSAGE);
        }
        const applied = await this.repository.markConfirmed(
          collaboration.id,
          version,
          isCreator ? 'CREATOR' : 'BRAND',
          now,
          tx,
        );
        if (!applied) {
          return { row: latest, applied, roomId: null, lineId: null };
        }
        if (fresh.stage === 'MATCHED') {
          await this.advanceOrFail(
            collaboration.id,
            'MATCHED',
            'NEGOTIATING',
            tx,
          );
        }
        const after = (await this.terms.latest(collaboration.id, tx)) ?? latest;
        const agreed = !!after.brandConfirmedAt && !!after.creatorConfirmedAt;
        if (agreed) {
          await this.advanceOrFail(
            collaboration.id,
            'NEGOTIATING',
            'AGREED',
            tx,
          );
        }
        const roomId = await this.conversations.idForCollaboration(
          collaboration.id,
          tx,
        );
        const line = roomId
          ? await this.conversations.postSystem(
              roomId,
              agreed ? 'TERMS_AGREED' : 'TERMS_CONFIRMED',
              agreed
                ? { version: after.version }
                : { name: actor.name, version: after.version },
              tx,
            )
          : null;
        return { row: after, applied, roomId, lineId: line?.id ?? null };
      },
    );

    if (applied) {
      await this.publishRoom(roomId, lineId, 'TERMS');
      await this.notifyConfirmed(collaboration, userId, row);
    }
    return toTermsVersionModel(
      row,
      collaboration.commissionerId,
      await this.terms.versionBefore(collaboration.id, row.version),
    );
  }

  // 협업 중에 새 판본을 낸다. 돈과 혜택만 바꾸는 길(F2)과 모든 항목을 바꾸는 수정 제안 화면이 이 한 함수를 쓴다.
  // 빠진 항목은 직전 판본에서 옮기고, 낸 쪽은 "확인함", 상대는 "대기"이며 단계는 NEGOTIATING이다(합의돼 있었다면 합의가 취소된다).
  // 확인·그만두기와 같은 잠금 안에서 한다: 같은 판본을 보고 두 쪽이 동시에 내면 하나만 다음 판본이 되고 나머지는 409 STALE_VERSION이고,
  // 확인과 새 판본이 엇갈려도 지난 판본이 합의되지 않는다.
  // 같은 트랜잭션에서: 브랜드가 아직 결제하지 않은 계약은 무효가 되고(크리에이터의 동의 취소) 안내 줄이 남는다.
  async proposeTerms(
    userId: string,
    collaborationId: string,
    input: ProposeRewardDto,
  ): Promise<TermsVersionModel> {
    const collaboration = await this.requireParty(userId, collaborationId);
    const isCreator = collaboration.creatorId === userId;
    const connected = isCreator
      ? ((await this.creators.getSummary(userId))?.instagramConnected ?? false)
      : true;
    const actor = await this.actorOf(collaboration, userId);
    // 생성된 앱 클라이언트는 안 쓴 칸을 null로 보낸다: 성과 추가 말고는 null을 "빠짐"으로 읽는다(성과 추가의 null은 끔이다).
    const edit: TermsEdit = {
      title: input.title ?? undefined,
      fee: input.fee ?? undefined,
      performance:
        input.performance === undefined || input.performance === null
          ? input.performance
          : {
              ratePer1000: input.performance.ratePer1000,
              cap: input.performance.cap,
            },
      startDate: input.startDate ?? undefined,
      format: input.format ?? undefined,
      pieces: input.pieces ?? undefined,
      productProvided: input.productProvided ?? undefined,
      revisionScope: input.revisionScope ?? undefined,
      usageRights: input.usageRights ?? undefined,
      payoutDays: input.payoutDays ?? undefined,
    };
    const now = this.clock.now();

    const { created, previous, roomId, lineIds } =
      await this.repository.transaction(async (tx) => {
        await this.repository.lockCollaboration(collaboration.id, tx);
        const fresh = await this.collaborations.findById(collaboration.id, tx);
        const latest = await this.terms.latest(collaboration.id, tx);
        if (!fresh || !latest || !negotiableStages.includes(fresh.stage)) {
          throw new AppError('CONFLICT', '지금은 조건을 제안할 수 없어요.');
        }
        if (latest.version !== input.baseVersion) {
          throw new AppError(
            'STALE_VERSION',
            '상대가 먼저 새 조건을 제안했어요.',
            { latestVersion: latest.version },
          );
        }
        // 브랜드가 결제창을 연 사이에 조건이 바뀌면 결제 금액이 달라지므로 막는다(60분이 지나면 풀린다).
        if (
          await this.collaborations.hasOpenBrandPayment(
            collaboration.id,
            this.paymentLockSince(now),
            tx,
          )
        ) {
          throw new AppError('CONFLICT', PAYMENT_IN_PROGRESS_MESSAGE);
        }
        const values = nextTermsValues(
          latest,
          edit,
          isCreator ? 'CREATOR' : 'BRAND',
          now,
        );
        // 시작일은 이번에 바꾸는 값만 오늘 이후인지 본다(지난 시작일이 그대로인 판본에서 제작비만 바꾸는 협의를 막지 않는다).
        const startDateChange =
          edit.startDate !== undefined &&
          edit.startDate !== latest.startDate.toISOString().slice(0, 10)
            ? edit.startDate
            : undefined;
        const problem = termsProblem(
          values,
          startDateChange,
          kstDateString(now),
        );
        if (problem) throw new AppError('VALIDATION_FAILED', problem);
        if (diffTerms(latest, values).length === 0) {
          throw new AppError('VALIDATION_FAILED', '바꾼 조건이 없어요.');
        }
        if (
          isCreator &&
          values.perfCap !== null &&
          needsInstagram(
            { format: values.format, perViewCap: values.perfCap },
            connected,
          )
        ) {
          throw new AppError('CONFLICT', INSTAGRAM_REQUIRED_MESSAGE);
        }
        const row = await this.terms.createVersion(
          collaboration.id,
          userId,
          values,
          tx,
        );
        if (fresh.stage !== 'NEGOTIATING') {
          // 단계 표가 원본이다: MATCHED와 AGREED만 협의로 옮길 수 있다.
          if (!canTransition('BRAND_CONTRACT', fresh.stage, 'NEGOTIATING')) {
            throw new AppError('CONFLICT', '지금은 조건을 제안할 수 없어요.');
          }
          await this.advanceOrFail(
            collaboration.id,
            fresh.stage,
            'NEGOTIATING',
            tx,
          );
        }
        const voided = await this.collaborations.voidPendingContract(
          collaboration.id,
          'NEW_TERMS',
          now,
          tx,
        );
        const roomId = await this.conversations.idForCollaboration(
          collaboration.id,
          tx,
        );
        const lineIds: string[] = [];
        if (roomId) {
          if (voided) {
            lineIds.push(
              (
                await this.conversations.postSystem(
                  roomId,
                  'CONSENT_VOIDED',
                  {},
                  tx,
                )
              ).id,
            );
          }
          lineIds.push(
            (
              await this.conversations.postSystem(
                roomId,
                'TERMS_PROPOSED',
                {
                  name: actor.name,
                  version: row.version,
                  proposerId: userId,
                },
                tx,
              )
            ).id,
          );
        }
        return { created: row, previous: latest, roomId, lineIds };
      });

    for (const lineId of lineIds) {
      await this.conversations.publishCreated(lineId);
    }
    if (roomId) await this.conversations.publishUpdated(roomId, 'TERMS');
    await this.notifyProposed(collaboration, userId, created);
    return toTermsVersionModel(created, collaboration.commissionerId, previous);
  }

  // 커밋 뒤에 안내 줄과 방의 변경을 참가자의 화면으로 밀어 준다(전달이 실패해도 던지지 않는다).
  private async publishRoom(
    roomId: string | null,
    lineId: string | null,
    reason: 'TERMS',
  ): Promise<void> {
    if (!roomId) return;
    if (lineId) await this.conversations.publishCreated(lineId);
    await this.conversations.publishUpdated(roomId, reason);
  }

  // 결제 잠금이 시작되는 시각의 경계: 이보다 늦게 요청된 PENDING 결제가 있으면 잠겨 있다.
  private paymentLockSince(now: Date): Date {
    return new Date(now.getTime() - BRAND_PAYMENT_LOCK_MINUTES * MINUTE_MS);
  }

  // 안내 줄과 알림에 쓰는 내 이름 사본. 못 읽으면 기본 이름으로 대신한다(조건 변경이 되돌아가지 않게).
  private async actorOf(
    collaboration: Collaboration,
    userId: string,
  ): Promise<{ userId: string; name: string; photoPath: string | null }> {
    const byCreator = collaboration.creatorId === userId;
    try {
      const actor = byCreator
        ? await this.creators.getActor(userId)
        : await this.brands.getActor(userId);
      if (actor) return actor;
    } catch {
      // 아래 기본 이름으로 대신한다.
    }
    return {
      userId,
      name: byCreator ? '크리에이터' : '브랜드',
      photoPath: null,
    };
  }

  // 잠금 안이라 실패할 길이 없지만, 실패하면 확인만 남고 단계가 안 움직인 채 끝나므로 트랜잭션째 되돌린다.
  private async advanceOrFail(
    collaborationId: string,
    from: CollaborationStage,
    to: CollaborationStage,
    tx: Prisma.TransactionClient,
  ): Promise<void> {
    if (
      !(await this.collaborations.advance(collaborationId, from, to, {}, tx))
    ) {
      throw new AppError('CONFLICT', '지금은 조건을 확인할 수 없어요.');
    }
  }

  // 커밋 뒤에 상대에게 알린다. 실패해도 이미 저장된 확인은 유효하다(원장 판단 R22).
  private notifyConfirmed(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
  ): Promise<void> {
    return this.notifyCounterpart(
      collaboration,
      userId,
      row,
      'TERMS_CONFIRMED',
      'terms-confirmed',
    );
  }

  // 새 판본을 낸 것도 같은 모양으로 알린다(낸 쪽에는 알리지 않는다).
  private notifyProposed(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
  ): Promise<void> {
    return this.notifyCounterpart(
      collaboration,
      userId,
      row,
      'TERMS_PROPOSED',
      'terms-proposed',
    );
  }

  private async notifyCounterpart(
    collaboration: Collaboration,
    userId: string,
    row: TermsVersion,
    kind: 'TERMS_CONFIRMED' | 'TERMS_PROPOSED',
    dedupePrefix: string,
  ): Promise<void> {
    const byCreator = collaboration.creatorId === userId;
    try {
      const actor = await this.actorOf(collaboration, userId);
      await this.notifications.notify({
        userId: byCreator
          ? collaboration.commissionerId
          : collaboration.creatorId,
        role: byCreator ? 'BRAND' : 'CREATOR',
        kind,
        actor,
        params: { version: row.version },
        target: { kind: 'TERMS', id: collaboration.id },
        dedupeKey: `${dedupePrefix}:${collaboration.id}:${row.version}:${userId}`,
      });
    } catch (error) {
      this.logger.warn(
        `조건 알림을 남기지 못했어요(${kind}): ${error instanceof Error ? error.name : 'unknown'}`,
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
