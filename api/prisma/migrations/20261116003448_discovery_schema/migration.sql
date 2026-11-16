-- CreateEnum
CREATE TYPE "fee_band" AS ENUM ('W200K', 'W300K', 'W400K', 'W500K_PLUS');

-- CreateEnum
CREATE TYPE "product_trial_days" AS ENUM ('D3', 'D7', 'D14', 'ANY');

-- CreateEnum
CREATE TYPE "campaign_status" AS ENUM ('ACTIVE', 'CLOSED');

-- CreateEnum
CREATE TYPE "swipe_decision_kind" AS ENUM ('LIKE', 'PASS', 'HOLD');

-- CreateEnum
CREATE TYPE "pass_reason" AS ENUM ('MOOD', 'REGION', 'FEE', 'FIELD');

-- CreateEnum
CREATE TYPE "swipe_target_kind" AS ENUM ('CREATOR', 'CAMPAIGN', 'STORE');

-- CreateEnum
CREATE TYPE "not_required" AS ENUM ('FACE', 'FIXED_LINES', 'SCRIPT_READING');

-- CreateEnum
CREATE TYPE "recommendation_scope" AS ENUM ('BRAND', 'CREATOR');

-- CreateEnum
CREATE TYPE "revision_scope" AS ENUM ('NONE', 'GUIDE_1', 'DRAFT_1', 'DRAFT_2');

-- CreateEnum
CREATE TYPE "brand_usage_rights" AS ENUM ('REPOST_ONLY', 'ADS_TOO', 'NONE');

-- AlterTable
ALTER TABLE "collaborations" ADD COLUMN     "campaign_id" UUID;

-- AlterTable
ALTER TABLE "creator_profiles" ADD COLUMN     "card_headline" TEXT,
ADD COLUMN     "card_photo_path" TEXT;

