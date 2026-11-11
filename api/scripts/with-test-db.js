// 자동 테스트를 같은 DB의 cora_test 스키마에서 돌리는 실행기.
// api/.env를 읽어 TEST_* 값을 DATABASE_URL/DIRECT_URL로 옮기고,
// prisma migrate deploy로 스키마를 최신으로 맞춘 뒤 넘겨받은 명령을 실행한다.
// 값을 출력하지 않는다.
const { spawnSync } = require('node:child_process');
require('dotenv').config({ quiet: true });
process.env.PRISMA_HIDE_UPDATE_MESSAGE = '1';

const { TEST_DATABASE_URL, TEST_DIRECT_URL } = process.env;
if (!TEST_DATABASE_URL || !TEST_DIRECT_URL) {
  console.error('api/.env에 TEST_DATABASE_URL, TEST_DIRECT_URL이 필요해요.');
  process.exit(1);
}
process.env.DATABASE_URL = TEST_DATABASE_URL;
process.env.DIRECT_URL = TEST_DIRECT_URL;

function run(cmd, args) {
  const r = spawnSync(cmd, args, { stdio: 'inherit', env: process.env });
  if (r.status !== 0) process.exit(r.status ?? 1);
}

run('yarn', ['--silent', 'prisma', 'migrate', 'deploy']);
const [cmd, ...args] = process.argv.slice(2);
run('yarn', ['--silent', cmd, ...args]);
