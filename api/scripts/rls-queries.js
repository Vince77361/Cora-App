// RLS 감시 쿼리. test/db/rls.db-spec.ts와 scripts/check-rls.js가 함께 쓴다.
// 스키마를 'public'으로 박지 않고 current_schema()를 쓰므로,
// 테스트에서는 cora_test, 개발 DB 확인에서는 public을 본다.
const TABLES_WITHOUT_RLS = `
  SELECT c.relname AS relname FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = current_schema() AND c.relkind = 'r' AND c.relrowsecurity = false
  ORDER BY c.relname`;

const POLICY_COUNT = `
  SELECT count(*) AS n FROM pg_policies WHERE schemaname = current_schema()`;

module.exports = { TABLES_WITHOUT_RLS, POLICY_COUNT };
