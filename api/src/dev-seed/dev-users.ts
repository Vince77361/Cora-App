import type { PrismaClient, UserRole } from '@prisma/client';

// public.users에 역할을 맞추는 포트. 테스트에서는 cora_test의 Prisma를 그대로 꽂는다.
export interface DevUsers {
  // 행이 없으면 만들고, 있으면 역할만 맞춘다. 새로 만들었는지를 돌려준다.
  upsertRole(id: string, role: UserRole): Promise<{ created: boolean }>;
}

// 서버 모듈이 아니라 한 번 돌고 끝나는 시드라서 repository를 거치지 않고 Prisma를 직접 쓴다.
export class PrismaDevUsers implements DevUsers {
  constructor(private readonly prisma: PrismaClient) {}

  async upsertRole(id: string, role: UserRole): Promise<{ created: boolean }> {
    const existing = await this.prisma.user.findUnique({
      where: { id },
      select: { id: true },
    });
    // deletedAt을 비우는 건, 지워진 채로 남은 개발 계정이 시드 뒤에도 로그인되지 않는 것을 막기 위해서다.
    await this.prisma.user.upsert({
      where: { id },
      create: { id, role },
      update: { role, deletedAt: null },
    });
    return { created: existing === null };
  }
}
