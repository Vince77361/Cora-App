-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "notification_kind" ADD VALUE 'VIEW_EVIDENCE_REQUESTED';
ALTER TYPE "notification_kind" ADD VALUE 'VIEW_REPORT_DISPUTED';

-- CreateTable
CREATE TABLE "view_evidences" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "file_path" TEXT NOT NULL,
    "stated_views" INTEGER NOT NULL,
    "submitted_by_id" UUID NOT NULL,
    "confirmed_at" TIMESTAMPTZ(3),
    "confirmed_by" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "view_evidences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlement_disputes" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "raised_by_id" UUID NOT NULL,
    "reason" TEXT NOT NULL,
    "resolved_at" TIMESTAMPTZ(3),
    "resolution" TEXT,
    "resolved_views" INTEGER,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "settlement_disputes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "view_evidences_collaboration_id_idx" ON "view_evidences"("collaboration_id");

-- CreateIndex
CREATE UNIQUE INDEX "settlement_disputes_collaboration_id_raised_by_id_key" ON "settlement_disputes"("collaboration_id", "raised_by_id");

-- AddForeignKey
ALTER TABLE "view_evidences" ADD CONSTRAINT "view_evidences_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "view_evidences" ADD CONSTRAINT "view_evidences_submitted_by_id_fkey" FOREIGN KEY ("submitted_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement_disputes" ADD CONSTRAINT "settlement_disputes_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlement_disputes" ADD CONSTRAINT "settlement_disputes_raised_by_id_fkey" FOREIGN KEY ("raised_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 새 테이블은 RLS를 켜고 정책은 만들지 않는다(앱은 데이터를 NestJS API로만 읽고 쓴다).
ALTER TABLE "view_evidences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "settlement_disputes" ENABLE ROW LEVEL SECURITY;

-- BEGIN resume-settlement-confirmer
-- 운영 명령 resume-settlement로 정산한 옛 행은 settlement-confirmation 이전에 AUTO로 채워졌다.
-- 새 코드는 같은 길을 OPERATOR로 쓰므로 옛 행도 맞춘다(값만 고친다, 두 번 돌려도 같다).
UPDATE "settlements" s
SET "confirmed_by" = 'OPERATOR'::"settlement_confirmer"
WHERE s."confirmed_by" = 'AUTO'::"settlement_confirmer"
  AND EXISTS (
    SELECT 1 FROM "ops_audit_logs" a
    WHERE a."collaboration_id" = s."collaboration_id"
      AND a."command" = 'resume-settlement'
  );
-- END resume-settlement-confirmer
