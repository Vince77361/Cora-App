-- CreateEnum
CREATE TYPE "settlement_status" AS ENUM ('UNCONFIRMED', 'CONFIRMED', 'DISPUTED');

-- CreateEnum
CREATE TYPE "evidence_source" AS ENUM ('CONNECTED_ACCOUNT', 'CAPTURE');

-- CreateEnum
CREATE TYPE "settlement_confirmer" AS ENUM ('COMMISSIONER', 'AUTO', 'OPERATOR', 'NOT_NEEDED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "notification_kind" ADD VALUE 'VIEW_REPORT_REQUESTED';
ALTER TYPE "notification_kind" ADD VALUE 'VIEW_REPORT_READY';

-- AlterTable
ALTER TABLE "settlements" ADD COLUMN     "calculated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "confirm_due_at" TIMESTAMPTZ(3),
ADD COLUMN     "confirmed_at" TIMESTAMPTZ(3),
ADD COLUMN     "confirmed_by" "settlement_confirmer",
ADD COLUMN     "evidence_source" "evidence_source" NOT NULL DEFAULT 'CONNECTED_ACCOUNT',
ADD COLUMN     "fixed_cash_amount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "status" "settlement_status" NOT NULL DEFAULT 'CONFIRMED',
ADD COLUMN     "view_pay_amount" INTEGER NOT NULL DEFAULT 0,
ALTER COLUMN "settled_at" DROP NOT NULL;

-- BEGIN settlement-confirmation-backfill
-- 옛 정산 행 이전: 확인 절차가 없던 때 끝난 정산이라 모두 확정이다. 계산·확인 시각은 정산 시각과 같다.
-- 일반 행은 고정 현금이 없어 viewPay = 지급액이고, 확인한 쪽은 자동(AUTO)이다.
-- 강제 지급(운영 명령) 행은 운영자가 정한 금액이라 OPERATOR, 고정 현금만 있는 행(조회수 수당 없음)은 NOT_NEEDED이며
-- 지급액 전부가 고정 현금이다. 고정 현금과 조회수 수당이 함께 있는 행은 조건 사본의 고정 현금을 뺀 값이 수당이다.
UPDATE "settlements" s
SET "status" = 'CONFIRMED',
    "calculated_at" = s."settled_at",
    "confirmed_at" = s."settled_at",
    "confirmed_by" = CASE
      WHEN EXISTS (
        SELECT 1 FROM "payouts" p
        WHERE p."collaboration_id" = s."collaboration_id"
          AND p."idempotency_key" = 'force-payout:' || s."collaboration_id"::text
      ) OR EXISTS (
        SELECT 1 FROM "ledger_entries" l
        WHERE l."collaboration_id" = s."collaboration_id"
          AND l."idempotency_key" = 'force-payout:' || s."collaboration_id"::text
      ) THEN 'OPERATOR'::"settlement_confirmer"
      WHEN s."final_views" IS NULL THEN 'NOT_NEEDED'::"settlement_confirmer"
      ELSE 'AUTO'::"settlement_confirmer"
    END,
    "fixed_cash_amount" = CASE
      WHEN EXISTS (
        SELECT 1 FROM "ledger_entries" l
        WHERE l."collaboration_id" = s."collaboration_id"
          AND l."idempotency_key" = 'force-payout:' || s."collaboration_id"::text
      ) THEN 0
      WHEN s."final_views" IS NULL THEN s."payout_amount"
      ELSE LEAST(
        s."payout_amount",
        COALESCE((SELECT (c."terms" ->> 'fixedCash')::int FROM "collaborations" c WHERE c."id" = s."collaboration_id"), 0)
      )
    END
WHERE s."settled_at" IS NOT NULL;

UPDATE "settlements"
SET "view_pay_amount" = "payout_amount" - "fixed_cash_amount";
-- END settlement-confirmation-backfill
