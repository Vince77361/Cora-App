import { Injectable } from '@nestjs/common';
import { FeaturedPost } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import type { FeaturedPostDraft } from './featured-post-rules';

export type FeaturedPostRow = FeaturedPost;

// 저장할 목록의 한 칸: 있던 게시물을 그대로 두거나(keepId) 새로 만든다(draft). 차례가 곧 순서(1번부터)다.
export type FeaturedPostPlanItem =
  { keepId: string } | { draft: FeaturedPostDraft };

// 순서를 옮기는 동안만 쓰는 임시 번호. 부분 유니크 인덱스는 문장 안에서 한 행씩 검사해서 두 게시물의 자리를 맞바꾸려면 비는 번호가 필요하다.
const TEMP_POSITION_OFFSET = 1000;

@Injectable()
export class FeaturedPostsRepository {
  constructor(private readonly prisma: PrismaService) {}

  // 살아 있는 대표 게시물, 순서대로.
  listLive(creatorId: string): Promise<FeaturedPostRow[]> {
    return this.prisma.featuredPost.findMany({
      where: { creatorId, deletedAt: null },
      orderBy: { position: 'asc' },
    });
  }

  // 여러 크리에이터의 것을 한 번에(카드 목록이 줄마다 읽지 않게).
  listLiveForCreators(creatorIds: string[]): Promise<FeaturedPostRow[]> {
    if (creatorIds.length === 0) return Promise.resolve([]);
    return this.prisma.featuredPost.findMany({
      where: { creatorId: { in: creatorIds }, deletedAt: null },
      orderBy: [{ creatorId: 'asc' }, { position: 'asc' }],
    });
  }

  // 한 트랜잭션으로 목록 전체를 바꾼다. 두 기기에서 동시에 와도 한 사람의 저장은 차례로 일어나도록 사용자 행을 잠근다.
  // 계획에 든 keepId가 그 사이에 없어졌으면 아무것도 바꾸지 않고 null을 돌려준다(서비스가 404로 바꾼다).
  replace(
    creatorId: string,
    plan: FeaturedPostPlanItem[],
    now: Date,
  ): Promise<FeaturedPostRow[] | null> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`
        SELECT id FROM users WHERE id = ${creatorId}::uuid FOR NO KEY UPDATE`;
      const live = await tx.featuredPost.findMany({
        where: { creatorId, deletedAt: null },
      });
      const liveIds = new Set(live.map((row) => row.id));
      const keepIds = plan.flatMap((item) =>
        'keepId' in item ? [item.keepId] : [],
      );
      if (keepIds.some((id) => !liveIds.has(id))) return null;

      // 빠지는 행을 먼저 지워서 그 자리의 순서 번호와 인스타 게시물 ID를 비운다.
      const keep = new Set(keepIds);
      const removed = live.filter((row) => !keep.has(row.id));
      if (removed.length > 0) {
        await tx.featuredPost.updateMany({
          where: { id: { in: removed.map((row) => row.id) } },
          data: { deletedAt: now },
        });
      }
      // 남는 행은 임시 번호로 비켜 놓고 새 자리에 놓는다.
      if (keepIds.length > 0) {
        await tx.featuredPost.updateMany({
          where: { id: { in: keepIds } },
          data: { position: { increment: TEMP_POSITION_OFFSET } },
        });
      }
      for (const [index, item] of plan.entries()) {
        const position = index + 1;
        if ('keepId' in item) {
          await tx.featuredPost.update({
            where: { id: item.keepId },
            data: { position },
          });
        } else {
          await tx.featuredPost.create({
            data: { creatorId, position, ...item.draft },
          });
        }
      }
      return tx.featuredPost.findMany({
        where: { creatorId, deletedAt: null },
        orderBy: { position: 'asc' },
      });
    });
  }
}
