import { AsyncLocalStorage } from 'node:async_hooks';

export interface RequestContext {
  requestId: string;
  // 보안 로그에만 남긴다. 프록시 뒤에서의 값 신뢰 여부는 앱 설정(trust proxy)이 정한다.
  ip?: string;
}

// 요청마다(그리고 작업 큐·운영 명령 실행마다) 한 번 정해지고, 서비스 코드의 인자를 늘리지 않고도
// 로그와 오류 응답이 같은 ID를 쓰게 하려고 AsyncLocalStorage에 둔다.
const storage = new AsyncLocalStorage<RequestContext>();

export function runWithRequestContext<T>(
  context: RequestContext,
  fn: () => T,
): T {
  return storage.run(context, fn);
}

export function currentRequestContext(): RequestContext | undefined {
  return storage.getStore();
}

export function currentRequestId(): string | undefined {
  return storage.getStore()?.requestId;
}
