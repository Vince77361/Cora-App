import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { SeedError } from './supabase-admin';

// 개발 프로젝트의 ref. 공개 값이라 커밋된 파일(seed/dev-project.json)에 둔다.
// 개발 프로젝트를 새로 만들면 그 파일을 바꿔야 한다.
export function readDevProjectRef(): string {
  const raw = readFileSync(join(__dirname, '../dev-project.json'), 'utf8');
  const { projectRef } = JSON.parse(raw) as { projectRef?: unknown };
  if (typeof projectRef !== 'string' || projectRef === '') {
    throw new SeedError('seed/dev-project.json에 projectRef가 없어요.');
  }
  return projectRef;
}

// `https://<ref>.supabase.co`에서 ref를 꺼낸다. 형식이 다르면 null.
export function projectRefOf(supabaseUrl: string | undefined): string | null {
  if (!supabaseUrl) return null;
  try {
    return new URL(supabaseUrl).hostname.split('.')[0] || null;
  } catch {
    return null;
  }
}

const last4 = (value: string) => value.slice(-4);

// 비밀번호가 비밀이 아닌 계정을 만드는 일이라, 개발 환경이고 개발 프로젝트일 때만 허용한다.
// NODE_ENV가 비었거나 test·staging·production이면 거부한다(.env에 값이 없는 경우가 기본일 수 있다).
// 거부 메시지에는 프로젝트 ref의 끝 4자리까지만 담는다.
export function assertDevTarget(target: {
  nodeEnv: string | undefined;
  supabaseUrl: string | undefined;
  devProjectRef: string;
}): void {
  if (target.nodeEnv !== 'development') {
    throw new SeedError(
      `개발 계정은 NODE_ENV=development일 때만 만들어요. (지금: ${target.nodeEnv ? target.nodeEnv : '비어 있음'})`,
    );
  }
  const ref = projectRefOf(target.supabaseUrl);
  if (ref === null) {
    throw new SeedError(
      'SUPABASE_URL에서 프로젝트를 알아보지 못해 중단해요. https://<ref>.supabase.co 형식인지 확인하세요.',
    );
  }
  if (ref !== target.devProjectRef) {
    throw new SeedError(
      `SUPABASE_URL의 프로젝트(…${last4(ref)})가 개발 프로젝트(…${last4(target.devProjectRef)})가 아니라서 중단해요. 개발 프로젝트를 새로 만들었다면 seed/dev-project.json을 고치세요.`,
    );
  }
}
