// 문서 생성은 어느 기기에서나, 비밀값 없이 돌아야 한다. api/.env를 읽지 않고
// 비어 있는 필수 키만 눈에 띄는 가짜 값으로 채운다. 이 값은 어디에도 연결되지 않는다.
const PLACEHOLDERS: Record<string, string> = {
  NODE_ENV: 'development',
  DATABASE_URL:
    'postgresql://placeholder:placeholder@localhost:5432/placeholder',
  DIRECT_URL: 'postgresql://placeholder:placeholder@localhost:5432/placeholder',
  SUPABASE_URL: 'https://placeholder.invalid',
  PUSH_ADAPTER: 'fake',
};
for (const [key, value] of Object.entries(PLACEHOLDERS)) {
  process.env[key] ??= value;
}
