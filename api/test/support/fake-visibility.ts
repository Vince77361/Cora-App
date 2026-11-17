import type { IndustryCategory } from '@prisma/client';
import {
  VisibilityCommissioner,
  VisibilityService,
  VisibilityViewer,
} from '../../src/visibility/visibility.service';

// DB 없이 공통 필터를 흉내 낸다. 기본은 모든 것이 보인다.
export class FakeVisibility extends VisibilityService {
  // 이 업종의 가게는 크리에이터에게 숨긴다.
  hiddenIndustries = new Set<IndustryCategory>();
  // 이 크리에이터는 가게에게 숨긴다(그 업종을 피하는 크리에이터).
  hiddenCreators = new Set<string>();

  constructor() {
    super(null as never, null as never);
  }

  filterCreators(
    creatorIds: string[],
    viewer: VisibilityViewer,
  ): Promise<string[]> {
    void viewer;
    return Promise.resolve(
      creatorIds.filter((id) => !this.hiddenCreators.has(id)),
    );
  }

  filterCommissioners<T extends VisibilityCommissioner>(
    targets: T[],
  ): Promise<T[]> {
    return Promise.resolve(
      targets.filter((target) => !this.hiddenIndustries.has(target.industry)),
    );
  }

  async commissionerVisibleTo(
    target: VisibilityCommissioner,
  ): Promise<boolean> {
    return (await this.filterCommissioners([target])).length === 1;
  }
}
