import { Injectable } from '@nestjs/common';
import { InstagramConnection, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface InstagramConnectionData {
  handle: string;
  followers: number | null;
  // 키가 없는 개발 환경에서는 null이다. 운영은 키가 없으면 시작하지 않아 항상 봉해진 값이다.
  tokenEnc: string | null;
  refreshedAt: Date;
}

// 같은 아이디를 다른 크리에이터가 먼저 연결했을 때 나는 유일 제약 위반인가.
function isHandleTaken(error: unknown): boolean {
  if (
    !(error instanceof Prisma.PrismaClientKnownRequestError) ||
    error.code !== 'P2002'
  ) {
    return false;
  }
  const target = error.meta?.target;
  // target은 열 이름 배열이거나 인덱스 이름 문자열이다.
  const text = Array.isArray(target)
    ? target.join(',')
    : typeof target === 'string'
      ? target
      : '';
  return text.includes('handle');
}

@Injectable()
export class InstagramRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 지워진(deleted_at) 행은 없는 것으로 본다.
  findByCreatorId(creatorId: string): Promise<InstagramConnection | null> {
    return this.prisma.instagramConnection.findFirst({
      where: { creatorId, deletedAt: null },
    });
  }

  findByHandle(handle: string): Promise<InstagramConnection | null> {
    return this.prisma.instagramConnection.findFirst({
      where: { handle, deletedAt: null },
    });
  }

  // 크리에이터당 한 줄(creator_id 유니크)이고 아이디도 유일하다(handle 유니크).
  // 다시 연결하면 같은 줄을 덮어쓴다. 아이디를 다른 사람이 먼저 연결했으면 null이다.
  async upsert(
    creatorId: string,
    data: InstagramConnectionData,
  ): Promise<InstagramConnection | null> {
    try {
      return await this.prisma.instagramConnection.upsert({
        where: { creatorId },
        create: { creatorId, ...data },
        update: { ...data, deletedAt: null },
      });
    } catch (error) {
      if (isHandleTaken(error)) return null;
      throw error;
    }
  }

  // 연결을 풀면 토큰까지 지운다. 줄을 남겨 두면 아이디 유일 제약이 그 아이디를 계속 막는다.
  async remove(creatorId: string): Promise<void> {
    await this.prisma.instagramConnection.deleteMany({ where: { creatorId } });
  }
}
