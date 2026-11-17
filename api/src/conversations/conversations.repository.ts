import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import {
  Collaboration,
  Conversation,
  ConversationMember,
  ConversationStatus,
  Message,
  MessageKind,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export function isUniqueViolation(error: unknown): boolean {
  if (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  ) {
    return true;
  }
  // 날 SQL(문장 하나로 보내는 메시지 저장)의 유일 제약 위반은 P2010으로 감싸여 나온다.
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2010' &&
    JSON.stringify(error.meta ?? {}).includes('23505')
  );
}

export type RoomWithCollaboration = Conversation & {
  collaboration: Collaboration;
  members: ConversationMember[];
};

export interface NewMessage {
  conversationId: string;
  senderId: string | null;
  clientId: string | null;
  kind: MessageKind;
  text: string | null;
  cardTitle: string | null;
  cardPhotoPath: string | null;
  systemCode: string | null;
  systemParams: Prisma.InputJsonValue | null;
  // 글·카드는 열린 방에만 쓴다. 안내 줄은 방의 상태와 상관없이 남는다(닫힌 방의 마지막 줄 등).
  requireOpen: boolean;
  now: Date;
}

interface MessageRow {
  id: string;
  conversation_id: string;
  seq: number;
  sender_id: string | null;
  client_id: string | null;
  kind: MessageKind;
  text: string | null;
  card_title: string | null;
  card_photo_path: string | null;
  system_code: string | null;
  system_params: Prisma.JsonValue | null;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

const fromRow = (row: MessageRow): Message => ({
  id: row.id,
  conversationId: row.conversation_id,
  seq: row.seq,
  senderId: row.sender_id,
  clientId: row.client_id,
  kind: row.kind,
  text: row.text,
  cardTitle: row.card_title,
  cardPhotoPath: row.card_photo_path,
  systemCode: row.system_code,
  systemParams: row.system_params,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  deletedAt: row.deleted_at,
});

// 대화방·참가자·메시지의 저장소. 모든 읽기와 쓰기가 tx를 받을 수 있다.
// 쓰는 곳은 updatedAt을 직접 받는다: @updatedAt은 벽시계라서 Clock과 어긋난다.
@Injectable()
export class ConversationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  private client(tx?: Prisma.TransactionClient) {
    return tx ?? this.prisma;
  }

