import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { prisma } from './setup-db';

const BRAND = '77777777-7777-4777-8777-777777777771';
const CREATOR = '77777777-7777-4777-8777-777777777772';
const CREATOR_2 = '77777777-7777-4777-8777-777777777773';

// 거절 이유까지 확인한다. 아무 오류나 통과하면 외래 키·검증 오류로도 테스트가 통과해 버린다.
function uniqueOn(...columns: string[]) {
  return { code: 'P2002', meta: { target: columns } };
}

// 마이그레이션 파일의 BEGIN/END 사이(기존 협업마다 방과 참가자 채우기)만 cora_test에서 다시 실행한다.
// 테이블을 만드는 앞부분은 migrate deploy가 이미 적용했다. 채우기는 여러 번 돌려도 같은 결과여야 한다.
function backfillSql(): string {
  const dir = join(__dirname, '../../prisma/migrations');
  const folder = readdirSync(dir).find((d) =>
    d.endsWith('_chat_contract_schema'),
  );
  if (!folder) throw new Error('대화·계약 마이그레이션이 없어요.');
  const sql = readFileSync(join(dir, folder, 'migration.sql'), 'utf8');
  const match =
    /-- BEGIN conversation-backfill\n([\s\S]*?)-- END conversation-backfill/.exec(
      sql,
    );
  if (!match) throw new Error('채우기 SQL의 BEGIN/END 묶음을 찾지 못했어요.');
  return match[1];
}

// 준비된 문장 하나에는 명령을 하나만 보낼 수 있어 세미콜론으로 나눠 차례로 실행한다.
async function runBackfill() {
  const statements = backfillSql()
    .split(';')
    .map((statement) => statement.trim())
    .filter((statement) => statement.length > 0);
  for (const statement of statements) {
    await prisma.$executeRawUnsafe(statement);
  }
}

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: BRAND, role: 'BRAND' },
      { id: CREATOR, role: 'CREATOR' },
      { id: CREATOR_2, role: 'CREATOR' },
    ],
  });
});

async function createCollaboration(creatorId = CREATOR) {
  return prisma.collaboration.create({
    data: {
      kind: 'BRAND_CONTRACT',
      stage: 'INQUIRY',
      commissionerId: BRAND,
      creatorId,
      terms: {},
      settlementMethod: 'FIXED',
    },
  });
}

async function createRoom(collaborationId: string) {
  return prisma.conversation.create({
    data: { collaborationId, status: 'OPEN' },
  });
}

function textMessage(
  conversationId: string,
  seq: number,
  over: { senderId?: string; clientId?: string } = {},
) {
  return prisma.message.create({
    data: {
      conversationId,
      seq,
      kind: 'TEXT',
      text: '안녕하세요',
      senderId: over.senderId ?? CREATOR,
      clientId: over.clientId,
    },
  });
}

function contractData(collaborationId: string) {
  return {
    collaborationId,
    status: 'AWAITING_BRAND' as const,
    termsVersion: 1,
    termsSnapshot: { version: 1 },
    creatorConsentedAt: new Date('2026-12-01T00:00:00Z'),
    creatorConsentTexts: ['제작비를 받아요'],
    brandConsentTexts: [],
  };
}

describe('collaboration stages', () => {
  it('allows INQUIRY to become MATCHED in the same row and AGREED to fall back to NEGOTIATING', async () => {
    const collaboration = await createCollaboration();
    const matched = await prisma.collaboration.update({
      where: { id: collaboration.id },
      data: { stage: 'MATCHED' },
    });
    expect(matched.id).toBe(collaboration.id);
    expect(matched.stage).toBe('MATCHED');

    const agreed = await prisma.collaboration.update({
      where: { id: collaboration.id },
      data: { stage: 'AGREED' },
    });
    const back = await prisma.collaboration.update({
      where: { id: agreed.id },
      data: { stage: 'NEGOTIATING' },
    });
    expect(back.stage).toBe('NEGOTIATING');
    // 새 칸의 기본값: 수정 한 번 더 허용 횟수는 0, 메모·그만둔 이유는 비어 있다.
    expect(back.extraRevisionsAllowed).toBe(0);
    expect(back.creatorNote).toBeNull();
    expect(back.dropReason).toBeNull();
  });
});

describe('messages', () => {
  it('rejects two messages with the same sequence number in one conversation', async () => {
    const room = await createRoom((await createCollaboration()).id);
    await textMessage(room.id, 1);
    await expect(
      textMessage(room.id, 1, { senderId: BRAND }),
    ).rejects.toMatchObject(uniqueOn('conversation_id', 'seq'));
    // 다른 방이면 같은 번호가 가능하다.
    const other = await createRoom((await createCollaboration(CREATOR_2)).id);
    await expect(textMessage(other.id, 1)).resolves.toBeDefined();
  });

  it('rejects a second message with the same sender and client id', async () => {
    const room = await createRoom((await createCollaboration()).id);
    await textMessage(room.id, 1, { clientId: 'client-1' });
    await expect(
      textMessage(room.id, 2, { clientId: 'client-1' }),
    ).rejects.toMatchObject(
      uniqueOn('conversation_id', 'sender_id', 'client_id'),
    );
    // 보낸 사람이 다르면 같은 clientId도 따로다. 안내 줄(보낸 사람·clientId 없음)은 여러 줄이 된다.
    await expect(
      textMessage(room.id, 3, { senderId: BRAND, clientId: 'client-1' }),
    ).resolves.toBeDefined();
    for (const seq of [4, 5]) {
      await prisma.message.create({
        data: {
          conversationId: room.id,
          seq,
          kind: 'SYSTEM',
          systemCode: 'MATCHED',
        },
      });
    }
  });

  it('rejects a text longer than 1000 characters', async () => {
    const room = await createRoom((await createCollaboration()).id);
    await expect(
      prisma.message.create({
        data: {
          conversationId: room.id,
          seq: 1,
          kind: 'TEXT',
          senderId: CREATOR,
          text: 'a'.repeat(1001),
        },
      }),
    ).rejects.toThrow(/messages_text_length/);
  });
});

