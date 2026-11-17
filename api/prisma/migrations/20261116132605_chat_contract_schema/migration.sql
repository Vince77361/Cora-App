-- CreateEnum
CREATE TYPE "conversation_status" AS ENUM ('REQUESTED', 'OPEN', 'DECLINED', 'CLOSED');

-- CreateEnum
CREATE TYPE "message_kind" AS ENUM ('TEXT', 'CONTENT_CARD', 'SYSTEM');

-- CreateEnum
CREATE TYPE "report_target_kind" AS ENUM ('USER', 'CONVERSATION');

-- CreateEnum
CREATE TYPE "report_reason" AS ENUM ('SPAM', 'ABUSE', 'FRAUD', 'OTHER');

-- CreateEnum
CREATE TYPE "drop_reason" AS ENUM ('SCHEDULE', 'BUDGET', 'DIRECTION', 'OTHER', 'REQUEST_DECLINED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "contract_status" AS ENUM ('AWAITING_BRAND', 'CONCLUDED', 'VOIDED');

-- AlterTable
ALTER TABLE "collaborations" ADD COLUMN     "contracted_at" TIMESTAMPTZ(3),
ADD COLUMN     "creator_note" TEXT,
ADD COLUMN     "drop_reason" "drop_reason",
ADD COLUMN     "dropped_by_id" UUID,
ADD COLUMN     "extra_revisions_allowed" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "status" "conversation_status" NOT NULL,
    "requested_by_id" UUID,
    "last_seq" INTEGER NOT NULL DEFAULT 0,
    "last_message_at" TIMESTAMPTZ(3),
    "closed_reason" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversation_members" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "last_read_seq" INTEGER NOT NULL DEFAULT 0,
    "muted_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "conversation_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "seq" INTEGER NOT NULL,
    "sender_id" UUID,
    "client_id" TEXT,
    "kind" "message_kind" NOT NULL,
    "text" TEXT,
    "card_title" TEXT,
    "card_photo_path" TEXT,
    "system_code" TEXT,
    "system_params" JSONB,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "blocks" (
    "id" UUID NOT NULL,
    "blocker_id" UUID NOT NULL,
    "blocked_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "blocks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reports" (
    "id" UUID NOT NULL,
    "reporter_id" UUID NOT NULL,
    "target_kind" "report_target_kind" NOT NULL,
    "target_id" UUID NOT NULL,
    "reason" "report_reason" NOT NULL,
    "detail" TEXT,
    "resolved_at" TIMESTAMPTZ(3),
    "resolved_by" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contracts" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "status" "contract_status" NOT NULL,
    "terms_version" INTEGER NOT NULL,
    "terms_snapshot" JSONB NOT NULL,
    "creator_consented_at" TIMESTAMPTZ(3) NOT NULL,
    "creator_consent_texts" TEXT[],
    "brand_consent_texts" TEXT[],
    "brand_consented_at" TIMESTAMPTZ(3),
    "payment_id" UUID,
    "concluded_at" TIMESTAMPTZ(3),
    "voided_at" TIMESTAMPTZ(3),
    "void_reason" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "contracts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "conversations_collaboration_id_key" ON "conversations"("collaboration_id");

-- CreateIndex
CREATE INDEX "conversation_members_user_id_idx" ON "conversation_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "conversation_members_conversation_id_user_id_key" ON "conversation_members"("conversation_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "messages_conversation_id_seq_key" ON "messages"("conversation_id", "seq");

-- CreateIndex
CREATE UNIQUE INDEX "messages_conversation_id_sender_id_client_id_key" ON "messages"("conversation_id", "sender_id", "client_id");

-- CreateIndex
CREATE INDEX "blocks_blocked_id_idx" ON "blocks"("blocked_id");

-- CreateIndex
CREATE UNIQUE INDEX "blocks_blocker_id_blocked_id_key" ON "blocks"("blocker_id", "blocked_id");

-- CreateIndex
CREATE INDEX "reports_resolved_at_idx" ON "reports"("resolved_at");

-- CreateIndex
CREATE UNIQUE INDEX "reports_reporter_id_target_kind_target_id_key" ON "reports"("reporter_id", "target_kind", "target_id");

-- CreateIndex
CREATE UNIQUE INDEX "contracts_payment_id_key" ON "contracts"("payment_id");

-- CreateIndex
CREATE INDEX "contracts_collaboration_id_idx" ON "contracts"("collaboration_id");

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_dropped_by_id_fkey" FOREIGN KEY ("dropped_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_members" ADD CONSTRAINT "conversation_members_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_members" ADD CONSTRAINT "conversation_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contracts" ADD CONSTRAINT "contracts_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contracts" ADD CONSTRAINT "contracts_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- 새 테이블은 RLS를 켜고 정책은 만들지 않는다. 앱은 데이터를 NestJS API로만 읽고 쓴다.
ALTER TABLE "conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "conversation_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "blocks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "reports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "contracts" ENABLE ROW LEVEL SECURITY;

-- 아래는 Prisma 스키마로 적을 수 없는 제약이라 직접 SQL로 둔다.

-- 협업마다 살아 있는(무효가 아닌) 계약은 하나뿐이다. 무효가 된 계약은 기록으로 남는다.
CREATE UNIQUE INDEX "contracts_live_collaboration_key"
  ON "contracts" ("collaboration_id")
  WHERE "status" <> 'VOIDED';

-- 메시지 1000자, 신고 설명 500자, 크리에이터 한마디 40자. 번호는 1부터다.
ALTER TABLE "messages" ADD CONSTRAINT "messages_text_length"
  CHECK ("text" IS NULL OR char_length("text") <= 1000);
ALTER TABLE "messages" ADD CONSTRAINT "messages_seq_positive"
  CHECK ("seq" >= 1);
ALTER TABLE "reports" ADD CONSTRAINT "reports_detail_length"
  CHECK ("detail" IS NULL OR char_length("detail") <= 500);
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_creator_note_length"
  CHECK ("creator_note" IS NULL OR char_length("creator_note") <= 40);
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_extra_revisions_range"
  CHECK ("extra_revisions_allowed" >= 0);

-- 문자열 칸의 값 범위(enum으로 만들 만큼 넓지 않은 것).
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_closed_reason"
  CHECK ("closed_reason" IS NULL OR "closed_reason" = 'BLOCKED');
ALTER TABLE "contracts" ADD CONSTRAINT "contracts_void_reason"
  CHECK ("void_reason" IS NULL OR "void_reason" IN ('NEW_TERMS', 'DROPPED', 'BLOCKED'));

-- 기존 협업마다 열린 대화방과 참가자 두 줄을 만든다(끝난 협업 포함, 안내 줄 없음).
-- 여러 번 실행해도 같은 결과여야 한다(db-spec이 이 묶음을 다시 실행해 확인한다).
-- BEGIN conversation-backfill
INSERT INTO "conversations" ("id", "collaboration_id", "status", "last_seq", "created_at", "updated_at")
SELECT gen_random_uuid(), c."id", 'OPEN', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM "collaborations" c
WHERE NOT EXISTS (
  SELECT 1 FROM "conversations" v WHERE v."collaboration_id" = c."id"
);

INSERT INTO "conversation_members" ("id", "conversation_id", "user_id", "created_at", "updated_at")
SELECT gen_random_uuid(), v."id", m."user_id", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM "conversations" v
JOIN "collaborations" c ON c."id" = v."collaboration_id"
CROSS JOIN LATERAL (VALUES (c."commissioner_id"), (c."creator_id")) AS m("user_id")
ON CONFLICT ("conversation_id", "user_id") DO NOTHING;
-- END conversation-backfill
