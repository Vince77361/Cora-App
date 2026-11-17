import { Injectable, Logger } from '@nestjs/common';
import {
  Campaign,
  Conversation,
  ConversationStatus,
  Message,
  Prisma,
  UserRole,
} from '@prisma/client';
import {
  negotiableStages,
  preContractStages,
} from '../collaborations/collaboration-stage';
import { CollaborationsRepository } from '../collaborations/collaborations.repository';
import { Clock } from '../common/clock';
import { AppError } from '../common/errors/app-error';
import { BrandsService } from '../brands/brands.service';
import { CampaignsService } from '../campaigns/campaigns.service';
import { CreatorsService } from '../creators/creators.service';
import { NotificationsService } from '../notifications/notifications.service';
import { StoragePort } from '../integrations/storage/storage.port';
import {
  ConversationUpdatedPayload,
  ConversationUpdateReason,
  RealtimePublisher,
} from '../realtime/realtime-publisher';
import { readTerms } from '../stores/reward-terms';
import { StoresService } from '../stores/stores.service';
import { toTermsVersionModel } from '../terms/terms-rules';
import { TermsService } from '../terms/terms.service';
import {
  ConversationCounterpartModel,
  ConversationDetailModel,
  ConversationSummaryModel,
} from './dto/conversation.model';
import {
  ListMessagesQuery,
  MESSAGES_PAGE_MAX,
} from './dto/list-messages.query';
import { MessageModel } from './dto/message.model';
import { SendMessageDto } from './dto/send-message.dto';
import {
  ConversationsRepository,
  isUniqueViolation,
  RoomWithCollaboration,
} from './conversations.repository';
import { MessageCreated, MessageEvents } from './message-events';
import { previewOf } from './message-preview';
import {
  renderSystemLine,
  SystemCode,
  SystemParams,
  SystemViewer,
} from './system-lines';

type Role = 'COMMISSIONER' | 'CREATOR';

const CARD_PREVIEW = '콘텐츠 카드를 보냈어요.';
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// 읽는 동안 같은 상대·캠페인·가게를 다시 읽지 않게 모아 둔다(목록 한 번에 한 벌).
interface Lookups {
  creators: Map<string, { name: string; photoUrl: string | null } | null>;
  brands: Map<string, { name: string; photoUrl: string | null }>;
  stores: Map<string, { name: string; photoUrl: string | null } | null>;
  campaigns: Map<string, Campaign | null>;
}

interface Header {
  counterpart: ConversationCounterpartModel;
  contextLabel: string;
  role: Role;
}

// 한 사람에게 보여 줄 새 메시지. 실시간 전달(message.created)과 푸시에 쓴다.
export interface MessageDelivery {
  userId: string;
  // 알림을 받는 역할(역할이 여럿인 계정에서 앱이 역할을 바꾼 뒤 이동하게 한다).
  role: UserRole;
  isSender: boolean;
  // 이 사람이 방의 알림을 껐는지.
  muted: boolean;
  // 이 사람의 눈으로 만든 메시지(mine, 안내 줄의 문구가 사람마다 다르다).
  message: MessageModel;
  // 푸시 본문. 글은 60자 + …, 콘텐츠 카드는 고정 문구다.
  preview: string;
  // 보낸 사람 이름(푸시 제목). 프로필을 읽어야 해서 푸시를 보낼 때만 부른다.
  senderName(): Promise<string>;
}

export interface MessageDeliveries {
  conversationId: string;
  status: ConversationStatus;
  deliveries: MessageDelivery[];
}

const notFound = (): AppError =>
  new AppError('NOT_FOUND', '대화를 찾을 수 없어요.');

const requestAnswered = (): AppError =>
  new AppError('CONFLICT', '이미 답한 메시지 요청이에요.');

// 대화방과 메시지. 방은 협업 하나에 하나이고 참가자(맡기는 쪽, 크리에이터) 둘만 읽고 쓴다.
// 참가자가 아니면 방이 없는 것과 같다(404).
@Injectable()
export class ConversationsService {
  private readonly logger = new Logger(ConversationsService.name);

