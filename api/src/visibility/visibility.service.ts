import { Injectable } from '@nestjs/common';
import type { IndustryCategory } from '@prisma/client';
import { PrinciplesService } from '../principles/principles.service';
import { isBlocked } from './visibility-rules';

export interface VisibilityViewer {
  userId: string;
  kind: 'STORE' | 'BRAND';
  industry: IndustryCategory;
}

export interface VisibilityCommissioner {
  ownerId: string;
  industry: IndustryCategory;
}

// 누가 누구를 볼 수 있는지의 단일 창구. 크리에이터를 찾는 쪽(가게·브랜드)과 가게·브랜드를 찾는 쪽(크리에이터)의
// 조회는 모두 여기를 거친다. 조회마다 DB에서 읽어서, 피하는 업종을 나중에 더해도 곧바로 반영된다.
// 5번 계획이 차단을 여기에 더한다.
@Injectable()
export class VisibilityService {
  constructor(private readonly principles: PrinciplesService) {}

  // 본인은 보이지 않는다. 피하는 업종이면 보이지 않는다. 브랜드에게는 협업 원칙이 있는 크리에이터만 보인다(사장님에게는 원칙이 없어도 보인다).
  async creatorVisibleTo(
    creatorId: string,
    viewer: VisibilityViewer,
  ): Promise<boolean> {
    return (await this.filterCreators([creatorId], viewer)).length === 1;
  }

  // 입력 순서를 지키고 중복은 그대로 둔다. 한 번의 조회로 거른다.
  async filterCreators(
    creatorIds: string[],
    viewer: VisibilityViewer,
  ): Promise<string[]> {
    const mine = creatorIds.filter((id) => id !== viewer.userId);
    if (mine.length === 0) return [];
    const found = await this.principles.findMany(mine);
    return mine.filter((id) => {
      const principles = found.get(id) ?? null;
      if (viewer.kind === 'BRAND' && principles === null) return false;
      return !isBlocked(principles, viewer.industry);
    });
  }

  // 크리에이터가 그 업종을 피하면 가게·브랜드는 그 크리에이터에게 없는 것처럼 보인다.
  async commissionerVisibleTo(
    target: VisibilityCommissioner,
    creatorId: string,
  ): Promise<boolean> {
    return (await this.filterCommissioners([target], creatorId)).length === 1;
  }

  // 가게 목록처럼 여러 곳을 한 번에 거른다. 크리에이터의 원칙은 한 번만 읽는다.
  async filterCommissioners<T extends VisibilityCommissioner>(
    targets: T[],
    creatorId: string,
  ): Promise<T[]> {
    if (targets.length === 0) return [];
    const principles = await this.principles.find(creatorId);
    return targets.filter((target) => !isBlocked(principles, target.industry));
  }
}