describe('conversations', () => {
  it('allows only one conversation per collaboration and one membership per user', async () => {
    const collaboration = await createCollaboration();
    const room = await createRoom(collaboration.id);
    await expect(createRoom(collaboration.id)).rejects.toMatchObject(
      uniqueOn('collaboration_id'),
    );
    await prisma.conversationMember.create({
      data: { conversationId: room.id, userId: CREATOR },
    });
    await expect(
      prisma.conversationMember.create({
        data: { conversationId: room.id, userId: CREATOR },
      }),
    ).rejects.toMatchObject(uniqueOn('conversation_id', 'user_id'));
    const member = await prisma.conversationMember.findFirstOrThrow({
      where: { conversationId: room.id },
    });
    expect(member.lastReadSeq).toBe(0);
    expect(room.lastSeq).toBe(0);
  });

  it('backfills an open conversation for every existing collaboration', async () => {
    const first = await createCollaboration();
    const second = await createCollaboration(CREATOR_2);
    // 이미 방이 있는 협업은 건드리지 않는다.
    const existing = await createRoom(second.id);
    await runBackfill();
    await runBackfill();

    const rooms = await prisma.conversation.findMany({
      include: { members: true },
    });
    expect(rooms).toHaveLength(2);
    for (const room of rooms) {
      expect(room.status).toBe('OPEN');
      expect(room.lastSeq).toBe(0);
      const creator = room.collaborationId === first.id ? CREATOR : CREATOR_2;
      expect(room.members.map((m) => m.userId).sort()).toEqual(
        [BRAND, creator].sort(),
      );
    }
    expect(rooms.find((r) => r.collaborationId === second.id)?.id).toBe(
      existing.id,
    );
    // 안내 줄은 만들지 않는다.
    expect(await prisma.message.count()).toBe(0);
  });
});

describe('contracts', () => {
  it('allows only one live contract per collaboration but keeps voided ones', async () => {
    const collaboration = await createCollaboration();
    const first = await prisma.contract.create({
      data: contractData(collaboration.id),
    });
    await expect(
      prisma.contract.create({ data: contractData(collaboration.id) }),
    ).rejects.toMatchObject(uniqueOn('collaboration_id'));

    await prisma.contract.update({
      where: { id: first.id },
      data: {
        status: 'VOIDED',
        voidedAt: new Date('2026-12-02T00:00:00Z'),
        voidReason: 'NEW_TERMS',
      },
    });
    await prisma.contract.create({
      data: { ...contractData(collaboration.id), termsVersion: 2 },
    });
    expect(
      await prisma.contract.count({
        where: { collaborationId: collaboration.id },
      }),
    ).toBe(2);
  });

  it('rejects an unknown void reason', async () => {
    const collaboration = await createCollaboration();
    await expect(
      prisma.contract.create({
        data: { ...contractData(collaboration.id), voidReason: 'WHATEVER' },
      }),
    ).rejects.toThrow(/contracts_void_reason/);
  });
});

describe('blocks and reports', () => {
  it('rejects a second block of the same user by the same blocker', async () => {
    await prisma.block.create({
      data: { blockerId: BRAND, blockedId: CREATOR },
    });
    await expect(
      prisma.block.create({ data: { blockerId: BRAND, blockedId: CREATOR } }),
    ).rejects.toMatchObject(uniqueOn('blocker_id', 'blocked_id'));
    // 반대 방향은 다른 줄이다.
    await expect(
      prisma.block.create({ data: { blockerId: CREATOR, blockedId: BRAND } }),
    ).resolves.toBeDefined();
  });

  it('rejects a second report by the same reporter on the same target', async () => {
    const data = {
      reporterId: BRAND,
      targetKind: 'USER' as const,
      targetId: CREATOR,
      reason: 'SPAM' as const,
    };
    await prisma.report.create({ data });
    await expect(prisma.report.create({ data })).rejects.toMatchObject(
      uniqueOn('reporter_id', 'target_kind', 'target_id'),
    );
    await expect(
      prisma.report.create({ data: { ...data, reporterId: CREATOR } }),
    ).resolves.toBeDefined();
  });

  it('rejects a report detail longer than 500 characters', async () => {
    await expect(
      prisma.report.create({
        data: {
          reporterId: BRAND,
          targetKind: 'USER',
          targetId: CREATOR,
          reason: 'OTHER',
          detail: 'a'.repeat(501),
        },
      }),
    ).rejects.toThrow(/reports_detail_length/);
  });
});