-- CreateTable
CREATE TABLE "creator_principles" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "fields" "industry_category"[],
    "blocked_industries" "industry_category"[],
    "face_ok" BOOLEAN NOT NULL,
    "script_ok" BOOLEAN NOT NULL,
    "honest_review" BOOLEAN NOT NULL,
    "fee_band" "fee_band" NOT NULL,
    "trial_days" "product_trial_days" NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "creator_principles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "brand_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "tagline" TEXT,
    "industry" "industry_category" NOT NULL,
    "photo_path" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "brand_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaigns" (
    "id" UUID NOT NULL,
    "brand_id" UUID NOT NULL,
    "status" "campaign_status" NOT NULL,
    "headline" TEXT NOT NULL,
    "fee" INTEGER NOT NULL,
    "budget" INTEGER NOT NULL,
    "product_provided" BOOLEAN NOT NULL,
    "format" "content_format" NOT NULL,
    "start_from" DATE NOT NULL,
    "trial_days" "product_trial_days" NOT NULL,
    "must_include" TEXT[],
    "not_required" "not_required"[],
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "swipe_decisions" (
    "id" UUID NOT NULL,
    "actor_id" UUID NOT NULL,
    "target_kind" "swipe_target_kind" NOT NULL,
    "target_id" UUID NOT NULL,
    "campaign_id" UUID,
    "decision" "swipe_decision_kind" NOT NULL,
    "pass_reason" "pass_reason",
    "note" TEXT,
    "content_title" TEXT,
    "content_photo_path" TEXT,
    "proposed_fee" INTEGER,
    "proposed_product_provided" BOOLEAN,
    "proposed_perf_rate" INTEGER,
    "proposed_perf_cap" INTEGER,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "swipe_decisions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "matches" (
    "id" UUID NOT NULL,
    "campaign_id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "matched_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "matches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_recommendations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "scope" "recommendation_scope" NOT NULL,
    "campaign_id" UUID,
    "day" DATE NOT NULL,
    "items" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "daily_recommendations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "terms_versions" (
    "id" UUID NOT NULL,
    "collaboration_id" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "proposed_by_id" UUID,
    "title" TEXT NOT NULL,
    "fee" INTEGER NOT NULL,
    "start_date" DATE NOT NULL,
    "format" "content_format" NOT NULL,
    "pieces" INTEGER NOT NULL,
    "product_provided" BOOLEAN NOT NULL,
    "revision_scope" "revision_scope" NOT NULL,
    "usage_rights" "brand_usage_rights" NOT NULL,
    "payout_days" INTEGER NOT NULL,
    "perf_rate_per_thousand" INTEGER,
    "perf_cap" INTEGER,
    "brand_confirmed_at" TIMESTAMPTZ(3),
    "creator_confirmed_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "terms_versions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "creator_principles_creator_id_key" ON "creator_principles"("creator_id");

-- CreateIndex
CREATE UNIQUE INDEX "brand_profiles_user_id_key" ON "brand_profiles"("user_id");

-- CreateIndex
CREATE INDEX "campaigns_brand_id_status_idx" ON "campaigns"("brand_id", "status");

-- CreateIndex
CREATE INDEX "swipe_decisions_target_kind_target_id_idx" ON "swipe_decisions"("target_kind", "target_id");

-- CreateIndex
CREATE UNIQUE INDEX "matches_collaboration_id_key" ON "matches"("collaboration_id");

-- CreateIndex
CREATE INDEX "matches_creator_id_idx" ON "matches"("creator_id");

-- CreateIndex
CREATE UNIQUE INDEX "matches_campaign_id_creator_id_key" ON "matches"("campaign_id", "creator_id");

-- CreateIndex
CREATE UNIQUE INDEX "terms_versions_collaboration_id_version_key" ON "terms_versions"("collaboration_id", "version");

-- CreateIndex
CREATE INDEX "collaborations_campaign_id_idx" ON "collaborations"("campaign_id");

-- AddForeignKey
ALTER TABLE "collaborations" ADD CONSTRAINT "collaborations_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "creator_principles" ADD CONSTRAINT "creator_principles_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "brand_profiles" ADD CONSTRAINT "brand_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "swipe_decisions" ADD CONSTRAINT "swipe_decisions_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "swipe_decisions" ADD CONSTRAINT "swipe_decisions_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_recommendations" ADD CONSTRAINT "daily_recommendations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_recommendations" ADD CONSTRAINT "daily_recommendations_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "terms_versions" ADD CONSTRAINT "terms_versions_collaboration_id_fkey" FOREIGN KEY ("collaboration_id") REFERENCES "collaborations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "terms_versions" ADD CONSTRAINT "terms_versions_proposed_by_id_fkey" FOREIGN KEY ("proposed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- 새 테이블 7개는 RLS를 켜고 정책은 만들지 않는다(앱은 NestJS API로만 읽고 쓴다).
ALTER TABLE "creator_principles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "brand_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "campaigns" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "swipe_decisions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "matches" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "daily_recommendations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "terms_versions" ENABLE ROW LEVEL SECURITY;

-- 아래는 Prisma 스키마로 적을 수 없는 제약이라 직접 SQL로 둔다.

-- 브랜드마다 진행 중인 캠페인은 하나뿐이다.
CREATE UNIQUE INDEX "campaigns_active_brand_key"
  ON "campaigns" ("brand_id")
  WHERE "status" = 'ACTIVE' AND "deleted_at" IS NULL;

-- 같은 캠페인·크리에이터의 브랜드 협업은 하나뿐이다.
CREATE UNIQUE INDEX "collaborations_brand_campaign_creator_key"
  ON "collaborations" ("campaign_id", "creator_id")
  WHERE "kind" = 'BRAND_CONTRACT';

-- campaign_id가 null일 수 있는 유일 제약은 NULL 두 개를 서로 다른 값으로 보는 Postgres 기본 때문에
-- 부분 유니크 인덱스 두 개(null인 경우, 아닌 경우)로 나눠 건다.
CREATE UNIQUE INDEX "swipe_decisions_no_campaign_key"
  ON "swipe_decisions" ("actor_id", "target_kind", "target_id")
  WHERE "campaign_id" IS NULL;
CREATE UNIQUE INDEX "swipe_decisions_campaign_key"
  ON "swipe_decisions" ("actor_id", "target_kind", "target_id", "campaign_id")
  WHERE "campaign_id" IS NOT NULL;

CREATE UNIQUE INDEX "daily_recommendations_no_campaign_key"
  ON "daily_recommendations" ("user_id", "scope", "day")
  WHERE "campaign_id" IS NULL;
CREATE UNIQUE INDEX "daily_recommendations_campaign_key"
  ON "daily_recommendations" ("user_id", "scope", "campaign_id", "day")
  WHERE "campaign_id" IS NOT NULL;

-- 캠페인 예산: 1만 원 단위, 제작비 이상, 100,000,000원 이하. 꼭 넣을 것은 최대 3개.
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_budget_range"
  CHECK ("budget" >= "fee" AND "budget" <= 100000000 AND "budget" % 10000 = 0);
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_must_include_max"
  CHECK (cardinality("must_include") <= 3);

-- 성과 추가(1,000회당 단가와 상한)는 둘 다 있거나 둘 다 없다. 브랜드의 제안도 같다.
ALTER TABLE "terms_versions" ADD CONSTRAINT "terms_versions_perf_pair"
  CHECK (("perf_rate_per_thousand" IS NULL) = ("perf_cap" IS NULL));
ALTER TABLE "swipe_decisions" ADD CONSTRAINT "swipe_decisions_proposed_perf_pair"
  CHECK (("proposed_perf_rate" IS NULL) = ("proposed_perf_cap" IS NULL));

-- 정산까지 걸리는 날은 7일 또는 14일이다.
ALTER TABLE "terms_versions" ADD CONSTRAINT "terms_versions_payout_days"
  CHECK ("payout_days" IN (7, 14));
