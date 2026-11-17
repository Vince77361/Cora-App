import {
  Collaboration,
  CollaborationKind,
  CollaborationStage,
} from '@prisma/client';
import { SNAPSHOT_DAYS } from './job-keys';

const DAY_MS = 24 * 60 * 60 * 1000;

// 조회수를 재는 동안 협업이 머무는 단계. 가게 오퍼는 COUNTING이고, 브랜드 계약은 공통 모델 21장대로 PUBLISHED에 머문다.
// 정산(계산 만들기·확인·이의·캡처)과 조회수 읽기가 단계를 비교할 때 'COUNTING'을 적지 않고 이 함수를 쓴다.
export function measurementStageOf(
  kind: CollaborationKind,
): CollaborationStage {
  return kind === 'BRAND_CONTRACT' ? 'PUBLISHED' : 'COUNTING';
}

// 측정 기간의 마지막 날 번호 = 측정 일수(제출한 날부터 센 날수). 협업의 countingEndsAt에서 읽는다(7일이든 14일이든).
// 시각이 없으면(운영 명령의 옛 협업 같은 드문 경우) 가게 오퍼의 7일이다.
export function measurementDaysOf(
  collaboration: Pick<Collaboration, 'submittedAt' | 'countingEndsAt'>,
): number {
  if (!collaboration.submittedAt || !collaboration.countingEndsAt) {
    return SNAPSHOT_DAYS;
  }
  return Math.round(
    (collaboration.countingEndsAt.getTime() -
      collaboration.submittedAt.getTime()) /
      DAY_MS,
  );
}
