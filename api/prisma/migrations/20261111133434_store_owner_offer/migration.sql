-- CreateEnum
CREATE TYPE "store_status" AS ENUM ('DRAFT', 'PUBLISHED');

-- CreateEnum
CREATE TYPE "store_onboarding_step" AS ENUM ('PAGE', 'DRAFTS', 'TERMS', 'DONE');

-- CreateEnum
CREATE TYPE "source_link_kind" AS ENUM ('NAVER_MAP', 'CATCHTABLE', 'INSTAGRAM');

-- CreateEnum
CREATE TYPE "content_draft_kind" AS ENUM ('CARD_NEWS', 'REELS_SCRIPT', 'BLOG');

-- CreateEnum
CREATE TYPE "content_format" AS ENUM ('SHORTS', 'REELS', 'CARD_NEWS', 'BLOG');

-- CreateEnum
CREATE TYPE "reward_type" AS ENUM ('VOUCHER', 'PER_VIEW', 'BOTH');

-- CreateEnum
CREATE TYPE "application_status" AS ENUM ('APPLIED', 'CANCELLED', 'OFFERED', 'CLOSED');

-- CreateEnum
CREATE TYPE "offer_status" AS ENUM ('SENT', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "industry_category" AS ENUM ('FOOD_CAFE', 'BEAUTY', 'FASHION', 'ACCESSORY', 'LIVING', 'GROCERY', 'DIGITAL', 'HEALTH', 'OTHER', 'ALCOHOL', 'GAMBLING', 'LOAN', 'DIET_SUPPLEMENT');

-- CreateTable
CREATE TABLE "stores" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "status" "store_status" NOT NULL DEFAULT 'DRAFT',
    "onboarding_step" "store_onboarding_step" NOT NULL DEFAULT 'PAGE',
    "name" TEXT,
    "category" TEXT,
    "industry" "industry_category" NOT NULL DEFAULT 'FOOD_CAFE',
    "neighborhood" TEXT,
    "region_sido" TEXT,
    "region_sigungu" TEXT,
    "cover_photo_path" TEXT,
    "signature_menu" TEXT,
    "hours" TEXT,
    "seats" TEXT,
    "best_shooting_time" TEXT,
    "intro" TEXT,
    "default_format" "content_format",
    "default_reward_type" "reward_type",
    "default_voucher_name" TEXT,
    "default_voucher_value" INTEGER,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "stores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "store_source_links" (
    "id" UUID NOT NULL,
    "store_id" UUID NOT NULL,
    "kind" "source_link_kind" NOT NULL,
    "url" TEXT NOT NULL,
    "summary" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "store_source_links_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "store_content_drafts" (
    "id" UUID NOT NULL,
    "store_id" UUID NOT NULL,
    "kind" "content_draft_kind" NOT NULL,
    "body_label" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "scenes" JSONB NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "regenerated_on" DATE,
    "regenerations_on_day" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "store_content_drafts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "creator_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "display_name" TEXT NOT NULL,
    "content_focus" TEXT,
    "instagram_handle" TEXT,
    "photo_path" TEXT,
    "region_sido" TEXT NOT NULL,
    "region_sigungu" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "creator_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "applications" (
    "id" UUID NOT NULL,
    "store_id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "status" "application_status" NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "offers" (
    "id" UUID NOT NULL,
    "store_id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "application_id" UUID,
    "format" "content_format" NOT NULL,
    "reward_type" "reward_type" NOT NULL,
    "voucher_name" TEXT,
    "voucher_value" INTEGER,
    "per_view_amount" INTEGER,
    "per_view_cap" INTEGER,
    "status" "offer_status" NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "accepted_at" TIMESTAMPTZ(3),
    "payment_due_at" TIMESTAMPTZ(3),
    "declined_at" TIMESTAMPTZ(3),
    "responded_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "offers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "stores_owner_id_key" ON "stores"("owner_id");

-- CreateIndex
CREATE INDEX "store_source_links_store_id_idx" ON "store_source_links"("store_id");

-- CreateIndex
CREATE UNIQUE INDEX "store_content_drafts_store_id_kind_key" ON "store_content_drafts"("store_id", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "creator_profiles_user_id_key" ON "creator_profiles"("user_id");

-- CreateIndex
CREATE INDEX "applications_store_id_status_idx" ON "applications"("store_id", "status");

-- CreateIndex
CREATE INDEX "applications_creator_id_idx" ON "applications"("creator_id");

-- CreateIndex
CREATE INDEX "offers_store_id_status_idx" ON "offers"("store_id", "status");

-- CreateIndex
CREATE INDEX "offers_creator_id_status_idx" ON "offers"("creator_id", "status");

-- CreateIndex
CREATE INDEX "offers_expires_at_idx" ON "offers"("expires_at");

-- AddForeignKey
ALTER TABLE "stores" ADD CONSTRAINT "stores_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "store_source_links" ADD CONSTRAINT "store_source_links_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "store_content_drafts" ADD CONSTRAINT "store_content_drafts_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creator_profiles" ADD CONSTRAINT "creator_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "applications" ADD CONSTRAINT "applications_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "applications" ADD CONSTRAINT "applications_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "offers" ADD CONSTRAINT "offers_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "offers" ADD CONSTRAINT "offers_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "offers" ADD CONSTRAINT "offers_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "applications"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- 같은 가게·크리에이터의 살아 있는 지원(APPLIED, OFFERED)은 하나뿐이다.
-- 취소·종료·삭제된 지원은 막지 않아야 다시 지원할 수 있으므로 부분 유니크 인덱스로 둔다.
CREATE UNIQUE INDEX "applications_live_store_creator_key"
  ON "applications" ("store_id", "creator_id")
  WHERE "status" IN ('APPLIED', 'OFFERED') AND "deleted_at" IS NULL;

-- 같은 가게·크리에이터의 열린 오퍼(SENT, ACCEPTED)는 하나뿐이다. 거절·만료·취소된 뒤에는 다시 보낼 수 있다.
CREATE UNIQUE INDEX "offers_open_store_creator_key"
  ON "offers" ("store_id", "creator_id")
  WHERE "status" IN ('SENT', 'ACCEPTED') AND "deleted_at" IS NULL;

-- 앱은 데이터를 NestJS API로만 읽고 쓰므로 RLS를 켜고 정책은 만들지 않는다.
ALTER TABLE "stores" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "store_source_links" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "store_content_drafts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "creator_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "applications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "offers" ENABLE ROW LEVEL SECURITY;
