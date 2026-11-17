import { Injectable } from '@nestjs/common';
import { Campaign, Conversation, Message, Prisma } from '@prisma/client';
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
import { StoragePort } from '../integrations/storage/storage.port';
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
import { MessageEvents } from './message-events';
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

const notFound = (): AppError =>
  new AppError('NOT_FOUND', '대화를 찾을 수 없어요.');

// 대화방과 메시지. 방은 협업 하나에 하나이고 참가자(맡기는 쪽, 크리에이터) 둘만 읽고 쓴다.
// 참가자가 아니면 방이 없는 것과 같다(404).
@Injectable()
export class ConversationsService {
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
    private readonly clock: Clock,
  ) {}

  // 협업과 같은 트랜잭션에서 방과 참가자 둘을 만든다. 이미 방이 있으면 그것을 돌려준다.
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
    if (existing) return existing;
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

  // 저장된 메시지를 구독자(푸시, 실시간)에게 알린다. 이미 커밋된 메시지에만 부른다.
  async publishCreated(messageId: string): Promise<void> {
    const message = await this.repository.findMessage(messageId);
    if (!message) return;
    const room = await this.repository.findWithMembers(message.conversationId);
    if (!room) return;
    await this.events.publish({
      conversationId: room.id,
      collaborationId: room.collaborationId,
      message,
      memberIds: room.members.map((m) => m.userId),
    });
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
      if (input.text !== undefined) {
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
  }

  async setMuted(
    userId: string,
    id: string,
    muted: boolean,
  ): Promise<{ muted: boolean }> {
    const room = await this.requireMember(userId, id);
    await this.repository.setMuted(room.id, userId, muted, this.clock.now());
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