  constructor(
    private readonly repository: ConversationsRepository,
    private readonly collaborations: CollaborationsRepository,
    private readonly creators: CreatorsService,
    private readonly brands: BrandsService,
    private readonly stores: StoresService,
    private readonly campaigns: CampaignsService,
    private readonly terms: TermsService,
    private readonly storage: StoragePort,
    private readonly events: MessageEvents,
    private readonly notifications: NotificationsService,
    private readonly clock: Clock,
    private readonly realtime: RealtimePublisher,
  ) {}

  // 협업과 같은 트랜잭션에서 방과 참가자 둘을 만든다. 이미 방이 있으면 그것을 돌려준다.
  // 이미 있는 방이 메시지 요청(REQUESTED)인데 열린 방(OPEN)을 원하면 방을 연다: "조건부터 질문하기"로 먼저 생긴 협업이
  // 서로 관심으로 올라갈 때다(요청을 수락하지 않아도 서로 관심이면 바로 열린다).
  // 두 사람 사이에 차단이 있으면 방은 처음부터 닫힌 방(CLOSED, BLOCKED)이다 — 차단 뒤 수락으로 대화가 열리는 길을 막는다.
  async openForCollaboration(
    collaborationId: string,
    opts: { status: 'OPEN' | 'REQUESTED'; requestedById?: string },
    tx: Prisma.TransactionClient,
  ): Promise<Conversation> {
    const existing = await this.repository.findByCollaborationId(
      collaborationId,
      tx,
    );
    if (existing) {
      if (existing.status === 'REQUESTED' && opts.status === 'OPEN') {
        const now = this.clock.now();
        const opened = await this.repository.transitionRoom(
          existing.id,
          'REQUESTED',
          'OPEN',
          now,
          tx,
        );
        if (opened) return { ...existing, status: 'OPEN', updatedAt: now };
      }
      return existing;
    }
    const collaboration = await this.collaborations.findById(
      collaborationId,
      tx,
    );
    if (!collaboration) {
      throw new AppError('NOT_FOUND', '협업을 찾을 수 없어요.');
    }
    const blocked = await this.repository.hasBlockBetween(
      collaboration.commissionerId,
      collaboration.creatorId,
      tx,
    );
    return this.repository.createRoom(
      {
        collaborationId,
        status: blocked ? 'CLOSED' : opts.status,
        requestedById: opts.requestedById ?? null,
        closedReason: blocked ? 'BLOCKED' : null,
        memberIds: [collaboration.commissionerId, collaboration.creatorId],
        now: this.clock.now(),
      },
      tx,
    );
  }

  // 차단: 두 사람 사이의 열려 있거나 요청 중인 방을 모두 닫는다. 협업과 같은 트랜잭션에서 부르고,
  // 커밋 뒤에 닫은 방마다 publishUpdated를 부른다(안내 줄은 남기지 않는다: 차단 사실은 상대에게 알리지 않는다).
  closeBetween(
    a: string,
    b: string,
    tx: Prisma.TransactionClient,
  ): Promise<string[]> {
    return this.repository.closeBetween(a, b, this.clock.now(), tx);
  }

  // 차단·신고가 방의 상대와 협업을 알아야 할 때 쓴다. 참가자가 아니면 404다.
  async participantView(
    userId: string,
    id: string,
  ): Promise<{ id: string; collaborationId: string; counterpartId: string }> {
    const room = await this.requireMember(userId, id);
    const other = room.members.find((m) => m.userId !== userId);
    if (!other) throw notFound();
    return {
      id: room.id,
      collaborationId: room.collaborationId,
      counterpartId: other.userId,
    };
  }

  // 신고 대상이 "내 방의 상대"인가.
  isRoomPartner(userId: string, otherId: string): Promise<boolean> {
    if (userId === otherId) return Promise.resolve(false);
    return this.repository.sharesRoom(userId, otherId);
  }

