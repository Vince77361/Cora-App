// 자동 테스트를 같은 DB의 cora_test 스키마에서 돌리는 실행기.
// api/.env의 TEST_DIRECT_URL(세션 풀러, 5432)을 DATABASE_URL/DIRECT_URL 둘 다로 옮긴다.
// 트랜잭션 풀러(6543)는 Prisma가 보낸 SET search_path가 다른 연결로 새어 나가
// 테스트가 개발 DB의 public을 건드릴 수 있어 쓰지 않는다.
// prisma migrate deploy로 스키마를 최신으로 맞춘 뒤 넘겨받은 명령을 실행한다.
// 값을 출력하지 않는다.
const { spawnSync } = require('node:child_process');
require('dotenv').config({ quiet: true });
process.env.PRISMA_HIDE_UPDATE_MESSAGE = '1';

const [cmd, ...args] = process.argv.slice(2);
if (!cmd) {
  console.error('사용법: node scripts/with-test-db.js <명령> [인자...]');
  process.exit(1);
}

const { TEST_DIRECT_URL } = process.env;
if (!TEST_DIRECT_URL) {
  console.error('api/.env에 TEST_DIRECT_URL이 필요해요.');
  process.exit(1);
}

// 세션 풀러는 클라이언트마다 백엔드를 하나씩 붙잡으므로, Prisma 기본 풀 크기를 줄여 연결 한도를 아낀다.
const url = new URL(TEST_DIRECT_URL);
if (!url.searchParams.has('connection_limit')) {
  url.searchParams.set('connection_limit', '5');
}
process.env.DATABASE_URL = url.toString();
process.env.DIRECT_URL = url.toString();
// 테스트 코드가 "이 실행기를 거쳤다"는 것을 확인하는 표시.
process.env.CORA_TEST_DB = '1';

function run(bin, binArgs) {
  const r = spawnSync(bin, binArgs, { stdio: 'inherit', env: process.env });
  if (r.error) {
    console.error(`실행 실패: ${bin} (${r.error.code})`);
    process.exit(1);
  }
  if (r.status !== 0) process.exit(r.status ?? 1);
}

run('yarn', ['--silent', 'prisma', 'migrate', 'deploy']);
run('yarn', ['--silent', cmd, ...args]);
