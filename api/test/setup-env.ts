// DATABASE_URL/DIRECT_URL은 여기서 정하지 않는다. scripts/with-test-db.js가
// api/.env의 TEST_* 값을 옮겨 주므로 e2e도 cora_test 스키마를 쓴다.
process.env.NODE_ENV = 'test';
process.env.SUPABASE_URL = 'https://fake.supabase.co';
process.env.PUSH_ADAPTER = 'fake';
