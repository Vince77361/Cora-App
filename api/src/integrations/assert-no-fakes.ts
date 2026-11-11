import type { Env } from '../config/env';

// 이름이 _ADAPTER로 끝나는 키를 전부 검사한다. 새 연동은 Env에 키만 추가하면 자동으로 걸린다.
export function assertNoFakesInProduction(env: Env): void {
  if (env.NODE_ENV !== 'production') return;
  const fakes = Object.entries(env as unknown as Record<string, unknown>)
    .filter(([key, value]) => key.endsWith('_ADAPTER') && value === 'fake')
    .map(([key]) => key);
  if (fakes.length > 0) {
    throw new Error(
      `운영 환경에서 가짜 연동을 쓸 수 없어요: ${fakes.join(', ')}`,
    );
  }
}
