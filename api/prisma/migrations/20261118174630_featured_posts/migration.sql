-- CreateEnum
CREATE TYPE "featured_post_source" AS ENUM ('INSTAGRAM', 'GALLERY');

-- CreateEnum
CREATE TYPE "featured_post_kind" AS ENUM ('PHOTO', 'VIDEO');

-- CreateTable
CREATE TABLE "featured_posts" (
    "id" UUID NOT NULL,
    "creator_id" UUID NOT NULL,
    "position" INTEGER NOT NULL,
    "source" "featured_post_source" NOT NULL,
    "kind" "featured_post_kind" NOT NULL,
    "media_path" TEXT NOT NULL,
    "thumbnail_path" TEXT,
    "caption" TEXT,
    "instagram_media_id" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMPTZ(3),

    CONSTRAINT "featured_posts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "featured_posts_creator_id_idx" ON "featured_posts"("creator_id");

-- AddForeignKey
ALTER TABLE "featured_posts" ADD CONSTRAINT "featured_posts_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 새 테이블은 RLS를 켜고 정책은 만들지 않는다. 앱은 데이터를 NestJS API로만 읽고 쓴다.
ALTER TABLE "featured_posts" ENABLE ROW LEVEL SECURITY;

-- 아래는 Prisma 스키마로 적을 수 없는 제약이라 직접 SQL로 둔다.

-- 순서는 지운 행을 빼고 크리에이터마다 유일하다. 순서를 바꿀 때는 서비스가 한 트랜잭션 안에서 임시 번호를 거쳐 옮긴다.
CREATE UNIQUE INDEX "featured_posts_live_position_key"
  ON "featured_posts" ("creator_id", "position")
  WHERE "deleted_at" IS NULL;

-- 원본 인스타 게시물은 크리에이터마다 한 번만 가져온다(지운 뒤에는 다시 가져올 수 있다).
CREATE UNIQUE INDEX "featured_posts_live_instagram_media_key"
  ON "featured_posts" ("creator_id", "instagram_media_id")
  WHERE "deleted_at" IS NULL AND "instagram_media_id" IS NOT NULL;

ALTER TABLE "featured_posts" ADD CONSTRAINT "featured_posts_position_positive"
  CHECK ("position" >= 1);

ALTER TABLE "featured_posts" ADD CONSTRAINT "featured_posts_caption_length"
  CHECK ("caption" IS NULL OR char_length("caption") <= 40);

-- 옛 카드(creator_profiles.card_headline·card_photo_path)를 1번 게시물(사진첩, 사진)로 옮긴다.
-- 한 줄이 없는 카드 사진은 사진첩 게시물의 규칙(한 줄 필수)에 맞지 않아 옮기지 않는다(옛 열은 그대로 남는다).
INSERT INTO "featured_posts"
  ("id", "creator_id", "position", "source", "kind", "media_path", "caption")
SELECT gen_random_uuid(), "user_id", 1, 'GALLERY', 'PHOTO', "card_photo_path",
       left(btrim("card_headline"), 40)
FROM "creator_profiles"
WHERE "deleted_at" IS NULL
  AND "card_photo_path" IS NOT NULL
  AND btrim(coalesce("card_headline", '')) <> '';
