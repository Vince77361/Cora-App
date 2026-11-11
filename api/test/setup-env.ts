// e2e가 개발 DB(public)에 쓰지 않도록, scripts/with-test-db.js를 거쳤을 때만 실행한다.
// 그 실행기가 api/.env의 TEST_DIRECT_URL을 DATABASE_URL/DIRECT_URL로 옮겨 cora_test를 쓰게 한다.
if (process.env.CORA_TEST_DB !== '1') {
  throw new Error(
    '테스트 DB 실행기를 거치지 않았어요. 개발 DB를 보호하려고 중단합니다. yarn test:e2e로 실행하세요.',
  );
}
process.env.NODE_ENV = 'test';
process.env.SUPABASE_URL = 'https://fake.supabase.co';
process.env.PUSH_ADAPTER = 'fake';
