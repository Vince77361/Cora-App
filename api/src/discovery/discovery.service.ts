import { Injectable, Logger } from '@nestjs/common';
import { Campaign, SwipeDecision, UserRole } from '@prisma/client';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { ConversationsService } from '../conversations/conversations.service';
import { AppError } from '../common/errors/app-error';
import { startOfKstDay } from '../common/kst';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { StoresService } from '../stores/stores.service';
import { BrandProposal, draftTerms } from '../terms/draft-terms';
import { proposalProblem } from '../terms/proposal-rules';
import { TermsService } from '../terms/terms.service';
import { UsersService } from '../users/users.service';
import { VisibilityService } from '../visibility/visibility.service';
import {
  DecisionResultModel,
  UndoneDecisionModel,
} from './dto/decision-result.model';
import { PassReasonDto } from './dto/pass-reason.dto';
import { InquiryDto } from './dto/inquiry.dto';
import { InquiryResultModel } from './dto/inquiry-result.model';
import { BrandProposalDto, PutDecisionDto } from './dto/put-decision.dto';
import {
  DecisionKey,
  DiscoveryRepository,
  isUniqueViolation,
} from './discovery.repository';
import {
  DecisionInput,
  INQUIRY_MESSAGE_MAX,
  NOTE_MAX,
  planDecisionWrite,
} from './discovery-rules';

// 한 결정이 낸 결과. 서로 관심이 이번 결정으로 새로 생겼을 때만 알림을 보낸다.
interface Outcome {
  matched: boolean;
  collaborationId: string | null;
  conversationId: string | null;
  createdNow: boolean;
  // 서로 관심 때 남긴 안내 줄(MATCHED). 커밋 뒤에 양쪽 화면으로 밀어 준다.
  systemMessageId?: string;
}

const NOT_MATCHED: Outcome = {
  matched: false,
  collaborationId: null,
  conversationId: null,
  createdNow: false,
};

const pairLockKey = (campaignId: string, creatorId: string): string =>
  `discovery:${campaignId}:${creatorId}`;

// 알림과 안내 줄에 쓰는 상대 이름 사본. 프로필을 못 읽으면 null이고 쓰는 쪽이 기본 이름으로 대신한다.
interface ActorCopy {
  userId: string;
  name: string;
  photoPath: string | null;
}
interface Actors {
  brand: ActorCopy | null;
  creator: ActorCopy | null;
}

const campaignNotFound = (): AppError =>
  new AppError('NOT_FOUND', '캠페인을 찾을 수 없어요.');

// 크리에이터의 "받은 제안"에 보이는 관심: 관심(LIKE)에 글이나 조건 제안이 붙어 있다.
function isProposalLike(row: SwipeDecision | null): boolean {
  return (
    row?.decision === 'LIKE' && (row.note !== null || row.proposedFee !== null)
  );
}

function alreadyMatched(): AppError {
  return new AppError(
    'CONFLICT',
    '이미 서로 관심이 닿아서 결정을 바꿀 수 없어요.',
  );
}

// 관심·넘김·보류와 서로 관심. 넘김과 넘긴 이유는 본인에게만 쓰이고 상대에게 가는 응답과 알림에 들어가지 않는다.
@Injectable()
export class DiscoveryService {
  private readonly logger = new Logger(DiscoveryService.name);

  constructor(
    private readonly users: UsersService,
    private readonly brands: BrandsService,
    private readonly campaigns: CampaignsService,
    private readonly creators: CreatorsService,
    private readonly stores: StoresService,
    private readonly visibility: VisibilityService,
    private readonly notifications: NotificationsService,
    private readonly terms: TermsService,
    private readonly collaborations: CollaborationsRepository,
    private readonly conversations: ConversationsService,
    private readonly repository: DiscoveryRepository,
    private readonly clock: Clock,
  ) {}

