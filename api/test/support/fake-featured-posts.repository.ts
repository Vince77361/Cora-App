import { randomUUID } from 'node:crypto';
import {
  FeaturedPostPlanItem,
  FeaturedPostRow,
  FeaturedPostsRepository,
} from '../../src/creators/featured-posts.repository';

// 서비스 규칙만 보려고 메모리에 저장하는 손 구현. 차례대로 1..n을 매기는 것까지 흉내 낸다.
export class FakeFeaturedPostsRepository extends FeaturedPostsRepository {
  readonly rows: FeaturedPostRow[] = [];

  constructor() {
    super(null as never);
  }

  listLive(creatorId: string): Promise<FeaturedPostRow[]> {
    return Promise.resolve(
      this.rows
        .filter((r) => r.creatorId === creatorId && !r.deletedAt)
        .sort((a, b) => a.position - b.position),
    );
  }

  listLiveForCreators(ids: string[]): Promise<FeaturedPostRow[]> {
    return Promise.resolve(
      this.rows.filter((r) => ids.includes(r.creatorId) && !r.deletedAt),
    );
  }

  async replace(
    creatorId: string,
    plan: FeaturedPostPlanItem[],
    now: Date,
  ): Promise<FeaturedPostRow[] | null> {
    const live = await this.listLive(creatorId);
    const keep = new Set(
      plan.flatMap((p) => ('keepId' in p ? [p.keepId] : [])),
    );
    if ([...keep].some((id) => !live.some((r) => r.id === id))) return null;
    for (const row of live) if (!keep.has(row.id)) row.deletedAt = now;
    plan.forEach((item, index) => {
      if ('keepId' in item) {
        const row = this.rows.find((r) => r.id === item.keepId);
        if (row) row.position = index + 1;
      } else {
        this.rows.push({
          id: randomUUID(),
          creatorId,
          position: index + 1,
          createdAt: now,
          deletedAt: null,
          ...item.draft,
        });
      }
    });
    return this.listLive(creatorId);
  }
}
