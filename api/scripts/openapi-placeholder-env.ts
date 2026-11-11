// 문서 생성은 어느 기기에서나, 비밀값 없이 돌아야 한다. 그래서 필요한 키를 눈에 띄는
// 가짜 값으로 무조건 덮어쓴다. 셸이나 CI에 NODE_ENV=production, PUSH_ADAPTER=real,
// 잘못된 DATABASE_URL 같은 값이 있어도 내보내기가 달라지거나 실패하지 않게 하려는 것이다.
// ConfigModule이 api/.env를 읽을 수는 있지만, 이미 process.env에 들어 있는 값은 덮어쓰지
// 않으므로 .env는 필요하지도, 문서에 영향을 주지도 않는다. 이 값은 어디에도 연결되지 않는다.
const PLACEHOLDERS: Record<string, string> = {
  NODE_ENV: 'development',
  PORT: '3000',
  DATABASE_URL:
    'postgresql://placeholder:placeholder@localhost:5432/placeholder',
  DIRECT_URL: 'postgresql://placeholder:placeholder@localhost:5432/placeholder',
  SUPABASE_URL: 'https://placeholder.invalid',
  PUSH_ADAPTER: 'fake',
};
for (const [key, value] of Object.entries(PLACEHOLDERS)) {
  process.env[key] = value;
}