  async decide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    const role = await this.users.getRole(userId);
    if (role === 'BRAND') return this.brandDecide(userId, input);
    if (role === 'CREATOR') return this.creatorDecide(userId, input);
    throw new AppError(
      'FORBIDDEN',
      '브랜드나 크리에이터 계정만 관심을 보낼 수 있어요.',
    );
  }

  // 가게 카드는 오른쪽(지원)이 2번의 applyToStore이고, 넘김만 여기서 저장한다.
  async passStore(userId: string, storeId: string): Promise<void> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const [store] = await this.stores.findPublishedCards([storeId], userId);
    if (!store) throw new AppError('NOT_FOUND', '가게를 찾을 수 없어요.');
    const key: DecisionKey = {
      actorId: userId,
      targetKind: 'STORE',
      targetId: store.summary.id,
      campaignId: null,
    };
    const now = this.clock.now();
    await this.repository.transaction(async (tx) => {
      await this.repository.lock(`discovery-store:${userId}:${storeId}`, tx);
      const existing = await this.repository.findDecision(key, tx);
      const write = planDecisionWrite(existing, { decision: 'PASS' });
      if (write.kind === 'create') {
        await this.repository.createDecision(key, write.data, now, tx);
      } else if (write.kind === 'update' && existing) {
        await this.repository.updateDecision(existing.id, write.data, now, tx);
      }
    });
  }

  // 넘긴 이유는 PASS 결정이 있을 때만 남긴다. 이유 없이 넘기는 것은 이 호출을 하지 않는 것이다.
  async setPassReason(userId: string, input: PassReasonDto): Promise<void> {
    const role = await this.users.getRole(userId);
    let campaignId: string | null;
    if (role === 'BRAND' && input.targetKind === 'CREATOR') {
      campaignId = (await this.campaigns.requireMyActive(userId)).id;
    } else if (role === 'CREATOR' && input.targetKind === 'CAMPAIGN') {
      campaignId = input.targetId;
    } else if (role === 'CREATOR' && input.targetKind === 'STORE') {
      campaignId = null;
    } else if (role === 'BRAND' || role === 'CREATOR') {
      throw new AppError('VALIDATION_FAILED', '넘길 수 없는 대상이에요.');
    } else {
      throw new AppError(
        'FORBIDDEN',
        '브랜드나 크리에이터 계정만 쓸 수 있어요.',
      );
    }
    const existing = await this.repository.findDecision({
      actorId: userId,
      targetKind: input.targetKind,
      targetId: input.targetId,
      campaignId,
    });
    if (existing?.decision !== 'PASS') {
      throw new AppError('CONFLICT', '넘긴 카드에만 이유를 남길 수 있어요.');
    }
    const saved = await this.repository.setPassReason(
      existing.id,
      input.reason,
      existing.updatedAt,
    );
    // 읽은 뒤 되돌리기가 먼저 그 행을 지웠다.
    if (!saved) {
      throw new AppError('CONFLICT', '넘긴 카드에만 이유를 남길 수 있어요.');
    }
  }

  // 오늘(한국 날짜) 내가 가장 나중에 한 결정을 행째 지운다(넘긴 이유와 브랜드의 제안도 함께).
  // 오늘 한 결정이 없으면 null이고 아무것도 지우지 않는다. 서로 관심이 된 것은 되돌릴 수 없다.
  async undoLast(userId: string): Promise<UndoneDecisionModel | null> {
    const role = await this.users.getRole(userId);
    if (role !== 'BRAND' && role !== 'CREATOR') {
      throw new AppError(
        'FORBIDDEN',
        '브랜드나 크리에이터 계정만 쓸 수 있어요.',
      );
    }
    const since = startOfKstDay(this.clock.now());
    const first = await this.repository.findLastSince(userId, since);
    if (!first) return null;
    return this.repository.transaction(async (tx) => {
      let target = first;
      let pair = this.pairOf(userId, target);
      if (pair) await this.repository.lock(pairLockKey(...pair), tx);
      // 고른 뒤 잠그는 사이에 같은 사용자의 새 결정이 들어왔을 수 있어 잠근 뒤에 마지막 결정을 다시 고른다.
      const latest = await this.repository.findLastSince(userId, since, tx);
      if (!latest) return null;
      if (latest.id !== target.id) {
        target = latest;
        pair = this.pairOf(userId, target);
        if (pair) await this.repository.lock(pairLockKey(...pair), tx);
        // 새로 잠근 쌍에서도 그 사이에 지워졌을 수 있다.
        if (!(await this.repository.findDecisionById(target.id, tx))) {
          return null;
        }
      }
      if (pair && (await this.repository.findMatch(pair[0], pair[1], tx))) {
        throw alreadyMatched();
      }
      await this.repository.deleteDecision(target.id, tx);
      return { targetKind: target.targetKind, targetId: target.targetId };
    });
  }

  private async brandDecide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    if (input.targetKind !== 'CREATOR') {
      throw new AppError(
        'VALIDATION_FAILED',
        '브랜드는 크리에이터에게만 관심을 보낼 수 있어요.',
      );
    }
    const campaign = await this.campaigns.requireMyActive(userId);
    const brand = await this.brands.requireProfile(userId);
    const note = this.cleanNote(input.note, NOTE_MAX.BRAND);
    const proposal = this.cleanProposal(input, campaign);
    const creatorId = input.targetId;
    // 보이지 않는 크리에이터(피하는 업종, 협업 원칙 없음, 탈퇴)는 없는 것과 같다.
    const visible =
      (await this.creators.getSummary(creatorId)) !== null &&
      (await this.visibility.creatorVisibleTo(creatorId, {
        userId,
        kind: 'BRAND',
        industry: brand.industry,
      }));
    if (!visible) {
      throw new AppError('NOT_FOUND', '크리에이터를 찾을 수 없어요.');
    }
    const card =
      input.decision === 'LIKE' && note
        ? await this.creators.getCardCopy(creatorId)
        : null;
    return this.saveAndMatch({
      side: 'BRAND',
      campaign,
      creatorId,
      key: {
        actorId: userId,
        targetKind: 'CREATOR',
        targetId: creatorId,
        campaignId: campaign.id,
      },
      input: { decision: input.decision, note, proposal, card },
    });
  }

  private async creatorDecide(
    userId: string,
    input: PutDecisionDto,
  ): Promise<DecisionResultModel> {
    if (input.targetKind !== 'CAMPAIGN') {
      throw new AppError(
        'VALIDATION_FAILED',
        '크리에이터는 캠페인에만 관심을 보낼 수 있어요.',
      );
    }
    if (input.proposal) {
      throw new AppError(
        'VALIDATION_FAILED',
        '조건 제안은 브랜드만 붙일 수 있어요.',
      );
    }
    const note = this.cleanNote(input.note, NOTE_MAX.CREATOR);
    const campaign = await this.requireVisibleCampaign(userId, input.targetId);
    await this.creators.requireProfile(userId);
    return this.saveAndMatch({
      side: 'CREATOR',
      campaign,
      creatorId: userId,
      key: {
        actorId: userId,
        targetKind: 'CAMPAIGN',
        targetId: campaign.id,
        campaignId: campaign.id,
      },
      input: { decision: input.decision, note },
    });
  }

  // 크리에이터가 보이는(피하는 업종이 아닌) 진행 중인 캠페인. 없거나 보이지 않으면 404다.
  private async requireVisibleCampaign(
    userId: string,
    campaignId: string,
  ): Promise<Campaign> {
    const campaign = await this.campaigns.findActiveById(campaignId);
    const brand = campaign
      ? (await this.brands.findProfiles([campaign.brandId])).get(
          campaign.brandId,
        )
      : undefined;
    if (
      !campaign ||
      !brand ||
      !(await this.visibility.commissionerVisibleTo(
        { ownerId: campaign.brandId, industry: brand.industry },
        userId,
      ))
    ) {
      throw new AppError('NOT_FOUND', '캠페인을 찾을 수 없어요.');
    }
    return campaign;
  }

  // "조건부터 질문하기": 서로 관심을 만들지 않고 브랜드에게 메시지 요청을 보낸다.
  // 한 트랜잭션에서 협업(INQUIRY), 메시지 요청 방(REQUESTED, 요청자 = 나), 첫 메시지(번호 1)를 만든다.
  // 서로 관심 판정과 같은 (캠페인, 크리에이터) 잠금을 잡아서, 문의와 서로 관심이 동시에 와도 협업이 둘 생기지 않는다.
  // 브랜드가 나에게 글이나 제안을 붙인 관심을 보낸 캠페인(받은 제안에 보이는 것)만 물을 수 있다: 아니면 404.
  async inquire(
    userId: string,
    campaignId: string,
    input: InquiryDto,
  ): Promise<InquiryResultModel> {
    if ((await this.users.getRole(userId)) !== 'CREATOR') {
      throw new AppError('FORBIDDEN', '크리에이터 계정만 쓸 수 있어요.');
    }
    const message = input.message.trim();
    if (message === '') {
      throw new AppError('VALIDATION_FAILED', '메시지를 입력해 주세요.');
    }
    // 글자 수는 코드 포인트로 센다(대화 메시지와 같은 기준).
    if (Array.from(message).length > INQUIRY_MESSAGE_MAX) {
      throw new AppError('VALIDATION_FAILED', '1,000자까지 보낼 수 있어요.');
    }
    const contentLine =
      this.cleanNote(input.contentLine, NOTE_MAX.CREATOR) ?? null;
    const campaign = await this.requireVisibleCampaign(userId, campaignId);
    await this.creators.requireProfile(userId);
    const actors = await this.readActors(campaign.brandId, userId);
    const now = this.clock.now();

    let created: InquiryResultModel;
    let firstMessageId = '';
    try {
      created = await this.repository.transaction(async (tx) => {
        await this.repository.lock(pairLockKey(campaign.id, userId), tx);
        const like = await this.repository.findDecision(
          {
            actorId: campaign.brandId,
            targetKind: 'CREATOR',
            targetId: userId,
            campaignId: campaign.id,
          },
          tx,
        );
        if (!isProposalLike(like)) throw campaignNotFound();
        if (
          await this.collaborations.findBrandContract(campaign.id, userId, tx)
        ) {
          throw new AppError(
            'CONFLICT',
            '이 캠페인으로 이미 진행한 협업이 있어요.',
          );
        }
        const mine = await this.repository.findDecision(
          {
            actorId: userId,
            targetKind: 'CAMPAIGN',
            targetId: campaign.id,
            campaignId: campaign.id,
          },
          tx,
        );
        // 넘긴 캠페인은 받은 제안에서도 사라진다(보류는 결정이 아니라서 남는다).
        if (mine && mine.decision !== 'HOLD') throw campaignNotFound();

        const collaboration = await this.collaborations.create(
          {
            kind: 'BRAND_CONTRACT',
            stage: 'INQUIRY',
            commissionerId: campaign.brandId,
            creatorId: userId,
            offerId: null,
            storeId: null,
            campaignId: campaign.id,
            creatorNote: contentLine,
            terms: {},
            settlementMethod: 'FIXED',
            fundedAt: null,
            submitDueAt: null,
            createdAt: now,
          },
          tx,
        );
        const room = await this.conversations.openForCollaboration(
          collaboration.id,
          { status: 'REQUESTED', requestedById: userId },
          tx,
        );
        // 두 사람 사이에 차단이 있으면 방이 닫힌 채로 만들어진다. 차단 사실을 알리지 않고 없는 것으로 답하며 되돌린다.
        if (room.status !== 'REQUESTED') throw campaignNotFound();
        firstMessageId = await this.conversations.postRequestMessage(
          room.id,
          userId,
          message,
          tx,
        );
        return { collaborationId: collaboration.id, conversationId: room.id };
      });
    } catch (error) {
      // 유일 제약이 마지막 안전망이다: 같은 쌍의 협업이 동시에 만들어졌다.
      if (isUniqueViolation(error)) {
        throw new AppError(
          'CONFLICT',
          '이 캠페인으로 이미 진행한 협업이 있어요.',
        );
      }
      throw error;
    }
    // 커밋 뒤에 양쪽 화면으로 첫 메시지와 새 방을 밀어 준다. 요청 방의 첫 메시지에는 일반 대화 메시지 푸시가 가지 않는다(아래 MESSAGE_REQUEST가 그 알림이다).
    await this.conversations.publishCreated(firstMessageId);
    await this.conversations.publishUpdated(created.conversationId, 'STATUS');
    // 커밋 뒤에 브랜드에게 알린다. 알림이 실패해도 이미 보낸 요청은 유효하다(원장 판단 R22).
    try {
      await this.notifications.notify({
        userId: campaign.brandId,
        role: 'BRAND',
        kind: 'MESSAGE_REQUEST',
        actor: actors.creator ?? {
          userId,
          name: '크리에이터',
          photoPath: null,
        },
        target: { kind: 'CONVERSATION', id: created.conversationId },
        dedupeKey: `message-request:${created.collaborationId}`,
      });
    } catch (error) {
      this.logger.warn(
        `메시지 요청 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
    return created;
  }

  // 결정을 저장하고, 반대쪽에도 관심이 있으면 같은 트랜잭션에서 서로 관심을 만든다.
  // 같은 쌍의 결정은 잠금으로 한 줄로 서므로 동시에 서로 관심을 보내도 매칭, 협업, 버전 1은 한 번만 만들어진다
  // (유일 제약이 마지막 안전망이다).
  private async saveAndMatch(args: {
    side: 'BRAND' | 'CREATOR';
    campaign: Campaign;
    creatorId: string;
    key: DecisionKey;
    input: DecisionInput;
  }): Promise<DecisionResultModel> {
    const { side, campaign, creatorId, key, input } = args;
    const now = this.clock.now();
    // 안내 줄과 알림에 쓸 이름은 트랜잭션 밖에서 미리 읽는다: 트랜잭션이 연결을 쥔 채 다른 연결을 기다리지 않고,
    // 이름을 못 읽어도 서로 관심이 되돌아가지 않게 기본 이름으로 대신한다.
    const actors = await this.readActors(campaign.brandId, creatorId);
    let outcome: Outcome;
    try {
      outcome = await this.repository.transaction(async (tx) => {
        await this.repository.lock(pairLockKey(campaign.id, creatorId), tx);
        if (await this.repository.findMatch(campaign.id, creatorId, tx)) {
          throw alreadyMatched();
        }
        const existing = await this.repository.findDecision(key, tx);
        const write = planDecisionWrite(existing, input);
        let mine: SwipeDecision | null = existing;
        if (write.kind === 'create') {
          mine = await this.repository.createDecision(key, write.data, now, tx);
        } else if (write.kind === 'update' && existing) {
          mine = await this.repository.updateDecision(
            existing.id,
            write.data,
            now,
            tx,
          );
        }
        if (!mine || mine.decision !== 'LIKE') return NOT_MATCHED;

        const theirs = await this.repository.findDecision(
          side === 'BRAND'
            ? {
                actorId: creatorId,
                targetKind: 'CAMPAIGN',
                targetId: campaign.id,
                campaignId: campaign.id,
              }
            : {
                actorId: campaign.brandId,
                targetKind: 'CREATOR',
                targetId: creatorId,
                campaignId: campaign.id,
              },
          tx,
        );
        if (theirs?.decision !== 'LIKE') return NOT_MATCHED;
        const brandRow = side === 'BRAND' ? mine : theirs;
        const creatorRow = side === 'CREATOR' ? mine : theirs;
        return this.createMatch(
          campaign,
          creatorId,
          brandRow,
          creatorRow,
          actors,
          now,
          tx,
        );
      });
    } catch (error) {
      // 유일 제약이 마지막 안전망이다: 같은 쌍의 서로 관심이 이미 만들어졌으면 그 결과를 돌려준다.
      if (!isUniqueViolation(error)) throw error;
      const match = await this.repository.findMatch(campaign.id, creatorId);
      if (!match) throw error;
      outcome = {
        matched: true,
        collaborationId: match.collaborationId,
        conversationId: await this.conversations.idForCollaboration(
          match.collaborationId,
        ),
        createdNow: false,
      };
    }
    // 커밋 뒤에 안내 줄과 방의 변경을 양쪽 화면으로 밀어 준다(문의로 먼저 열린 방이 열린 방이 된 경우도 포함).
    if (outcome.systemMessageId) {
      await this.conversations.publishCreated(outcome.systemMessageId);
    }
    if (outcome.createdNow && outcome.conversationId) {
      await this.conversations.publishUpdated(outcome.conversationId, 'STATUS');
    }
    if (outcome.createdNow && outcome.collaborationId) {
      await this.notifyMutual(
        campaign,
        creatorId,
        outcome.collaborationId,
        actors,
      );
    }
    return {
      decision: input.decision,
      matched: outcome.matched,
      collaborationId: outcome.collaborationId,
      conversationId: outcome.conversationId,
    };
  }

  // 서로 관심: matches 행, 협업(MATCHED, 정산 방식 FIXED, 맡기는 쪽은 브랜드), 조건 버전 1.
  // 크리에이터가 "조건부터 질문하기"로 먼저 만든 협업(INQUIRY)이 있으면 새로 만들지 않고 그것을 MATCHED로 올린다.
  private async createMatch(
    campaign: Campaign,
    creatorId: string,
    brandRow: SwipeDecision,
    creatorRow: SwipeDecision,
    actors: Actors,
    now: Date,
    tx: Parameters<DiscoveryRepository['createMatch']>[1],
  ): Promise<Outcome> {
    let collaboration = await this.collaborations.findBrandContract(
      campaign.id,
      creatorId,
      tx,
    );
    if (!collaboration) {
      collaboration = await this.collaborations.create(
        {
          kind: 'BRAND_CONTRACT',
          stage: 'MATCHED',
          commissionerId: campaign.brandId,
          creatorId,
          offerId: null,
          storeId: null,
          campaignId: campaign.id,
          // 브랜드 협업의 조건은 terms_versions가 담는다. 가게 오퍼의 조건 사본 열은 비워 둔다.
          terms: {},
          settlementMethod: 'FIXED',
          fundedAt: null,
          submitDueAt: null,
          createdAt: now,
        },
        tx,
      );
    } else if (collaboration.stage === 'INQUIRY') {
      const moved = await this.collaborations.advance(
        collaboration.id,
        'INQUIRY',
        'MATCHED',
        {},
        tx,
      );
      if (!moved) throw alreadyMatched();
    } else {
      throw new AppError(
        'CONFLICT',
        '이 캠페인으로 이미 진행한 협업이 있어요.',
      );
    }
    await this.repository.createMatch(
      {
        campaignId: campaign.id,
        creatorId,
        collaborationId: collaboration.id,
        matchedAt: now,
      },
      tx,
    );
    if (!(await this.terms.latest(collaboration.id, tx))) {
      const card = await this.creators.getCardCopy(creatorId);
      // 제목: 관심에 쓴 글, 없으면 문의("조건부터 질문하기")에 적은 한 줄, 없으면 캠페인 한 줄.
      const values = draftTerms(
        campaign,
        { cardHeadline: card?.headline ?? null },
        creatorRow.note ?? collaboration.creatorNote,
        proposalOf(brandRow),
      );
      await this.terms.createVersion(collaboration.id, null, values, tx);
    }
    // 협업과 같은 트랜잭션에서 방을 연다(방 없는 협업이 생기지 않게). 문의로 먼저 생긴 협업은 방이 이미 있다.
    const room = await this.conversations.openForCollaboration(
      collaboration.id,
      { status: 'OPEN' },
      tx,
    );
    const line = await this.conversations.postSystem(
      room.id,
      'MATCHED',
      {
        commissionerName: actors.brand?.name ?? '브랜드',
        creatorName: actors.creator?.name ?? '크리에이터',
      },
      tx,
    );
    return {
      matched: true,
      collaborationId: collaboration.id,
      conversationId: room.id,
      createdNow: true,
      systemMessageId: line.id,
    };
  }

  private async readActors(
    brandId: string,
    creatorId: string,
  ): Promise<Actors> {
    const [brand, creator] = await Promise.all([
      this.brands.getActor(brandId).catch(() => null),
      this.creators.getActor(creatorId).catch(() => null),
    ]);
    return { brand, creator };
  }

  // 커밋 뒤에 양쪽에 알린다. 알림이 실패해도 이미 저장된 서로 관심은 유효하다(원장 판단 R22).
  private async notifyMutual(
    campaign: Campaign,
    creatorId: string,
    collaborationId: string,
    actors: Actors,
  ): Promise<void> {
    const target = { kind: 'MATCH' as const, id: collaborationId };
    const dedupeKey = `mutual-interest:${collaborationId}`;
    const send = async (
      userId: string,
      role: UserRole,
      actor: { userId: string; name: string; photoPath: string | null },
    ): Promise<void> => {
      try {
        await this.notifications.notify({
          userId,
          role,
          kind: 'MUTUAL_INTEREST',
          actor,
          target,
          dedupeKey,
        });
      } catch (error) {
        this.logger.warn(
          `서로 관심 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    };
    await send(
      creatorId,
      'CREATOR',
      actors.brand ?? {
        userId: campaign.brandId,
        name: '브랜드',
        photoPath: null,
      },
    );
    await send(
      campaign.brandId,
      'BRAND',
      actors.creator ?? {
        userId: creatorId,
        name: '크리에이터',
        photoPath: null,
      },
    );
  }

  // 되돌릴 결정이 가리키는 (캠페인, 크리에이터) 쌍. 가게 넘김은 쌍이 없다.
  private pairOf(
    userId: string,
    row: SwipeDecision,
  ): [campaignId: string, creatorId: string] | null {
    if (!row.campaignId) return null;
    if (row.targetKind === 'CREATOR') return [row.campaignId, row.targetId];
    if (row.targetKind === 'CAMPAIGN') return [row.campaignId, userId];
    return null;
  }

  // 글은 앞뒤 공백을 걷어 내고 빈 글은 null로 본다. 보내지 않았으면 undefined(저장된 글을 그대로 둔다).
  // 생성된 클라이언트는 비운 선택 칸을 명시적 null로 보내므로 null도 보내지 않은 것이다.
  private cleanNote(
    value: string | null | undefined,
    max: number,
  ): string | null | undefined {
    if (value === undefined || value === null) return undefined;
    const text = value.trim();
    if (text.length > max) {
      throw new AppError(
        'VALIDATION_FAILED',
        `글은 ${max}자까지 쓸 수 있어요.`,
      );
    }
    return text === '' ? null : text;
  }

  // 제안은 관심에만 붙고, 범위와 단위는 정책 한 곳(proposalProblem)에서 본다.
  private cleanProposal(
    input: PutDecisionDto,
    campaign: Campaign,
  ): BrandProposal | undefined {
    if (!input.proposal) return undefined;
    if (input.decision !== 'LIKE') {
      throw new AppError(
        'VALIDATION_FAILED',
        '조건 제안은 관심을 보낼 때만 붙일 수 있어요.',
      );
    }
    const proposal = toProposal(input.proposal);
    const problem = proposalProblem(proposal, campaign.format);
    if (problem) throw new AppError('VALIDATION_FAILED', problem);
    return proposal;
  }
}

function toProposal(dto: BrandProposalDto): BrandProposal {
  return {
    fee: dto.fee,
    productProvided: dto.productProvided,
    performance: dto.performance
      ? { ratePer1000: dto.performance.ratePer1000, cap: dto.performance.cap }
      : null,
  };
}

// 저장된 결정 행의 제안 칸을 값으로 읽는다. 제작비가 없으면 제안이 없는 것이다.
function proposalOf(row: SwipeDecision): BrandProposal | null {
  if (row.proposedFee === null || row.proposedProductProvided === null) {
    return null;
  }
  return {
    fee: row.proposedFee,
    productProvided: row.proposedProductProvided,
    performance:
      row.proposedPerfRate !== null && row.proposedPerfCap !== null
        ? { ratePer1000: row.proposedPerfRate, cap: row.proposedPerfCap }
        : null,
  };
}
