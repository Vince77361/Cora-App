-- CreateEnum
CREATE TYPE "notification_tab" AS ENUM ('MATCHING', 'COLLABORATION', 'SETTLEMENT');

-- CreateEnum
CREATE TYPE "notification_switch" AS ENUM ('MUTUAL_INTEREST', 'OFFERS', 'MESSAGES', 'SETTLEMENT', 'RECOMMENDATIONS', 'ESSENTIAL');

-- CreateEnum
CREATE TYPE "notification_glyph" AS ENUM ('WON', 'PEN');

-- CreateEnum
CREATE TYPE "notification_kind" AS ENUM ('APPLICATION_RECEIVED', 'OFFER_RECEIVED', 'OFFER_ACCEPTED', 'OFFER_DECLINED', 'PAYMENT_FUNDED', 'CONTENT_SUBMITTED', 'SUBMIT_REMINDER', 'UNSUBMITTED_ENDED', 'UNSUBMITTED_REFUNDED', 'CREATOR_CANCELLED', 'CANCEL_REQUESTED', 'COLLABORATION_HALTED', 'SETTLEMENT_CONFIRMED', 'PAYOUT_DONE', 'SETTLEMENT_REFUNDED');

-- CreateEnum
CREATE TYPE "quiet_hours" AS ENUM ('OFF', 'NIGHT', 'WEEKEND');

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" "user_role" NOT NULL,
    "kind" "notification_kind" NOT NULL,
    "tab" "notification_tab",
    "params" JSONB NOT NULL,
    "actor_user_id" UUID,
    "actor_name" TEXT,
    "actor_photo_path" TEXT,
    "target_kind" TEXT NOT NULL,
    "target_id" TEXT,
    "dedupe_key" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "read_at" TIMESTAMPTZ(3),

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_settings" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "mutual_interest" BOOLEAN NOT NULL DEFAULT true,
    "offers" BOOLEAN NOT NULL DEFAULT true,
    "messages" BOOLEAN NOT NULL DEFAULT true,
    "settlement" BOOLEAN NOT NULL DEFAULT true,
    "recommendations" BOOLEAN NOT NULL DEFAULT false,
    "recommendations_agreed_at" TIMESTAMPTZ(3),
    "quiet_hours" "quiet_hours" NOT NULL DEFAULT 'NIGHT',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "notifications_user_id_role_created_at_idx" ON "notifications"("user_id", "role", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "notifications_user_id_dedupe_key_key" ON "notifications"("user_id", "dedupe_key");

-- CreateIndex
CREATE UNIQUE INDEX "notification_settings_user_id_key" ON "notification_settings"("user_id");

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_settings" ADD CONSTRAINT "notification_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 앱은 알림을 NestJS API로만 읽고 쓰므로 RLS만 켜고 정책은 만들지 않는다.
ALTER TABLE "notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "notification_settings" ENABLE ROW LEVEL SECURITY;
