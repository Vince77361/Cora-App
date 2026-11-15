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
process.env.STORE_LINK_ADAPTER = 'fake';
process.env.CONTENT_DRAFT_ADAPTER = 'fake';
process.env.PAYMENT_ADAPTER = 'fake';
process.env.PAYOUT_ADAPTER = 'fake';
process.env.VIEW_COUNT_ADAPTER = 'fake';
process.env.INSTAGRAM_ADAPTER = 'fake';
process.env.OPERATOR_ALERT_ADAPTER = 'fake';
// 테스트가 쓰는 값. 실제 비밀값이 아니다.
process.env.PAYMENT_WEBHOOK_SECRET = 'test-payment-webhook-secret-0123456789';
process.env.PAYOUT_ACCOUNT_KEY = Buffer.alloc(32, 7).toString('base64');
// 요청 수 제한은 한 테스트 파일이 같은 사용자·같은 IP로 분당 수백 번 부르므로 사실상 끈다. 제한 자체는 hardening.e2e-spec이 작은 값으로 따로 시험한다.
process.env.RATE_LIMIT_IP_PER_MIN = '1000000';
process.env.RATE_LIMIT_USER_PER_MIN = '1000000';
