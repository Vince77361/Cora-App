import type { Env } from '../config/env';

// 서버(main.ts)가 시작할 때 부른다. 운영에서 작업자를 끈 채로는 서버가 뜨지 않게 한다:
// 작업자가 따로 도는 프로세스가 아직 없어서, 꺼 두면 정산·지급·환급·기한 작업이 모두 멈춘다.
// 운영 명령(ops-main)은 이 검사를 거치지 않는다(작업을 올리기만 하는 것이 그 명령의 설계다).
export function assertWorkerOnInProduction(
  env: Pick<Env, 'NODE_ENV' | 'JOBS_WORKER'>,
): void {
  if (env.NODE_ENV === 'production' && env.JOBS_WORKER === 'off') {
    throw new Error(
      '운영에서는 JOBS_WORKER=off로 서버를 시작할 수 없어요. 작업자가 따로 도는 프로세스가 없어서 정산·지급·환급 작업이 멈춰요.',
    );
  }
}
