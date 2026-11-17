import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// 차단 관계를 읽는 저장소. blocks 표는 안전(차단·신고) 모듈이 쓰지만, 안전 모듈은 오퍼 모듈을 import하고 오퍼 모듈은
// 이 모듈을 import하므로 안전 모듈의 것을 가져다 쓰면 순환이 된다. 그래서 읽기만 여기서 직접 한다(협업 저장소가 오퍼 표를 읽는 것과 같다).
@Injectable()
export class VisibilityRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 이 사용자와 어느 방향으로든 차단 관계인 사용자들. 조회마다 DB에서 읽는다(차단 직후 곧바로 반영된다).
  async blockedPartners(userId: string): Promise<Set<string>> {
    const rows = await this.prisma.block.findMany({
      where: {
        deletedAt: null,
        OR: [{ blockerId: userId }, { blockedId: userId }],
      },
      select: { blockerId: true, blockedId: true },
    });
    return new Set(
      rows.map((row) =>
        row.blockerId === userId ? row.blockedId : row.blockerId,
      ),
    );
  }
}
