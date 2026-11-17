-- 브랜드 계약의 측정 기간은 7일 또는 14일이다. 스냅숏 일수 = 측정 일수라 날 번호의 범위를 0~14로 넓힌다.
-- 범위만 넓히는 변경이라 이미 있는 줄(0~7)은 모두 새 제약을 만족한다.
ALTER TABLE "view_snapshots" DROP CONSTRAINT "view_snapshots_day_index_range";
ALTER TABLE "view_snapshots" ADD CONSTRAINT "view_snapshots_day_index_range" CHECK ("day_index" BETWEEN 0 AND 14);
