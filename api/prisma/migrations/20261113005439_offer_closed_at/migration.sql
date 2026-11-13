-- 협업이 끝난 오퍼를 "닫힘"으로 표시해, 같은 가게가 같은 크리에이터에게 다시 오퍼하고
-- 크리에이터가 다시 지원할 수 있게 한다. 더하기만 하는 마이그레이션이라 옛 값은 그대로다.

-- AlterTable
ALTER TABLE "offers" ADD COLUMN     "closed_at" TIMESTAMPTZ(3);

-- 열린 오퍼의 부분 유니크 인덱스에 "닫히지 않음"을 더한다. 이 인덱스는 Prisma 스키마 밖이라
-- 이름을 같게 두고 손으로 다시 만든다(그래서 이름으로 찾는 안전망 테스트가 그대로 맞는다).
DROP INDEX "offers_open_store_creator_key";
CREATE UNIQUE INDEX "offers_open_store_creator_key"
  ON "offers" ("store_id", "creator_id")
  WHERE "status" IN ('SENT', 'ACCEPTED') AND "closed_at" IS NULL AND "deleted_at" IS NULL;

-- 채우기: 연결 지원을 먼저 닫고(오퍼의 닫힘 여부로 대상을 고른다), 오퍼를 닫는다.
-- 끝난 협업이 있는 ACCEPTED 오퍼는 협업이 마지막으로 바뀐 시각에, 협업이 아예 없는 옛 ACCEPTED 오퍼
-- (3번 계획 전에 수락, 돈도 할 일도 없다)는 수락한 시각에 닫는다.
UPDATE "applications" a
SET "status" = 'CLOSED'
FROM "offers" o
WHERE o."application_id" = a."id"
  AND a."status" = 'OFFERED'
  AND o."status" = 'ACCEPTED'
  AND o."closed_at" IS NULL
  AND (
    NOT EXISTS (
      SELECT 1 FROM "collaborations" c
      WHERE c."offer_id" = o."id" AND c."deleted_at" IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM "collaborations" c
      WHERE c."offer_id" = o."id" AND c."deleted_at" IS NULL
        AND c."stage" IN ('SETTLED', 'REFUNDED', 'CANCELLED')
    )
  );

UPDATE "offers" o
SET "closed_at" = c."updated_at"
FROM "collaborations" c
WHERE c."offer_id" = o."id"
  AND c."deleted_at" IS NULL
  AND c."stage" IN ('SETTLED', 'REFUNDED', 'CANCELLED')
  AND o."status" = 'ACCEPTED'
  AND o."closed_at" IS NULL;

UPDATE "offers" o
SET "closed_at" = COALESCE(o."accepted_at", o."updated_at")
WHERE o."status" = 'ACCEPTED'
  AND o."closed_at" IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM "collaborations" c
    WHERE c."offer_id" = o."id" AND c."deleted_at" IS NULL
  );
