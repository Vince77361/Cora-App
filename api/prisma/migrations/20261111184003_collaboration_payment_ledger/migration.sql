-- CreateEnum
CREATE TYPE "collaboration_kind" AS ENUM ('STORE_OFFER', 'BRAND_CONTRACT');

-- CreateEnum
CREATE TYPE "collaboration_stage" AS ENUM ('AWAITING_PAYMENT', 'FUNDED', 'COUNTING', 'SETTLED', 'REFUNDED', 'CANCELLED', 'INQUIRY', 'MATCHED', 'NEGOTIATING', 'AGREED', 'CONTRACTED', 'GUIDED', 'REVIEWING', 'APPROVED', 'PUBLISHED', 'DROPPED', 'HALTED');

-- CreateEnum
CREATE TYPE "settlement_method" AS ENUM ('PER_VIEW', 'FIXED', 'NONE');

-- CreateEnum
CREATE TYPE "ledger_account" AS ENUM ('PG_IN', 'ESCROW', 'CREATOR_PAYABLE', 'STORE_REFUND', 'FEE_REVENUE');

-- CreateEnum
CREATE TYPE "payment_method" AS ENUM ('CARD', 'TRANSFER', 'EASY_PAY');

-- CreateEnum
CREATE TYPE "payment_status" AS ENUM ('PENDING', 'APPROVED', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "transfer_status" AS ENUM ('PENDING', 'DONE', 'FAILED');

-- CreateEnum
CREATE TYPE "cancel_request_status" AS ENUM ('PENDING', 'ACCEPTED', 'EXPIRED');

-- CreateTable
CREATE TABLE "collaborations" (
    "id" UUID NOT NULL,
    "kind" "collaboration_kind" NOT NULL,
    "stage" "collaboration_stage" NOT NULL,
    "commissioner_id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "offer_id" UUID,
    "store_id" UUID,
    "terms" JSONB NOT NULL,
    "settlement_method" "settlement_method" NOT NULL,
    "funded_at" TIMESTAMPTZ(3),
    "submit_due_at" TIMESTAMPTZ(3),
    "submitted_url" TEXT,
    "submitted_at" TIMESTAMPTZ(3),
    "counting_ends_at" TIMESTAMPTZ(3),
    "halted_reason" TEXT,
    "stage_before_halt" "collaboration_stage",
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "collaborations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "amount_escrow" INTEGER NOT NULL,
    "amount_fee" INTEGER NOT NULL,
    "fee_rate" INTEGER NOT NULL,
    "method" "payment_method" NOT NULL,
    "status" "payment_status" NOT NULL DEFAULT 'PENDING',
    "pg_transaction_id" TEXT,
    "requested_at" TIMESTAMPTZ(3) NOT NULL,
    "approved_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ledger_entries" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "batch_id" UUID NOT NULL,
    "debit_account" "ledger_account" NOT NULL,
    "credit_account" "ledger_account" NOT NULL,
    "amount" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "view_snapshots" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "taken_at" TIMESTAMPTZ(3) NOT NULL,
    "views" INTEGER,
    "day_index" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "view_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settlements" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "final_views" INTEGER,
    "payout_amount" INTEGER NOT NULL,
    "refund_amount" INTEGER NOT NULL,
    "settled_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "settlements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payouts" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "amount" INTEGER NOT NULL,
    "status" "transfer_status" NOT NULL DEFAULT 'PENDING',
    "external_id" TEXT,
    "idempotency_key" TEXT NOT NULL,
    "scheduled_for" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "payouts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refunds" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "amount" INTEGER NOT NULL,
    "status" "transfer_status" NOT NULL DEFAULT 'PENDING',
    "external_id" TEXT,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "refunds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payout_accounts" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "bank_code" TEXT NOT NULL,
    "account_number_enc" TEXT NOT NULL,
    "account_last4" TEXT NOT NULL,
    "holder_name" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "payout_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "instagram_connections" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "handle" TEXT NOT NULL,
    "followers" INTEGER,
    "token_enc" TEXT,
    "refreshed_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "instagram_connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cancel_requests" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "requested_by_id" UUID NOT NULL,
    "status" "cancel_request_status" NOT NULL DEFAULT 'PENDING',
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "cancel_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ops_audit_logs" (
    "id" UUID NOT NULL,
    "command" TEXT NOT NULL,
    "collaboration_id" UUID,
    "operator" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "detail" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "ops_audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "collaborations_offer_id_key" ON "collaborations"("offer_id");

-- CreateIndex
CREATE INDEX "collaborations_store_id_stage_idx" ON "collaborations"("store_id", "stage");

-- CreateIndex
CREATE INDEX "collaborations_creator_id_stage_idx" ON "collaborations"("creator_id", "stage");

-- CreateIndex
CREATE INDEX "collaborations_commissioner_id_stage_idx" ON "collaborations"("commissioner_id", "stage");

-- CreateIndex
CREATE INDEX "collaborations_stage_counting_ends_at_idx" ON "collaborations"("stage", "counting_ends_at");

-- CreateIndex
CREATE UNIQUE INDEX "payments_pg_transaction_id_key" ON "payments"("pg_transaction_id");

-- CreateIndex
CREATE INDEX "payments_collaboration_id_status_idx" ON "payments"("collaboration_id", "status");

-- CreateIndex
CREATE INDEX "ledger_entries_collaboration_id_idx" ON "ledger_entries"("collaboration_id");

-- CreateIndex
CREATE INDEX "ledger_entries_batch_id_idx" ON "ledger_entries"("batch_id");

-- CreateIndex
CREATE UNIQUE INDEX "ledger_entries_idempotency_key_debit_account_credit_account_key" ON "ledger_entries"("idempotency_key", "debit_account", "credit_account");

-- CreateIndex
CREATE UNIQUE INDEX "view_snapshots_collaboration_id_day_index_key" ON "view_snapshots"("collaboration_id", "day_index");

-- CreateIndex
CREATE UNIQUE INDEX "settlements_collaboration_id_key" ON "settlements"("collaboration_id");

-- CreateIndex
CREATE UNIQUE INDEX "payouts_idempotency_key_key" ON "payouts"("idempotency_key");

-- CreateIndex
CREATE INDEX "payouts_status_scheduled_for_idx" ON "payouts"("status", "scheduled_for");

-- CreateIndex
CREATE INDEX "payouts_collaboration_id_idx" ON "payouts"("collaboration_id");

-- CreateIndex
CREATE UNIQUE INDEX "refunds_idempotency_key_key" ON "refunds"("idempotency_key");

-- CreateIndex
CREATE INDEX "refunds_collaboration_id_idx" ON "refunds"("collaboration_id");

-- CreateIndex
CREATE UNIQUE INDEX "payout_accounts_creator_id_key" ON "payout_accounts"("creator_id");

-- CreateIndex
CREATE UNIQUE INDEX "instagram_connections_creator_id_key" ON "instagram_connections"("creator_id");

-- CreateIndex
CREATE UNIQUE INDEX "instagram_connections_handle_key" ON "instagram_connections"("handle");

-- CreateIndex
CREATE INDEX "cancel_requests_collaboration_id_status_idx" ON "cancel_requests"("collaboration_id", "status");

-- CreateIndex
CREATE INDEX "ops_audit_logs_collaboration_id_idx" ON "ops_audit_logs"("collaboration_id");

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_commissioner_id_fkey" FOREIGN KEY ("commissioner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_offer_id_fkey" FOREIGN KEY ("offer_id") REFERENCES "offers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "view_snapshots" ADD CONSTRAINT "view_snapshots_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "settlements" ADD CONSTRAINT "settlements_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payouts" ADD CONSTRAINT "payouts_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payout_accounts" ADD CONSTRAINT "payout_accounts_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "instagram_connections" ADD CONSTRAINT "instagram_connections_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cancel_requests" ADD CONSTRAINT "cancel_requests_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cancel_requests" ADD CONSTRAINT "cancel_requests_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ops_audit_logs" ADD CONSTRAINT "ops_audit_logs_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- 앱은 데이터를 NestJS API로만 읽고 쓴다. 새 테이블마다 RLS를 켜고 정책은 만들지 않는다.
ALTER TABLE "collaborations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "payments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ledger_entries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "view_snapshots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "settlements" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "payouts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "refunds" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "payout_accounts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "instagram_connections" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "cancel_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ops_audit_logs" ENABLE ROW LEVEL SECURITY;

-- 조회수 스냅샷은 링크 제출 당일(0)부터 7일째(7)까지다. Prisma 스키마로는 표현할 수 없어 직접 SQL로 둔다.
ALTER TABLE "view_snapshots" ADD CONSTRAINT "view_snapshots_day_index_range" CHECK ("day_index" BETWEEN 0 AND 7);