  findByCollaborationId(
    collaborationId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Conversation | null> {
    return this.client(tx).conversation.findFirst({
      where: { collaborationId, deletedAt: null },
    });
  }

  // 두 사람 사이에 어느 방향으로든 차단이 있는가.
  async hasBlockBetween(
    a: string,
    b: string,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const count = await this.client(tx).block.count({
      where: {
        deletedAt: null,
        OR: [
          { blockerId: a, blockedId: b },
          { blockerId: b, blockedId: a },
        ],
      },
    });
    return count > 0;
  }

  async hasBlocked(blockerId: string, blockedId: string): Promise<boolean> {
    return (
      (await this.prisma.block.count({
        where: { blockerId, blockedId, deletedAt: null },
      })) > 0
    );
  }

  async createRoom(
    input: {
      collaborationId: string;
      status: ConversationStatus;
      requestedById: string | null;
      closedReason: string | null;
      memberIds: string[];
      now: Date;
    },
    tx: Prisma.TransactionClient,
  ): Promise<Conversation> {
    const { now } = input;
    const room = await tx.conversation.create({
      data: {
        collaborationId: input.collaborationId,
        status: input.status,
        requestedById: input.requestedById,
        closedReason: input.closedReason,
        createdAt: now,
        updatedAt: now,
      },
    });
    await tx.conversationMember.createMany({
      data: input.memberIds.map((userId) => ({
        conversationId: room.id,
        userId,
        createdAt: now,
        updatedAt: now,
      })),
    });
    return room;
  }

  // 내가 참가자인 방(협업과 참가자 포함). 내가 참가자가 아니면 null이라 호출하는 쪽이 404로 답한다.
  findForMember(
    id: string,
    userId: string,
  ): Promise<RoomWithCollaboration | null> {
    return this.prisma.conversation.findFirst({
      where: {
        id,
        deletedAt: null,
        members: { some: { userId, deletedAt: null } },
      },
      include: {
        collaboration: true,
        members: { where: { deletedAt: null } },
      },
    });
  }

  // 참가자 확인 없이 방과 참가자를 읽는다(커밋된 메시지를 구독자에게 알릴 때).
  findWithMembers(id: string): Promise<RoomWithCollaboration | null> {
    return this.prisma.conversation.findFirst({
      where: { id, deletedAt: null },
      include: {
        collaboration: true,
        members: { where: { deletedAt: null } },
      },
    });
  }

  // 목록의 재료. 내가 거절한 요청(내가 요청자가 아닌 DECLINED)은 뺀다.
  listForMember(userId: string): Promise<RoomWithCollaboration[]> {
    return this.prisma.conversation.findMany({
      where: {
        deletedAt: null,
        members: { some: { userId, deletedAt: null } },
        NOT: {
          status: 'DECLINED',
          requestedById: { not: userId },
        },
      },
      include: {
        collaboration: true,
        members: { where: { deletedAt: null } },
      },
    });
  }

  // 방마다 마지막 번호의 메시지.
  lastMessages(rooms: { id: string; lastSeq: number }[]): Promise<Message[]> {
    const pairs = rooms
      .filter((room) => room.lastSeq > 0)
      .map((room) => ({ conversationId: room.id, seq: room.lastSeq }));
    if (pairs.length === 0) return Promise.resolve([]);
    return this.prisma.message.findMany({
      where: { deletedAt: null, OR: pairs },
    });
  }

  // 방마다 내 읽은 번호 뒤에 내가 보내지 않은 메시지의 수.
  async unreadCounts(
    userId: string,
    rooms: { id: string; lastReadSeq: number; lastSeq: number }[],
  ): Promise<Map<string, number>> {
    const open = rooms.filter((room) => room.lastSeq > room.lastReadSeq);
    if (open.length === 0) return new Map();
    const rows = await this.prisma.message.groupBy({
      by: ['conversationId'],
      where: {
        deletedAt: null,
        AND: [
          {
            OR: open.map((room) => ({
              conversationId: room.id,
              seq: { gt: room.lastReadSeq },
            })),
          },
          { OR: [{ senderId: null }, { senderId: { not: userId } }] },
        ],
      },
      _count: { _all: true },
    });
    return new Map(rows.map((row) => [row.conversationId, row._count._all]));
  }

  findByClientId(
    conversationId: string,
    senderId: string,
    clientId: string,
  ): Promise<Message | null> {
    return this.prisma.message.findFirst({
      where: { conversationId, senderId, clientId, deletedAt: null },
    });
  }

  findMessage(id: string): Promise<Message | null> {
    return this.prisma.message.findFirst({ where: { id, deletedAt: null } });
  }

  // 번호 순서대로 한 쪽을 읽는다. 위로 넘겨 볼 때(beforeSeq)와 마지막 N개는 큰 번호부터 잘라 오름차순으로 돌려준다.
  async listMessages(
    conversationId: string,
    page: { afterSeq?: number; beforeSeq?: number; limit: number },
  ): Promise<Message[]> {
    const seq: Prisma.IntFilter = {};
    if (page.afterSeq !== undefined) seq.gt = page.afterSeq;
    if (page.beforeSeq !== undefined) seq.lt = page.beforeSeq;
    const where: Prisma.MessageWhereInput = {
      conversationId,
      deletedAt: null,
      ...(Object.keys(seq).length > 0 ? { seq } : {}),
    };
    if (page.afterSeq !== undefined) {
      return this.prisma.message.findMany({
        where,
        orderBy: { seq: 'asc' },
        take: page.limit,
      });
    }
    const rows = await this.prisma.message.findMany({
      where,
      orderBy: { seq: 'desc' },
      take: page.limit,
    });
    return rows.reverse();
  }

  // 메시지 번호를 올리고 저장하는 일을 문장 하나로 한다: 방 행의 조건부 갱신(UPDATE ... RETURNING last_seq)이 번호를 정하고
  // 그 번호로 바로 INSERT한다. 같은 방의 동시 요청은 방 행의 잠금에서 한 줄로 서서 번호가 빠지거나 겹치지 않고,
  // 문장이 실패하면(유일 제약 위반 등) 번호 증가도 함께 사라진다. 원격 풀러에서 대화형 트랜잭션의 5초 제한을 피하는 이점도 있다.
  // 조건(열린 방)이 맞지 않으면 null이다.
  async appendMessage(
    input: NewMessage,
    tx?: Prisma.TransactionClient,
  ): Promise<Message | null> {
    const openOnly = input.requireOpen
      ? Prisma.sql`AND status = 'OPEN'::conversation_status`
      : Prisma.empty;
    const params =
      input.systemParams === null ? null : JSON.stringify(input.systemParams);
    const rows = await this.client(tx).$queryRaw<MessageRow[]>`
      WITH bumped AS (
        UPDATE conversations
        SET last_seq = last_seq + 1, last_message_at = ${input.now}, updated_at = ${input.now}
        WHERE id = ${input.conversationId}::uuid AND deleted_at IS NULL ${openOnly}
        RETURNING id, last_seq
      )
      INSERT INTO messages (
        id, conversation_id, seq, sender_id, client_id, kind, text,
        card_title, card_photo_path, system_code, system_params, created_at, updated_at
      )
      SELECT
        ${randomUUID()}::uuid, bumped.id, bumped.last_seq, ${input.senderId}::uuid, ${input.clientId},
        ${input.kind}::message_kind, ${input.text}, ${input.cardTitle}, ${input.cardPhotoPath},
        ${input.systemCode}, ${params}::jsonb, ${input.now}, ${input.now}
      FROM bumped
      RETURNING *`;
    return rows[0] ? fromRow(rows[0]) : null;
  }

  // 읽은 번호는 줄어들지 않는다(GREATEST).
  async markRead(
    conversationId: string,
    userId: string,
    seq: number,
    now: Date,
  ): Promise<void> {
    await this.prisma.$executeRaw`
      UPDATE conversation_members
      SET last_read_seq = GREATEST(last_read_seq, ${seq}), updated_at = ${now}
      WHERE conversation_id = ${conversationId}::uuid AND user_id = ${userId}::uuid
        AND deleted_at IS NULL`;
  }

  async setMuted(
    conversationId: string,
    userId: string,
    muted: boolean,
    now: Date,
  ): Promise<void> {
    await this.prisma.conversationMember.updateMany({
      where: { conversationId, userId, deletedAt: null },
      data: { mutedAt: muted ? now : null, updatedAt: now },
    });
  }
}