  async idForCollaboration(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<string | null> {
    return (
      (await this.repository.findByCollaborationId(collaborationId, tx))?.id ??
      null
    );
  }

  // 안내 줄을 남긴다. tx를 주면 커밋 전이라 이벤트를 내지 않는다: 부르는 쪽이 커밋 뒤 publishCreated를 부른다.
  // 돌려주는 모델은 보는 사람이 정해지지 않아 맡기는 쪽의 눈으로 만든 문구다(읽을 때는 사람마다 다시 만든다).
  async postSystem(
    conversationId: string,
    code: SystemCode,
    params: SystemParams,
    tx?: Prisma.TransactionClient,
  ): Promise<MessageModel> {
    const row = await this.repository.appendMessage(
      {
        conversationId,
        senderId: null,
        clientId: null,
        kind: 'SYSTEM',
        text: null,
        cardTitle: null,
        cardPhotoPath: null,
        systemCode: code,
        systemParams: params,
        requireOpen: false,
        now: this.clock.now(),
      },
      tx,
    );
    if (!row) throw notFound();
    if (!tx) await this.publishCreated(row.id);
    return this.toMessage(row, { userId: '', role: 'COMMISSIONER' });
  }

  // "조건부터 질문하기"의 첫 메시지. 방이 아직 메시지 요청(REQUESTED)이라 열린 방 조건 없이 번호 1로 남긴다.
  // 요청을 보낸 사람은 수락될 때까지 더 보낼 수 없으므로(sendMessage는 열린 방만) 요청에는 이 한 개만 담긴다.
  // tx 안에서 부르며 커밋 전이라 이벤트를 내지 않는다. 돌려주는 메시지 ID로 부르는 쪽이 커밋 뒤 publishCreated를 부른다.
  // 알림은 부르는 쪽이 MESSAGE_REQUEST로 보낸다(요청 방의 메시지에는 일반 대화 메시지 푸시를 보내지 않는다).
  async postRequestMessage(
    conversationId: string,
    senderId: string,
    text: string,
    tx: Prisma.TransactionClient,
  ): Promise<string> {
    const row = await this.repository.appendMessage(
      {
        conversationId,
        senderId,
        clientId: null,
        kind: 'TEXT',
        text,
        cardTitle: null,
        cardPhotoPath: null,
        systemCode: null,
        systemParams: null,
        requireOpen: false,
        now: this.clock.now(),
      },
      tx,
    );
    if (!row) throw notFound();
    return row.id;
  }

  // 받은 사람이 메시지 요청을 수락한다: REQUESTED → OPEN 조건부, 안내 줄 REQUEST_ACCEPTED. 협업은 INQUIRY에 남는다.
  // 요청을 보낸 사람에게는 커밋 뒤에 알린다(알림이 실패해도 수락은 유효하다).
  async acceptRequest(
    userId: string,
    id: string,
  ): Promise<ConversationDetailModel> {
    const room = await this.requireReceiver(userId, id);
    const actor = await this.actorOf(room, userId);
    const now = this.clock.now();
    let lineId = '';
    await this.repository.transaction(async (tx) => {
      const opened = await this.repository.transitionRoom(
        room.id,
        'REQUESTED',
        'OPEN',
        now,
        tx,
      );
      if (!opened) throw requestAnswered();
      const line = await this.postSystem(
        room.id,
        'REQUEST_ACCEPTED',
        // byId: 수락한 본인에게는 이름 대신 본인 문구로 보이게 하려고 남긴다.
        { name: actor?.name ?? '상대', byId: userId },
        tx,
      );
      lineId = line.id;
    });
    // 커밋 뒤에 양쪽 화면으로 안내 줄과 방의 변경을 밀어 준다.
    await this.publishCreated(lineId);
    await this.publishUpdated(room.id, 'STATUS');
    if (room.requestedById) {
      try {
        await this.notifications.notify({
          userId: room.requestedById,
          role: this.roleOf(room, room.requestedById),
          kind: 'MESSAGE_REQUEST_ACCEPTED',
          actor: actor ?? { userId, name: '상대', photoPath: null },
          target: { kind: 'CONVERSATION', id: room.id },
          dedupeKey: `message-request-accepted:${room.id}`,
        });
      } catch (error) {
        this.logger.warn(
          `메시지 요청 수락 알림을 남기지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
        );
      }
    }
    return this.get(userId, id);
  }

  // 받은 사람이 메시지 요청을 거절한다: REQUESTED → DECLINED, 협업 INQUIRY → DROPPED(REQUEST_DECLINED).
  // 상대에게 알리지 않는다(알림도 안내 줄도 없다). 협업이 끝나 같은 캠페인으로 다시 요청할 수 없다.
  // 잠금 순서는 협업 → 대화방이다: 서로 관심(협업 INQUIRY → MATCHED 뒤 방 열기)과 같은 순서라 엇갈려 막히지 않는다.
  // 둘 중 하나라도 이미 바뀌었으면(동시에 수락했거나 서로 관심이 닿았다) 던져 협업 변경도 되돌린다.
  async declineRequest(userId: string, id: string): Promise<void> {
    const room = await this.requireReceiver(userId, id);
    const now = this.clock.now();
    await this.repository.transaction(async (tx) => {
      const dropped = await this.collaborations.advance(
        room.collaborationId,
        'INQUIRY',
        'DROPPED',
        { dropReason: 'REQUEST_DECLINED', droppedById: userId },
        tx,
      );
      if (!dropped) throw requestAnswered();
      const declined = await this.repository.transitionRoom(
        room.id,
        'REQUESTED',
        'DECLINED',
        now,
        tx,
      );
      if (!declined) throw requestAnswered();
    });
    // 요청한 사람에게는 알리지 않는다(실시간도 없다). 거절한 사람의 다른 기기만 목록을 새로 읽는다.
    await this.publishUpdated(room.id, 'STATUS', [userId]);
  }

  // 내 방이고, 내가 보낸 요청이 아니고, 아직 답하지 않은 메시지 요청일 때만 돌려준다.
  private async requireReceiver(
    userId: string,
    id: string,
  ): Promise<RoomWithCollaboration> {
    const room = await this.requireMember(userId, id);
    if (room.requestedById === userId) {
      throw new AppError('FORBIDDEN', '내가 보낸 요청은 내가 답할 수 없어요.');
    }
    if (room.status !== 'REQUESTED') throw requestAnswered();
    return room;
  }

  private roleOf(room: RoomWithCollaboration, userId: string): UserRole {
    const { collaboration } = room;
    if (collaboration.creatorId === userId) return 'CREATOR';
    return collaboration.kind === 'BRAND_CONTRACT' ? 'BRAND' : 'STORE';
  }

  // 안내 줄과 알림에 쓸 내 이름 사본. 못 읽으면 null이라 쓰는 쪽이 기본 이름으로 대신한다(수락이 되돌아가지 않게).
  private async actorOf(
    room: RoomWithCollaboration,
    userId: string,
  ): Promise<{
    userId: string;
    name: string;
    photoPath: string | null;
  } | null> {
    try {
      const role = this.roleOf(room, userId);
      if (role === 'CREATOR') return await this.creators.getActor(userId);
      if (role === 'BRAND') return await this.brands.getActor(userId);
      return null;
    } catch {
      return null;
    }
  }

  // 저장된 메시지를 구독자(푸시, 실시간)에게 알린다. 이미 커밋된 메시지에만 부른다.
  // 전달은 부가 일이라 실패해도 던지지 않는다(저장된 메시지와 API 응답은 그대로 유효하다).
  async publishCreated(messageId: string): Promise<void> {
    try {
      const message = await this.repository.findMessage(messageId);
      if (!message) return;
      const room = await this.repository.findWithMembers(
        message.conversationId,
      );
      if (!room) return;
      await this.events.publish({
        conversationId: room.id,
        collaborationId: room.collaborationId,
        message,
        memberIds: room.members.map((m) => m.userId),
      });
    } catch (error) {
      this.logger.warn(
        `메시지를 밀어 주지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 방이 바뀌었다고(conversation.updated) 참가자의 화면에 알린다. userIds를 주면 그 사람들에게만 보낸다(읽음, 알림 끄기처럼
  // 나만 알면 되는 변경). 이미 커밋된 변경에만 부르고, 전달이 실패해도 던지지 않는다.
  async publishUpdated(
    conversationId: string,
    reason: ConversationUpdateReason,
    userIds?: string[],
  ): Promise<void> {
    try {
      const targets =
        userIds ??
        (await this.repository.findWithMembers(conversationId))?.members.map(
          (m) => m.userId,
        ) ??
        [];
      if (targets.length === 0) return;
      const payload: ConversationUpdatedPayload = { conversationId, reason };
      await this.realtime.toUsers(targets, 'conversation.updated', payload);
    } catch (error) {
      this.logger.warn(
        `방의 변경을 밀어 주지 못했어요: ${error instanceof Error ? error.name : 'unknown'}`,
      );
    }
  }

  // 새 메시지를 참가자 한 사람씩의 눈으로 만든다(mine과 안내 줄 문구가 사람마다 다르다). 실시간 전달과 푸시가 쓴다.
  async deliveriesOf(event: MessageCreated): Promise<MessageDeliveries | null> {
    const room = await this.repository.findWithMembers(event.conversationId);
    if (!room) return null;
    // 이름은 푸시를 보낼 때만 필요해서, 처음 부를 때 한 번만 읽는다.
    let lookups: Promise<Lookups> | null = null;
    const loadLookups = (): Promise<Lookups> => {
      lookups ??= (async () => {
        const loaded = this.newLookups();
        await this.preload([room], loaded);
        return loaded;
      })();
      return lookups;
    };
    return {
      conversationId: room.id,
      status: room.status,
      deliveries: room.members.map((member) => {
        const viewer = this.viewerOf(room, member.userId);
        return {
          userId: member.userId,
          role: this.roleOf(room, member.userId),
          isSender: event.message.senderId === member.userId,
          muted: member.mutedAt !== null,
          message: this.toMessage(event.message, viewer),
          preview: this.previewOfMessage(event.message, viewer),
          senderName: async () =>
            this.headerOf(room, member.userId, await loadLookups()).counterpart
              .name,
        };
      }),
    };
  }

  async list(userId: string): Promise<ConversationSummaryModel[]> {
    const rooms = await this.repository.listForMember(userId);
    if (rooms.length === 0) return [];
    const lookups = this.newLookups();
    await this.preload(rooms, lookups);
    const [lastMessages, unread] = await Promise.all([
      this.repository.lastMessages(rooms),
      this.repository.unreadCounts(
        userId,
        rooms.map((room) => ({
          id: room.id,
          lastSeq: room.lastSeq,
          lastReadSeq: this.memberOf(room, userId).lastReadSeq,
        })),
      ),
    ]);
    const lastById = new Map(lastMessages.map((m) => [m.conversationId, m]));
    const items = rooms.map((room) => {
      const header = this.headerOf(room, userId, lookups);
      const member = this.memberOf(room, userId);
      const last = lastById.get(room.id) ?? null;
      const summary: ConversationSummaryModel = {
        id: room.id,
        kind: room.collaboration.kind,
        status: room.status,
        section: this.sectionOf(room, userId),
        counterpart: header.counterpart,
        contextLabel: header.contextLabel,
        lastMessage: last
          ? {
              kind: last.kind,
              preview: this.previewOfMessage(last, {
                userId,
                role: header.role,
              }),
              at: last.createdAt.toISOString(),
            }
          : null,
        unreadCount: unread.get(room.id) ?? 0,
        muted: member.mutedAt !== null,
      };
      return { summary, room };
    });
    // 메시지 요청이 맨 위에 모이고, 그 안과 밖은 마지막 메시지가 최근인 방이 먼저다(메시지가 없으면 방을 만든 시각).
    const sortKey = (room: Conversation) =>
      (room.lastMessageAt ?? room.createdAt).getTime();
    return items
      .sort((a, b) => {
        const byRequest =
          Number(b.summary.section === 'REQUEST') -
          Number(a.summary.section === 'REQUEST');
        return byRequest !== 0 ? byRequest : sortKey(b.room) - sortKey(a.room);
      })
      .map((item) => item.summary);
  }

  async get(userId: string, id: string): Promise<ConversationDetailModel> {
    const room = await this.requireMember(userId, id);
    const lookups = this.newLookups();
    await this.preload([room], lookups);
    const header = this.headerOf(room, userId, lookups);
    const member = this.memberOf(room, userId);
    const collaboration = room.collaboration;
    const [unread, lastMessages, latestTerms, progress, blockedByMe] =
      await Promise.all([
        this.repository.unreadCounts(userId, [
          {
            id: room.id,
            lastSeq: room.lastSeq,
            lastReadSeq: member.lastReadSeq,
          },
        ]),
        this.repository.lastMessages([room]),
        collaboration.kind === 'BRAND_CONTRACT'
          ? this.terms.latest(collaboration.id)
          : Promise.resolve(null),
        this.collaborations.mapContractProgress([collaboration.id]),
        this.repository.hasBlocked(userId, header.counterpart.userId),
      ]);
    const viewer: SystemViewer = { userId, role: header.role };
    const last = lastMessages[0] ?? null;
    const campaign = collaboration.campaignId
      ? (lookups.campaigns.get(collaboration.campaignId) ?? null)
      : null;
    const isCreator = header.role === 'CREATOR';
    const open = room.status === 'OPEN';
    const brandContract = collaboration.kind === 'BRAND_CONTRACT';
    const card = isCreator ? await this.creators.getCardCopy(userId) : null;
    return {
      id: room.id,
      kind: collaboration.kind,
      status: room.status,
      section: this.sectionOf(room, userId),
      counterpart: header.counterpart,
      contextLabel: header.contextLabel,
      lastMessage: last
        ? {
            kind: last.kind,
            preview: this.previewOfMessage(last, viewer),
            at: last.createdAt.toISOString(),
          }
        : null,
      unreadCount: unread.get(room.id) ?? 0,
      muted: member.mutedAt !== null,
      collaborationId: collaboration.id,
      stage: collaboration.stage,
      myRole: header.role,
      requestedByMe: room.requestedById === userId,
      blockedByMe,
      lastSeq: room.lastSeq,
      lastReadSeq: member.lastReadSeq,
      terms: latestTerms
        ? toTermsVersionModel(latestTerms, collaboration.commissionerId)
        : null,
      campaignTerms:
        brandContract && collaboration.stage === 'INQUIRY' && campaign
          ? {
              fee: campaign.fee,
              format: campaign.format,
              productProvided: campaign.productProvided,
              startFrom: campaign.startFrom.toISOString().slice(0, 10),
            }
          : null,
      // 가게 오퍼는 수락된 판본의 조건 사본이 방 머리의 보상이다.
      storeTerms:
        collaboration.kind === 'STORE_OFFER'
          ? readTerms(collaboration.terms)
          : null,
      contractStatus: progress.get(collaboration.id) ?? 'NONE',
      canSend: open,
      canSendContentCard: open && isCreator && !!card?.headline,
      canProposeTerms:
        open && brandContract && negotiableStages.includes(collaboration.stage),
      canDrop:
        open &&
        brandContract &&
        preContractStages.includes(collaboration.stage),
      canLikeCampaign:
        open && isCreator && brandContract && collaboration.stage === 'INQUIRY',
    };
  }

  async listMessages(
    userId: string,
    id: string,
    query: ListMessagesQuery,
  ): Promise<MessageModel[]> {
    const room = await this.requireMember(userId, id);
    const rows = await this.repository.listMessages(room.id, {
      afterSeq: query.afterSeq,
      beforeSeq: query.beforeSeq,
      limit: query.limit ?? MESSAGES_PAGE_MAX,
    });
    const viewer = this.viewerOf(room, userId);
    return rows.map((row) => this.toMessage(row, viewer));
  }

  // 같은 clientId로 다시 보내면 새 행 없이 첫 행을 돌려준다(보내기를 다시 누르거나 연결이 끊겼다 붙은 경우).
  async send(
    userId: string,
    id: string,
    input: SendMessageDto,
  ): Promise<MessageModel> {
    const room = await this.requireMember(userId, id);
    const viewer = this.viewerOf(room, userId);
    const first = await this.repository.findByClientId(
      room.id,
      userId,
      input.clientId,
    );
    if (first) return this.toMessage(first, viewer);

    let text: string | null = null;
    let cardTitle: string | null = null;
    let cardPhotoPath: string | null = null;
    if (input.kind === 'TEXT') {
      text = (input.text ?? '').trim();
      if (text === '') {
        throw new AppError('VALIDATION_FAILED', '메시지를 입력해 주세요.');
      }
      // 글자 수는 코드 포인트로 센다(DB 제약과 같다).
      if (Array.from(text).length > 1000) {
        throw new AppError('VALIDATION_FAILED', '1,000자까지 보낼 수 있어요.');
      }
    } else {
      // 생성된 클라이언트는 보내지 않은 칸을 null로 보낸다: null은 보내지 않은 것과 같다.
      if (input.text !== undefined && input.text !== null) {
        throw new AppError(
          'VALIDATION_FAILED',
          '콘텐츠 카드에는 글을 붙일 수 없어요.',
        );
      }
      if (viewer.role !== 'CREATOR') {
        throw new AppError(
          'FORBIDDEN',
          '크리에이터만 콘텐츠 카드를 보낼 수 있어요.',
        );
      }
      const card = await this.creators.getCardCopy(userId);
      if (!card?.headline) {
        throw new AppError('CONFLICT', '보낼 콘텐츠 카드가 아직 없어요.');
      }
      // 보낸 뒤에 프로필의 카드를 고쳐도 대화의 카드는 그대로여야 해서 사본으로 넣는다.
      cardTitle = card.headline;
      cardPhotoPath = card.photoPath;
    }
    if (room.status !== 'OPEN') {
      throw new AppError('CONFLICT', '지금은 메시지를 보낼 수 없어요.');
    }

    let row: Message | null;
    try {
      row = await this.repository.appendMessage({
        conversationId: room.id,
        senderId: userId,
        clientId: input.clientId,
        kind: input.kind,
        text,
        cardTitle,
        cardPhotoPath,
        systemCode: null,
        systemParams: null,
        requireOpen: true,
        now: this.clock.now(),
      });
    } catch (error) {
      // 같은 clientId가 동시에 두 번 들어와 한쪽이 유일 제약에 졌다: 이긴 쪽의 행을 돌려준다.
      if (!isUniqueViolation(error)) throw error;
      const winner = await this.repository.findByClientId(
        room.id,
        userId,
        input.clientId,
      );
      if (!winner) throw error;
      return this.toMessage(winner, viewer);
    }
    if (!row) {
      throw new AppError('CONFLICT', '지금은 메시지를 보낼 수 없어요.');
    }
    await this.events.publish({
      conversationId: room.id,
      collaborationId: room.collaborationId,
      message: row,
      memberIds: room.members.map((m) => m.userId),
    });
    return this.toMessage(row, viewer);
  }

  async markRead(userId: string, id: string, seq: number): Promise<void> {
    const room = await this.requireMember(userId, id);
    if (seq > room.lastSeq) {
      throw new AppError(
        'VALIDATION_FAILED',
        '방의 마지막 번호보다 큰 번호까지는 읽을 수 없어요.',
      );
    }
    await this.repository.markRead(room.id, userId, seq, this.clock.now());
    // 읽은 번호는 내 다른 기기만 알면 된다.
    await this.publishUpdated(room.id, 'READ', [userId]);
  }

  async setMuted(
    userId: string,
    id: string,
    muted: boolean,
  ): Promise<{ muted: boolean }> {
    const room = await this.requireMember(userId, id);
    await this.repository.setMuted(room.id, userId, muted, this.clock.now());
    // 알림 끄기는 내 설정이라 내 다른 기기만 알면 된다.
    await this.publishUpdated(room.id, 'STATUS', [userId]);
    return { muted };
  }

  private async requireMember(
    userId: string,
    id: string,
  ): Promise<RoomWithCollaboration> {
    const room = UUID.test(id)
      ? await this.repository.findForMember(id, userId)
      : null;
    if (!room) throw notFound();
    return room;
  }

  private memberOf(room: RoomWithCollaboration, userId: string) {
    const member = room.members.find((m) => m.userId === userId);
    if (!member) throw notFound();
    return member;
  }

  private viewerOf(room: RoomWithCollaboration, userId: string): SystemViewer {
    return {
      userId,
      role:
        room.collaboration.creatorId === userId ? 'CREATOR' : 'COMMISSIONER',
    };
  }

  // 내가 답해야 하는 메시지 요청만 위에 모인다. 내가 보낸 요청은 일반 목록에서 "수락을 기다리고 있어요"로 보인다.
  private sectionOf(
    room: RoomWithCollaboration,
    userId: string,
  ): 'REQUEST' | 'NORMAL' {
    return room.status === 'REQUESTED' && room.requestedById !== userId
      ? 'REQUEST'
      : 'NORMAL';
  }

  private previewOfMessage(message: Message, viewer: SystemViewer): string {
    if (message.kind === 'TEXT') return previewOf(message.text ?? '');
    if (message.kind === 'CONTENT_CARD') return CARD_PREVIEW;
    return previewOf(this.systemText(message, viewer));
  }

  private systemText(message: Message, viewer: SystemViewer): string {
    const params =
      message.systemParams !== null &&
      typeof message.systemParams === 'object' &&
      !Array.isArray(message.systemParams)
        ? (message.systemParams as SystemParams)
        : {};
    return renderSystemLine(message.systemCode as SystemCode, params, viewer);
  }

  private toMessage(message: Message, viewer: SystemViewer): MessageModel {
    const mine =
      message.senderId !== null && message.senderId === viewer.userId;
    return {
      id: message.id,
      seq: message.seq,
      kind: message.kind,
      mine,
      clientId: mine ? message.clientId : null,
      text:
        message.kind === 'TEXT'
          ? message.text
          : message.kind === 'SYSTEM'
            ? this.systemText(message, viewer)
            : null,
      card:
        message.kind === 'CONTENT_CARD'
          ? {
              title: message.cardTitle ?? '',
              photoUrl: message.cardPhotoPath
                ? this.storage.publicUrl(message.cardPhotoPath)
                : null,
            }
          : null,
      createdAt: message.createdAt.toISOString(),
    };
  }

  private newLookups(): Lookups {
    return {
      creators: new Map(),
      brands: new Map(),
      stores: new Map(),
      campaigns: new Map(),
    };
  }

  // 방마다 읽지 않고 한 번에 읽어 둔다(브랜드 프로필은 한꺼번에, 나머지는 한 건씩 한 번만).
  private async preload(
    rooms: RoomWithCollaboration[],
    lookups: Lookups,
  ): Promise<void> {
    const brandRooms = rooms.filter(
      (r) => r.collaboration.kind === 'BRAND_CONTRACT',
    );
    const brandIds = [
      ...new Set(brandRooms.map((r) => r.collaboration.commissionerId)),
    ];
    if (brandIds.length > 0) {
      const profiles = await this.brands.findProfiles(brandIds);
      for (const [id, profile] of profiles) {
        lookups.brands.set(id, {
          name: profile.name,
          photoUrl: profile.photoUrl,
        });
      }
    }
    const creatorIds = [
      ...new Set(rooms.map((r) => r.collaboration.creatorId)),
    ];
    await Promise.all([
      ...creatorIds.map(async (id) => {
        const summary = await this.creators.getSummary(id);
        lookups.creators.set(
          id,
          summary
            ? { name: summary.displayName, photoUrl: summary.photoUrl }
            : null,
        );
      }),
      ...[
        ...new Set(
          brandRooms.flatMap((r) =>
            r.collaboration.campaignId ? [r.collaboration.campaignId] : [],
          ),
        ),
      ].map(async (id) => {
        lookups.campaigns.set(id, await this.campaigns.getById(id));
      }),
      ...[
        ...new Set(
          rooms.flatMap((r) =>
            r.collaboration.storeId ? [r.collaboration.storeId] : [],
          ),
        ),
      ].map(async (id) => {
        const store = await this.stores.getPartyCard(id);
        lookups.stores.set(
          id,
          store ? { name: store.name, photoUrl: store.coverPhotoUrl } : null,
        );
      }),
    ]);
  }

  // 상대 줄(이름·사진)과 맥락 줄. 프로필이 지워졌으면 역할 이름으로 대신한다.
  private headerOf(
    room: RoomWithCollaboration,
    userId: string,
    lookups: Lookups,
  ): Header {
    const { collaboration } = room;
    const role = this.viewerOf(room, userId).role;
    const creator = lookups.creators.get(collaboration.creatorId) ?? null;
    if (collaboration.kind === 'BRAND_CONTRACT') {
      const brand = lookups.brands.get(collaboration.commissionerId) ?? null;
      const campaign = collaboration.campaignId
        ? (lookups.campaigns.get(collaboration.campaignId) ?? null)
        : null;
      return {
        role,
        contextLabel: campaign?.headline ?? brand?.name ?? '브랜드 협업',
        counterpart:
          role === 'CREATOR'
            ? {
                userId: collaboration.commissionerId,
                name: brand?.name ?? '브랜드',
                photoUrl: brand?.photoUrl ?? null,
              }
            : {
                userId: collaboration.creatorId,
                name: creator?.name ?? '크리에이터',
                photoUrl: creator?.photoUrl ?? null,
              },
      };
    }
    const store = collaboration.storeId
      ? (lookups.stores.get(collaboration.storeId) ?? null)
      : null;
    return {
      role,
      contextLabel: store?.name ?? '가게',
      counterpart:
        role === 'CREATOR'
          ? {
              userId: collaboration.commissionerId,
              name: store?.name ?? '가게',
              photoUrl: store?.photoUrl ?? null,
            }
          : {
              userId: collaboration.creatorId,
              name: creator?.name ?? '크리에이터',
              photoUrl: creator?.photoUrl ?? null,
            },
    };
  }
}
