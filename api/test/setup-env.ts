// e2e는 api/.env 없이도 돌아야 하므로 필요한 값을 명백히 가짜인 값으로 채운다.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://fake:fake@localhost:6543/fake';
process.env.DIRECT_URL = 'postgresql://fake:fake@localhost:5432/fake';
process.env.SUPABASE_URL = 'https://fake.supabase.co';
process.env.PUSH_ADAPTER = 'fake';
