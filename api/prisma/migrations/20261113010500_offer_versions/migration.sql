-- 오퍼의 조건(형식, 보상, 사용권)을 판본(offer_versions)으로 옮긴다.
-- 순서: 새 열·새 테이블 → 오퍼마다 판본 1로 값 채우기 → 개수 확인 → 오퍼의 옛 조건 열 삭제.
-- 한 파일이 한 번에 적용되므로 개수 확인이 틀리면 전체가 되돌아가 중간 상태가 남지 않는다.

-- CreateEnum
CREATE TYPE "offer_party" AS ENUM ('STORE', 'CREATOR');

-- CreateEnum
CREATE TYPE "offer_end_reason" AS ENUM ('SCHEDULE', 'TERMS', 'OTHER_PARTNER', 'NO_REASON');

-- AlterTable: 오퍼가 흐름을 가진다. 옛 오퍼는 사장님이 보냈고 크리에이터가 답할 차례다.
-- 기본값은 옛 행을 채우려고만 쓰고 바로 뗀다(새 오퍼는 보낼 때 값을 정한다).
ALTER TABLE "offers"
ADD COLUMN     "end_reason" "offer_end_reason",
ADD COLUMN     "ended_by" "offer_party",
ADD COLUMN     "initiated_by" "offer_party" NOT NULL DEFAULT 'STORE',
ADD COLUMN     "latest_version" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "turn" "offer_party" NOT NULL DEFAULT 'CREATOR';

ALTER TABLE "offers"
ALTER COLUMN "initiated_by" DROP DEFAULT,
ALTER COLUMN "turn" DROP DEFAULT;

-- CreateTable
CREATE TABLE "offer_versions" (
    "id" UUID NOT NULL,
    "offer_id" UUID NOT NULL,
    "number" INTEGER NOT NULL,
    "author_party" "offer_party" NOT NULL,
    "format" "content_format" NOT NULL,
    "pieces" INTEGER NOT NULL DEFAULT 1,
    "voucher_name" TEXT,
    "voucher_value" INTEGER,
    "voucher_people" INTEGER,
    "fixed_cash" INTEGER NOT NULL,
    "view_rate_per_thousand" INTEGER,
    "per_view_cap" INTEGER,
    "usage_rights" "usage_rights" NOT NULL,
    "idea" TEXT,
    "principles" TEXT[],
    "series_name" TEXT,
    "series_format" "content_format",
    "series_note" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "offer_versions_pkey" PRIMARY KEY ("id")
);

-- 앱은 데이터를 NestJS API로만 읽고 쓴다. 정책은 만들지 않는다.
ALTER TABLE "offer_versions" ENABLE ROW LEVEL SECURITY;

-- CreateIndex
CREATE INDEX "offer_versions_offer_id_idx" ON "offer_versions"("offer_id");

-- CreateIndex
CREATE UNIQUE INDEX "offer_versions_offer_id_number_key" ON "offer_versions"("offer_id", "number");

-- AddForeignKey
ALTER TABLE "offer_versions" ADD CONSTRAINT "offer_versions_offer_id_fkey" FOREIGN KEY ("offer_id") REFERENCES "offers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 값 채우기: 오퍼마다 판본 1을 만든다. 조건은 오퍼의 값 그대로이고, 사장님이 쓴 판본이며, 만든 시각도 오퍼와 같다.
-- 지워진(논리 삭제) 오퍼도 빠짐없이 옮긴다. 옛 오퍼에는 아이디어·원칙·연재가 없다.
INSERT INTO "offer_versions" (
  "id", "offer_id", "number", "author_party", "format", "pieces",
  "voucher_name", "voucher_value", "voucher_people", "fixed_cash",
  "view_rate_per_thousand", "per_view_cap", "usage_rights", "principles",
  "created_at", "updated_at", "deleted_at"
)
SELECT
  gen_random_uuid(), o."id", 1, 'STORE', o."format", 1,
  o."voucher_name", o."voucher_value", o."voucher_people", o."fixed_cash",
  o."view_rate_per_thousand", o."per_view_cap", o."usage_rights", ARRAY[]::TEXT[],
  o."created_at", o."updated_at", o."deleted_at"
FROM "offers" o;

-- 옛 열을 지우기 전의 확인: 오퍼 수와 판본 1의 수가 같아야 한다. 다르면 예외로 이 파일 전체를 되돌린다.
DO $$
BEGIN
  IF (SELECT count(*) FROM "offers") <> (SELECT count(*) FROM "offer_versions" WHERE "number" = 1) THEN
    RAISE EXCEPTION '오퍼 수와 판본 1의 수가 달라요. 옛 조건 열을 지우지 않고 되돌려요.';
  END IF;
END $$;

-- AlterTable: 조건은 판본으로 옮겨졌으므로 오퍼의 옛 조건 열을 지운다.
ALTER TABLE "offers"
DROP COLUMN "fixed_cash",
DROP COLUMN "format",
DROP COLUMN "per_view_cap",
DROP COLUMN "usage_rights",
DROP COLUMN "view_rate_per_thousand",
DROP COLUMN "voucher_name",
DROP COLUMN "voucher_people",
DROP COLUMN "voucher_value";
