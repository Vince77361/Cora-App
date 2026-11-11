import { prisma } from './setup-db';

// check:rls 스크립트(JS)와 같은 SQL을 쓰려고 require로 읽는다.
interface RlsQueries {
  TABLES_WITHOUT_RLS: string;
  POLICY_COUNT: string;
}
// eslint-disable-next-line @typescript-eslint/no-require-imports
const queries = require('../../scripts/rls-queries') as RlsQueries;
const { TABLES_WITHOUT_RLS, POLICY_COUNT } = queries;

describe('row level security', () => {
  it('has row level security enabled on every table in the current schema', async () => {
    const rows =
      await prisma.$queryRawUnsafe<{ relname: string }[]>(TABLES_WITHOUT_RLS);
    expect(rows.map((r) => r.relname)).toEqual([]);
  });

  it('has no RLS policies in the current schema', async () => {
    const rows = await prisma.$queryRawUnsafe<{ n: bigint }[]>(POLICY_COUNT);
    expect(Number(rows[0].n)).toBe(0);
  });

  it('has the users table created by the migrations', async () => {
    const rows = await prisma.$queryRaw<{ n: bigint }[]>`
      SELECT count(*) AS n FROM pg_tables
      WHERE schemaname = current_schema() AND tablename = 'users'`;
    expect(Number(rows[0].n)).toBe(1);
  });
});
